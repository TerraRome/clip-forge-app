# API Reference Summary

Base path: `/api` (v1 implicit, prefix with `/api/v1/` on breaking changes).

## Endpoint Table

| Method | Path | Status | Request Body | Response | Description |
|--------|------|--------|-------------|----------|-------------|
| POST | `/api/projects` | 201 | `CreateProjectRequest` | `ProjectResponse` | Create new clipping project |
| POST | `/api/projects/{id}/process` | 200 | - | `ProjectResponse` | Start async processing pipeline |
| GET | `/api/projects/{id}` | 200 | - | `ProjectResponse` | Get project status + result URLs |
| GET | `/api/download/{project_id}` | 200 | - | binary/zip | Download all clips as ZIP |
| GET | `/health` | 200 | - | `{"status": "ok"}` | Liveness check |

## Schemas

```json
// POST /api/projects
{
  "youtube_url": "https://youtube.com/watch?v=...",
  "num_clips": 3,
  "subtitle_preset": "classic"
}

// GET /api/projects/{id}
{
  "id": "uuid",
  "status": "pending|processing|done|error",
  "progress": 0.75,
  "error_message": "",
  "clip_paths": ["clips/clip_1.mp4", ...],
  "youtube_url": "...",
  "num_clips": 3,
  "subtitle_preset": "classic",
  "created_at": "ISO8601",
  "updated_at": "ISO8601"
}
```

## Auth
- **Current**: No authentication (local/MVP).
- **Future**: JWT Bearer token via `Authorization` header.
- Unauthenticated endpoints: `/health`.

## Error Responses
All errors return JSON: `{"detail": "message"}` with appropriate HTTP status (400, 404, 409, 500).
