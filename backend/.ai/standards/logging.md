# Logging Standards — ClipForge

## Library
- **structlog** — always. Never stdlib `logging` directly.
- Configured once in `app/core/logging.py` with JSON output in production.
- Bound context (request_id, task_id, user_id) persists across async boundaries.
- Human-readable in dev via `structlog.dev.ConsoleRenderer()`.

## Module Setup
```python
import structlog
logger = structlog.get_logger()
```
One logger per module. Never create loggers in functions or classes.

## Correlation IDs
- Every request gets a `correlation_id` (UUID v4) at the FastAPI middleware layer.
- Injected into Celery task headers, forwarded to downstream workers.
- Always present in every log line.

## Log Levels
| Level   | When to use                                               |
|---------|-----------------------------------------------------------|
| DEBUG   | Dev detail: SQL queries, model shapes, FFmpeg commands,   |
|         | chunk boundaries. Never in production.                    |
| INFO    | Lifecycle: app start/stop, job created/completed,         |
|         | webhook delivered, file uploaded, pipeline step boundary. |
| WARN    | Recoverable anomalies: retry attempt, degraded model,     |
|         | fallback path taken, rate limit approaching.              |
| ERROR   | Unhandled exception, external API failure after retries,  |
|         | data corruption, FFmpeg non-zero exit.                    |
| CRITICAL| Process cannot continue: DB connection lost, disk full.   |

## What NOT to log
- Passwords, tokens, API keys, JWTs, PII, raw file bytes.
- Full SQL queries in production (DEBUG only).
- Internal stack traces to end-users (log server-side, return generic error).
- Full LLM prompt/response (preview only, 500 chars max).

## Worker-specific
- Log task_id, video_source, job_id at INFO during each major pipeline stage.
- Log FFmpeg progress callbacks at DEBUG.
- Log Celery retry count + ETA at WARN.
- Log on entry AND exit of every pipeline step.

## Error Logging Pattern
```python
try:
    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
except subprocess.CalledProcessError as e:
    logger.error("ffmpeg_failed", stderr=e.stderr, cmd_preview=" ".join(cmd[:6]))
    raise RuntimeError(f"Render failed: {e.stderr}") from e
```

## Forbidden
- `print()` — banned in production code.
- String formatting in log calls (`logger.info(f"...")`). Use positional args.
- Empty `except:` without log.
