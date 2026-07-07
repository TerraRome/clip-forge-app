# Celery Patterns Reference

## Not Currently Used
ClipForge uses `threading.Thread` for background pipeline execution.

## Migration Pattern (When Needed)
```python
from celery import Celery, shared_task

celery_app = Celery(
    "clipforge",
    broker="redis://localhost:6379/0",
    backend="redis://localhost:6379/0",
)

@shared_task(bind=True, autoretry_for=(Exception,), max_retries=3,
             default_retry_delay=30)
def run_pipeline_task(self, project_id: str):
    self.update_state(state="PROGRESS", meta={"progress": 5.0})
    # ... pipeline steps ...
    self.update_state(state="PROGRESS", meta={"progress": 100.0})
    return {"project_id": project_id, "status": "done"}
```

## Task Routing (Planned)
```python
celery_app.conf.task_routes = {
    "pipeline.download": {"queue": "download"},
    "pipeline.transcode": {"queue": "transcode"},
    "pipeline.inference": {"queue": "inference"},
}
```

## Concurrency
- Worker concurrency = 1 (GPU contention)
- Task ETA for deferred processing

## Key Differences from Threading
- Reliable retry (not just try/except)
- Progress tracking via result backend (not FileStorage)
- Dead letter queue for persistent failures
