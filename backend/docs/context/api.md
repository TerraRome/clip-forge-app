# REST API Design

## Purpose

ClipForge exposes a minimal REST API for the Flutter mobile frontend to create video projects, trigger processing, poll progress, and download finished clips. API-first design with Pydantic validation ensures type safety at the boundary.

## Base URL

```
http://{host}:{port}/api
```

All endpoints are prefixed with `/api` (configured in `main.py: app.include_router(router, prefix="/api")`).

## Endpoints

### POST /api/projects — Create Project

Create a new clipping project from a YouTube URL.

**Request Body:**
```json
{
  "youtube_url": "https://www.youtube.com/watch?v=ABC123xyz",
  "num_clips": 3,
  "subtitle_preset": "classic"
}
```

| Field | Type | Constraints | Default |
|-------|------|-------------|---------|
| youtube_url | string | Must match YouTube URL regex patterns (watch, youtu.be, shorts) | — |
| num_clips | integer | Must be 1, 3, 5, or 10 | — |
| subtitle_preset | string | classic, tiktok_3words, word_pop, karaoke | "classic" |

**Validation Rules** (in `schemas.py`):
- `youtube_url`: Regex matches `youtube.com/watch?v=`, `youtu.be/`, `youtube.com/shorts/` with 11-char video ID.
- `num_clips`: Validated via custom `@field_validator`, restricted to `{1, 3, 5, 10}`.
- `subtitle_preset`: Validated against `VALID_PRESETS` set.

**Response** `201 Created`:
```json
{
  "id": "uuid-string",
  "youtube_url": "https://www.youtube.com/watch?v=ABC123xyz",
  "num_clips": 3,
  "subtitle_preset": "classic",
  "status": "pending",
  "error_message": "",
  "progress": 0.0
}
```

**Errors:** `422 Unprocessable Entity` with Pydantic validation details.

### POST /api/projects/{project_id}/process — Start Processing

Triggers the full AI pipeline for a project. Only valid for projects in `pending` status.

**Response** `200 OK` (immediate, processing starts in background):
```json
{
  "id": "...",
  "status": "processing",
  "progress": 5.0,
  ...
}
```

**Errors:**
- `404 Not Found`: Project ID does not exist.
- `409 Conflict`: Project is not in `pending` status (already processing, done, or errored).

### GET /api/projects/{project_id} — Get Project Status

Poll this endpoint to track pipeline progress. Used by the Flutter frontend to update progress bars.

**Response** `200 OK`:
```json
{
  "id": "...",
  "status": "processing",
  "progress": 65.0,
  "error_message": "",
  ...
}
```

Progress values map to pipeline stages:
- 0%: Pending
- 5%: Download starting
- 20%: Download complete
- 30%: Audio extracted
- 50%: Transcription complete
- 65%: Highlights detected
- 65-100%: Per-clip rendering (evenly divided)

**Errors:** `404 Not Found`.

### GET /api/download/{project_id} — Download Clips

Returns a ZIP archive of all rendered MP4 clips. Only available when project status is `done`.

**Response** `200 OK`: Binary streaming ZIP response with `Content-Type: application/zip` and `Content-Disposition: attachment; filename="{project_id}.zip"`.

**Errors:**
- `404 Not Found`: Project does not exist.
- `400 Bad Request`: Project not yet in `done` state.

### GET /health — Health Check

Liveness probe. Not prefixed with `/api`.

**Response** `200 OK`:
```json
{
  "status": "ok"
}
```

## Error Response Format

All error responses follow the schema:
```json
{
  "detail": "Human-readable error message"
}
```

HTTP status codes used:
- `400`: Bad request (e.g., clips not ready)
- `404`: Resource not found
- `409`: Conflict (wrong state)
- `422`: Validation error (Pydantic)
- `500`: Internal server error (unhandled exceptions → FastAPI default)

## API Versioning

Current version is implicit (`v1`). The router prefix `/api` can be upgraded to `/api/v1` when breaking changes are introduced. Pydantic schemas are versioned by module — new versions get `schemas_v2.py` files with backward-compatible response models.

## Rate Limiting

Not yet implemented. Planned integration with slowapi for per-IP rate limiting on `POST /api/projects` and `POST /api/projects/{id}/process`. Download endpoint will have separate, higher limits.

## Authentication

Currently none. All endpoints are open. The `CORSMiddleware` allows all origins (`allow_origins=["*"]`). Production will add API key authentication via header validation middleware or OAuth2, with per-user project isolation and usage quotas.

## Best Practices

- **Idempotency**: `POST /api/projects` is not idempotent (creates new UUID each time). Future: accept optional `idempotency_key` header.
- **Polling**: Client polls every 2-3 seconds. Future: WebSocket for real-time progress events.
- **Large downloads**: The ZIP download streams via `StreamingResponse` (does not buffer entire archive in memory before sending).
- **Validation fails fast**: Pydantic validates at the boundary. Invalid requests never reach business logic.
