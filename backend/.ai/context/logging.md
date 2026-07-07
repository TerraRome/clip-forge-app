# Structured Logging with structlog

## Configuration (`app/main.py` lifespan)
```python
structlog.configure(
    processors=[
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.JSONRenderer(),
    ],
    wrapper_class=structlog.make_filtering_bound_logger(logging.INFO),
    context_class=dict,
    logger_factory=structlog.PrintLoggerFactory(),
    cache_logger_on_first_use=True,
)
```
- JSON output to stdout (not stderr)
- ISO 8601 timestamps
- Log level: INFO (DEBUG filtered out)
- `PrintLoggerFactory` — no file rotation (container-managed)

## Usage Pattern
```python
import structlog
logger = structlog.get_logger()
log = logger.bind(project_id=project_id)
log.info("step_download", url=url)
log.error("pipeline_failed", error=str(e))
```
- `bind()` for correlation IDs (project_id)
- Key-value pairs for structured context
- No f-strings in log messages (machine-parseable keys)

## Log Events (Pipeline)
- `pipeline_started`, `step_download`, `step_extract_audio`, `step_transcribe`, `step_highlights`, `step_render`, `pipeline_complete`
- `pipeline_failed` on exception (with `error` field)
- Face detection: `dominant_face_selected` with x/y/w/h/score
- Render: `rendering_clip` with crop_filter and subtitle_preset

## Log Levels
- INFO: pipeline steps, progress updates
- WARNING: fallback triggers (LLM fail → energy-based, word_pop fail → classic)
- ERROR: pipeline failures, download failures, render failures
