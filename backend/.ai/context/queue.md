# Queue: Not Yet Implemented

## Current State
- No message queue. Pipeline runs inline in daemon thread.
- No task routing, no retry, no dead letter queue.

## Why It Works Now
- Single-user / dev mode
- Thread dies with process — acceptable for development
- Simplicity: zero infrastructure dependencies

## Planned Redis/Celery Architecture (Future)
```
FastAPI → Celery Client → Redis Broker → Celery Worker → Pipeline Tasks
```

## Task Routing (Planned)
- `download_queue`: yt-dlp downloads (I/O bound)
- `transcode_queue`: ffmpeg operations (CPU/GPU)
- `inference_queue`: whisper + MediaPipe (GPU/ML)

## Retry Strategy (Planned)
- `@shared_task(autoretry_for=(subprocess.CalledProcessError,), max_retries=3, default_retry_delay=30)`
- Exponential backoff for transient failures
- Dead letter after 3 retries → `status=ERROR` with details

## Concurrency (Planned)
- Celery worker concurrency = 1 (GPU contention)
- Task ETA for deferred processing
- Result backend for progress tracking
