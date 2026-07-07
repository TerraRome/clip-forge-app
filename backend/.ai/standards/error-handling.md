# Error Handling Standards — ClipForge

## Philosophy
- Errors at boundary, trust inside.
- Catch at pipeline level, not per-service-call (unless recovery is possible).
- Structured error messages stored for user display.
- External tool failures (FFmpeg, Whisper, yt-dlp) always wrapped in project-specific errors.

## Exception Hierarchy
```
ClipForgeError            # Base — never raised directly
├── ConfigurationError    # Missing/malformed env vars
├── ValidationError       # Pydantic or business-rule violation
├── NotFoundError         # Entity not found
├── StorageError          # File read/write failures
├── ProcessingError       # Base for pipeline failures
│   ├── DownloadError     # yt-dlp failure
│   ├── AudioExtractError # FFmpeg audio extraction failure
│   ├── TranscribeError   # Whisper failure
│   ├── HighlightError    # No highlights found
│   ├── RenderError       # FFmpeg render failure
│   └── FaceDetectError   # MediaPipe failure (non-critical -> warn, continue)
├── ExternalServiceError  # Downstream API failures (after retries)
├── AuthenticationError   # JWT invalid/expired
└── AuthorizationError    # Valid token but insufficient perms
```

## HTTP Error Mapping
| Exception           | HTTP | Detail                                    |
|---------------------|------|-------------------------------------------|
| ValidationError     | 422  | Field-level errors (Pydantic output)      |
| NotFoundError       | 404  | Resource type + identifier                |
| AuthenticationError | 401  | "Invalid or expired token"                |
| AuthorizationError  | 403  | "Insufficient permissions"                |
| ProcessingError     | 500  | "Processing failed" (no internal detail)  |
| ExternalServiceError| 502  | "Upstream service unavailable"            |
| StorageError        | 500  | "Storage operation failed"                |
| ConfigurationError  | 500  | (logged, never returned to client)        |

## Global Exception Handler
- Single `@app.exception_handler(ClipForgeError)` in `api/middleware/error.py`.
- Logs full traceback, returns JSON with `{"error": ..., "detail": ..., "correlation_id": ...}`.
- Unhandled exceptions -> 500 with generic message + correlation_id.

## Graceful Degradation
- LLM highlight detection fails -> fall back to energy-based detection.
- Face detection fails -> log WARN, return center crop.
- Subtitle render fails -> fall back to classic ASS preset.
- FFmpeg failure -> mark job as `failed`, notify via webhook.

## Pattern: Non-Critical Fallback
```python
try:
    return self._primary_method(segments, total_duration, num_clips)
except Exception as e:
    logger.warning("primary_failed_falling_back", error=str(e))
    return self._fallback.detect(segments, total_duration, num_clips)
```

## Forbidden
- Exposing stack traces in API responses.
- `except: pass` (silent catch).
- `except Exception` without logging.
- Storing raw Python traceback in error_message — use concise description.

ponytail: Add Sentry integration for ERROR/CRITICAL alerting in production.
