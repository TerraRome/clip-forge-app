# Celery Task Queue

## Purpose

ClipForge uses Celery for production-grade async task processing. The current MVP runs pipeline synchronously in a background thread; this document describes the target Celery architecture for horizontal scaling, reliability, and observability.

## Current MVP Worker

`app/worker/pipeline.py` defines `run_pipeline(project_id)` — a synchronous function called in a `threading.Thread`. This model has no retry, no visibility into running tasks, no worker scaling, and no task persistence across restarts.

## Target Celery Architecture

```
FastAPI ──→ Redis Broker ──→ Celery Workers (GPU + CPU)
               │                    │
               ↓                    ↓
         Result Backend     PostgreSQL + MinIO
```

### Components

- **Broker**: Redis. Stores pending tasks. Simple, fast, battle-tested with Celery.
- **Result Backend**: Redis (MVP) or PostgreSQL (production). Stores task states and return values.
- **Workers**: Two worker pools — GPU workers (1-2 concurrent) for FFmpeg rendering, CPU workers (4-8 concurrent) for download/transcription.

## Task Definitions

All Celery tasks live in `app/worker/tasks.py`:

```python
from celery import Celery
from app.config import settings

celery_app = Celery(
    "clipforge",
    broker=settings.redis_url,
    backend=settings.redis_url,
    task_serializer="json",
    accept_content=["json"],
)

@celery_app.task(bind=True, max_retries=3, default_retry_delay=60)
def process_project(self, project_id: str):
    """Main pipeline task — decomposed into subtasks."""
    ...

@celery_app.task(bind=True, max_retries=2, default_retry_delay=30)
def download_video(self, project_id: str, url: str) -> str:
    """yt-dlp download. Retries on network errors."""
    ...

@celery_app.task(bind=True, max_retries=2, default_retry_delay=30)
def transcribe_audio(self, audio_path: str) -> list:
    """Whisper transcription. Retries on OOM if model too large."""
    ...

@celery_app.task(bind=True, max_retries=1, default_retry_delay=10)
def detect_highlights(self, segments: list, num_clips: int) -> list:
    """LLM highlight detection. Fails fast — no retry on API 4xx."""
    ...

@celery_app.task(bind=True, max_retries=0)  # no retry, budget is tight
def render_clip(self, project_id: str, clip_index: int, ...) -> str:
    """Single clip render. GPU-bound. No retry — manual re-render."""
    ...
```

## Task Routing

Tasks are routed to appropriate queues based on resource requirements:

```python
celery_app.conf.task_routes = {
    "tasks.download_video": {"queue": "io"},
    "tasks.transcribe_audio": {"queue": "cpu"},
    "tasks.detect_highlights": {"queue": "io"},  # network-bound (LLM API)
    "tasks.render_clip": {"queue": "gpu"},
}
```

### Worker Startup

```bash
# GPU worker (max 2 concurrent renders)
celery -A app.worker.tasks worker -Q gpu --concurrency=2 --max-tasks-per-child=1

# CPU worker (transcription, download, analysis)
celery -A app.worker.tasks worker -Q cpu,io --concurrency=4

# Beat scheduler (cleanup, retry dead letters)
celery -A app.worker.tasks beat
```

## Pipeline as Workflow (Chord)

The pipeline uses Celery chords (group + callback) for the fan-out render stage:

```python
from celery import chord

@pipeline_task
def process_project(project_id):
    download = download_video.s(project_id, url)
    extract = extract_audio.s()
    transcribe = transcribe_audio.s()
    detect = detect_highlights.s(num_clips)

    # Chain: download → extract → transcribe → detect
    # Then fan-out: one render per highlight
    workflow = (
        download |
        extract |
        transcribe |
        detect |
        chord(
            [render_clip.s(project_id, i, hl) for i, hl in enumerate(highlights)],
            finalize.s(project_id)
        )
    )
    workflow()
```

## State Tracking

Celery task state (`PENDING → STARTED → RETRY → SUCCESS/FAILURE`) is mapped to `ProjectStatus`:

| Celery State | Project Status |
|---|---|
| PENDING | PENDING |
| STARTED | PROCESSING |
| SUCCESS | DONE |
| FAILURE | ERROR |
| RETRY | PROCESSING (with `progress` frozen) |

A Celery `on_success` / `on_failure` callback updates the database project row.

## GPU Worker Considerations

- `--concurrency=2` prevents GPU OOM. Two simultaneous FFmpeg processes each use ~1-2 GB VRAM.
- `--max-tasks-per-child=1` ensures clean GPU state between renders. FFmpeg may leak memory across invocations.
- GPU workers run on hosts with NVIDIA GPUs. FFmpeg uses `h264_nvenc` instead of `h264_videotoolbox`.
- Workers must mount the shared filesystem (MinIO or NFS) for access to downloaded videos and rendered clips.

## Best Practices

- **Task idempotency**: All tasks are designed to be safely re-run. State mutations (status update, file writes) happen in the finalize step only.
- **Timeout per task**: Download: 600s. Transcribe: 600s (large model). Render: 300s per clip. Configured via `task_soft_time_limit` and `task_time_limit`.
- **Rate limiting**: API-based tasks (LLM highlight detection) use `task_acks_late=True` with rate limits to avoid hammering upstream APIs.
- **Monitoring**: Flower (`celery -A app.worker.tasks flower`) for task visibility in development. Datadog/Prometheus exporters in production.
