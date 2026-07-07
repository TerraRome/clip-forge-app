# Redis Queue Management

## Purpose

ClipForge uses Redis as both the Celery message broker and result backend. This document covers queue topology, task routing, retry policies, dead letter handling, and Redis memory management.

## Redis Configuration

```python
# app/config.py
settings.redis_url: str = "redis://redis:6379/0"  # broker
settings.redis_result_url: str = "redis://redis:6379/1"  # result backend
```

Standard Redis deployment: single instance for development, Redis Sentinel or ElastiCache for production. Separate DB numbers isolate broker (0), results (1), and cache (2).

## Queue Topology

### Default Queues

| Queue Name | Purpose | Concurrency | Priority |
|---|---|---|---|
| `celery` | Default fallback (admin tasks) | 1 | Low |
| `io` | Network-bound: yt-dlp download, LLM API calls | 8 | Medium |
| `cpu` | CPU-bound: Whisper transcription, probe analysis | 4 | Medium |
| `gpu` | GPU-bound: FFmpeg rendering (encode-heavy) | 2 | High |

### Queue Configuration (`celery.conf.task_routes`)

```python
task_routes = {
    "app.worker.tasks.download_video": {"queue": "io"},
    "app.worker.tasks.transcribe_audio": {"queue": "cpu"},
    "app.worker.tasks.extract_audio": {"queue": "cpu"},
    "app.worker.tasks.detect_highlights": {"queue": "io"},
    "app.worker.tasks.render_clip": {"queue": "gpu"},
    "app.worker.tasks.finalize": {"queue": "celery"},
}
```

## Retry Logic

### Retry Policies by Task

| Task | Max Retries | Retry Delay | Acknowledge Late | Notes |
|---|---|---|---|---|
| `download_video` | 3 | 60s exponential | Yes | Transient network failures. Backoff: 60, 120, 240s |
| `extract_audio` | 2 | 30s | Yes | File system races |
| `transcribe_audio` | 2 | 30s | Yes | OOM — retry with smaller model |
| `detect_highlights` | 1 | 10s | Yes | LLM API 5xx only. 4xx = no retry |
| `render_clip` | 0 | — | No | Too expensive to retry blindly. Manual re-render |

### Retry Decision Logic (`bind=True, autoretry_for=(...,)`)

```python
@celery_app.task(
    bind=True,
    autoretry_for=(ConnectionError, TimeoutError, subprocess.CalledProcessError),
    retry_backoff=True,
    retry_backoff_max=300,
    retry_jitter=True,
    max_retries=3,
)
def download_video(self, project_id, url):
    try:
        video_svc.download(url, path)
    except RuntimeError as e:
        if "HTTP Error 429" in str(e):
            self.retry(countdown=120)  # rate limit — wait longer
        elif "HTTP Error 404" in str(e):
            raise  # video gone — no retry
        raise
```

## Dead Letter Queue (DLQ)

Tasks that exhaust all retries land on the DLQ. Celery does not have a built-in DLQ — implemented using a custom approach:

### DLQ Implementation

```python
from celery.result import AsyncResult
import json

# Producer side: on final failure, push to Redis DLQ list
@celery_app.task(on_failure=dead_letter_handler)
def render_clip(...):
    ...

def dead_letter_handler(task, exc, task_id, args, kwargs, einfo):
    dlq_key = f"dlq:{task.name}"
    entry = {
        "task_id": task_id,
        "name": task.name,
        "args": args,
        "kwargs": kwargs,
        "error": str(exc),
        "timestamp": time.time(),
        "project_id": kwargs.get("project_id", args[0] if args else None),
    }
    redis_client.lpush(dlq_key, json.dumps(entry))
    redis_client.ltrim(dlq_key, 0, 999)  # keep last 1000
```

### DLQ Monitoring

A Celery Beat periodic task checks DLQ length hourly and sends alerts:

```python
@celery_app.task
def check_dlq():
    for key in redis_client.scan_iter("dlq:*"):
        count = redis_client.llen(key)
        if count > 10:
            logger.warning("dlq_growing", queue=key, count=count)
```

DLQ entries can be re-queued manually via admin CLI:

```bash
# Re-queue all failed renders for a project
python scripts/replay_dlq.py --project-id <uuid> --queue gpu
```

## Redis Memory Management

### Result Expiry

```python
celery_app.conf.result_expires = 3600 * 24  # 24 hours
```

Task results auto-expire after 24 hours. Completed task state is stored in PostgreSQL; Redis results are ephemeral.

### Max Memory Policy

```
maxmemory 2gb
maxmemory-policy allkeys-lru
```

Set in Redis config. The LRU eviction policy handles temporary task data. Persistent data (DLQ entries) is stored separately.

### Key Namespace Convention

| Pattern | Example | TTL |
|---|---|---|
| `celery-task-meta-{id}` | `celery-task-meta-uuid` | 24h |
| `celery-task-state-{id}` | `celery-task-state-uuid` | 24h |
| `dlq:{task_name}` | `dlq:render_clip` | No TTL (monitored) |
| `cache:{key}` | `cache:whisper_model` | Variable |

## Best Practices

- **Prefetch limit**: `worker_prefetch_multiplier=1` for GPU queue to avoid queuing renders when GPU is saturated.
- **Visibility timeout**: `task_acks_late=True` tasks use `visibility_timeout=3600` to prevent duplicate execution during long renders.
- **Connection pooling**: Celery's Redis broker handles connections via `redis://` URL with `blocking_pool` for high concurrency.
- **Sentinel mode**: Production uses `sentinel://` URLs with `master_name` for HA Redis.
