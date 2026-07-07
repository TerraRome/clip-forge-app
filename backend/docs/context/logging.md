# Structured Logging

## Purpose

ClipForge uses structured logging via `structlog` to produce machine-parseable JSON log output. Every log event includes correlation IDs, component names, and structured context for aggregation in log management systems (Datadog, Loki, CloudWatch).

## Configuration

Logging is configured in `app/main.py` during the FastAPI lifespan:

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

### Processor Chain

1. **add_log_level**: Injects the log level name (`info`, `error`, `warning`) into the event dict.
2. **PositionalArgumentsFormatter**: Allows `log.info("event", arg1, arg2)` positional args. Not heavily used in favor of keyword args.
3. **TimeStamper(fmt="iso")**: Adds ISO 8601 timestamp (UTC) to every event.
4. **JSONRenderer()**: Final renderer — outputs one JSON object per line. No pretty-print. Each line is a complete, parseable log event.

### Design Decisions

- **`PrintLoggerFactory` over `logging.LoggerFactory`**: Outputs directly to stdout. Simpler. Container environments (Docker) capture stdout as the standard log stream.
- **`make_filtering_bound_logger(logging.INFO)`: Discards DEBUG events globally. `logging.basicConfig(level=logging.INFO)` catches stdlib logger output at same level.
- **`cache_logger_on_first_use=True`**: Performance optimization. Avoids re-initializing logger on each call.

## Log Event Structure

Every log event produces a JSON object with these keys:

```json
{
  "event": "pipeline_started",
  "level": "info",
  "timestamp": "2026-07-07T14:30:00.123456+00:00",
  "logger": "app.worker.pipeline",
  "project_id": "a1b2c3d4-e5f6-...",
  ...additional_context
}
```

### Standard Fields

| Field | Source | Example |
|---|---|---|
| `event` | First positional arg | `"step_download"` |
| `level` | Processor | `"info"`, `"error"` |
| `timestamp` | Processor | `"2026-07-07T14:30:00.123456+00:00"` |
| `logger` | structlog automatic | Module path |
| `project_id` | Explicit bind | `"a1b2c3"` |

## Correlation IDs

The pipeline binds `project_id` to the logger at the start and uses the bound logger throughout:

```python
log = logger.bind(project_id=project_id)
log.info("pipeline_started")
```

Every log event from that point forward includes `project_id` without needing to pass it manually. This enables cross-service tracing: from API request → pipeline → Celery task → storage operation, all events for a project are correlated.

Future: When Celery is added, the task ID becomes the trace ID. When HTTP requests are traced, each request gets a `request_id` header propagated to the pipeline logger.

## Log Levels by Component

| Level | Component | Frequency |
|---|---|---|
| `INFO` | Pipeline steps | ~10 per project |
| `INFO` | Service operations | ~5 per service call |
| `WARNING` | Fallback activation | Rare |
| `WARNING` | LLM failure → heuristic | Per highlight failure |
| `ERROR` | Pipeline exception | Once per failure |
| `ERROR` | FFmpeg subprocess failure | Per corrupt download/failed render |

### Log Events Catalog

**Pipeline** (`pipeline.py`):
- `pipeline_started` → `pipeline_complete` / `pipeline_failed`
- `step_download`, `step_extract_audio`, `step_transcribe`, `step_highlights`, `step_render`, `step_face_detect`

**VideoService**:
- `downloading_video` → `download_complete` / `download_failed`
- `extracting_audio` → `audio_extraction_complete` / `audio_extraction_failed`

**TranscriptService**:
- `loading_whisper_model` (once at startup)
- `transcribing` → `transcription_complete`

**LLMHighlightService**:
- `llm_highlight_detecting` → `llm_highlight_detected` / `llm_highlight_failed_falling_back`

**FaceService**:
- `no_faces_detected_in_highlight` / `dominant_face_selected`

**SmartCropService**:
- `smart_crop` (with face center, scale, crop dimensions)

**RenderService**:
- `rendering_clip` → `render_complete` / `render_failed`

**SubtitleService**:
- `word_pop_failed_falling_back_to_classic`
- `karaoke_failed_falling_back_to_classic`

## Anti-Patterns

### 1. F-strings in log messages

```python
# BAD — evaluates string even when logging is disabled
logger.info(f"Processing {project_id}")

# GOOD — structlog evaluates lazily
logger.info("processing_project", project_id=project_id)
```

### 2. Catching and re-logging without context

```python
# BAD — loses stack trace
try:
    ...
except Exception as e:
    logger.error("failed", error=str(e))
    raise

# GOOD — preserves exception info
try:
    ...
except Exception:
    logger.exception("pipeline_failed")
    raise
```

### 3. Logging sensitive data

Never log LLM API keys, full transcript text (truncate to 500 chars), or file paths that reveal internal server structure.

## Future

- **Log aggregation**: Fluentd or Vector to ship logs from Docker to Loki → Grafana dashboards.
- **Per-request tracing**: Inject `request_id` middleware in FastAPI, propagate to workers via Celery headers.
- **Audit log**: Dedicated `audit` logger at `WARNING` level recording all user-initiated actions (create project, download clips) for compliance.
