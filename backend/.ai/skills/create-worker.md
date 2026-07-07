# Create Celery Task

## Description
Create a Celery task for asynchronous pipeline processing with retry, error handling, and progress reporting. ClipForge currently uses `threading.Thread` in `app/worker/pipeline.py`; this skill covers the Celery patterns for when threading is insufficient (distributed workers, persistence, monitoring).

## When to Use
- Converting the pipeline from threads to distributed Celery workers
- Adding a new long-running background job (batch export, model training)
- Need retry logic with exponential backoff on transient failures
- Need task queue monitoring and management

## Inputs
- Task function name (e.g., `process_video_task`)
- Input parameters (must be JSON-serializable: strings, ints, floats, lists, dicts)
- Retry policy (max_retries, retry_delay, autoretry_for exceptions)
- Queue name (e.g., `transcription`, `rendering`)

## Outputs
- Celery task in `app/worker/tasks.py`
- Task registration with Celery app
- Progress reporting to storage or task state

## Steps

1. **Define task function** with `@celery_app.task(bind=True, max_retries=3, default_retry_delay=60)`. `bind=True` enables `self.retry()` and `self.update_state()`. Add `autoretry_for=(ConnectionError, TimeoutError)` for automatic retry on network issues.

2. **Accept project_id as first arg** for context. Keep all args JSON-serializable. Deserialize into domain objects inside the task body. Log entry/exit with `structlog.get_logger().bind(task_id=self.request.id, project_id=project_id)`.

3. **Report progress** via `self.update_state(state='PROGRESS', meta={'progress': 50.0, 'step': 'transcribing'})`. For current file-based storage, also update `storage.update(project_id, progress=...)` for API consumers that poll project state.

4. **Handle retries** — catch specific transient exceptions explicitly. Use `self.retry(exc=e, countdown=min(60 * 2 ** self.request.retries, 600))` for exponential backoff capped at 10 minutes. Re-raise unknown exceptions immediately (they signal bugs not transient failures).

5. **Handle permanent failures** — after max retries exhausted, catch the retry exception, log with full traceback, update project status to `ProjectStatus.ERROR` with `error_message`, and return gracefully (do not re-raise).

6. **Keep task body thin** — delegate to `run_pipeline(project_id)` or a use case. The task wrapper handles only Celery lifecycle (retry, state, result). Business logic lives in services/usecases.

## Example

```python
@celery_app.task(bind=True, max_retries=3, default_retry_delay=60, autoretry_for=(ConnectionError, TimeoutError))
def process_video_task(self, project_id: str):
    log = structlog.get_logger().bind(task_id=self.request.id, project_id=project_id)
    log.info("task_started")
    try:
        run_pipeline(project_id)
    except Exception as e:
        log.error("task_failed_permanently", error=str(e))
        storage.update(project_id, status=ProjectStatus.ERROR, error_message=str(e))
        # Do not re-raise — permanent failure
```

## Notes
- Celery tasks must have JSON-serializable arguments — no dataclasses, no complex objects. Serialize at call site, deserialize in task.
- Avoid global state in tasks — they may run on different workers across machines.
- The current `run_pipeline()` function in `app/worker/pipeline.py` is already structured to be called from a Celery task wrapper.
- Monitor queues: `celery -A app.worker.celery_app status`, `celery -A app.worker.celery_app inspect active`.
- For development without Celery, the thread-based execution path remains available — no breaking changes to existing code.
