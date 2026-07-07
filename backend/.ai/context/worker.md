# Worker: In-Process Threading

## Current Architecture
- **No Celery/Redis**. Pipeline runs in `threading.Thread` (daemon) spawned from FastAPI endpoint.
- Thread started in `router.py` line 48: `thread = threading.Thread(target=run_pipeline, args=(project_id,), daemon=True)`
- Daemon thread dies if main process exits (acceptable for dev)

## Pipeline Orchestration (`app/worker/pipeline.py`)
```python
def run_pipeline(project_id: str) -> None:
    1. Download video (yt-dlp)                          → progress 5→20
    2. Extract audio (ffmpeg)                           → progress 30
    3. Transcribe (whisper)                             → progress 50
    4. Get video info (ffprobe)                         → (no progress)
    5. Detect highlights (LLM or word-density fallback) → progress 65
    6. For each highlight:
       a. Face detection (MediaPipe BlazeFace)
       b. Smart crop computation
       c. Render clip (ffmpeg + ASS subtitles)          → progress 65→100
    7. Set status = DONE or ERROR
```

## Error Handling
- `try/except` wraps entire pipeline
- On failure: set `status=ERROR`, save `error_message=str(e)`
- No retry logic (client re-submits)

## Future Upgrades
- Migrate to Celery with Redis broker for reliability
- Add `@shared_task(bind=True, autoretry_for=(...), max_retries=3)`
- Progress callbacks via Celery `update_state`
- Task routing: separate queues for download/transcode/AI inference
