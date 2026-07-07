# Database Schema Overview

## Current MVP: File-based JSON

Storage: `FileStorage` writes individual `{project_id}.json` files under `_projects/` directory.

### Project Schema (stored as JSON file)
```json
{
  "id": "a1b2c3d4-...",
  "youtube_url": "https://youtube.com/watch?v=...",
  "num_clips": 3,
  "subtitle_preset": "classic",
  "status": "done",
  "error_message": "",
  "progress": 1.0,
  "clip_paths": ["clip_1.mp4", "clip_2.mp4", "clip_3.mp4"],
  "created_at": "2026-07-07T12:00:00Z",
  "updated_at": "2026-07-07T12:05:00Z"
}
```

## Future PostgreSQL Schema (planned)

### Key Tables

| Table | Description | Key Columns |
|-------|-------------|-------------|
| `projects` | Root entity for clipping jobs | id (UUID PK), youtube_url, num_clips, status, progress |
| `clip_renders` | Individual clip outputs | id (UUID PK), project_id (FK), path, duration_s, order |
| `users` | User accounts (future) | id (UUID PK), email, auth_provider, external_id |
| `webhook_events` | Outbound webhook delivery log | id (UUID PK), project_id (FK), url, status, attempts |

### Relationships
- `projects` 1:N `clip_renders` (one project produces multiple clips)
- `users` 1:N `projects` (auth feature, not yet implemented)
- `projects` 1:N `webhook_events` (not yet implemented)

### Status Enum
`PENDING -> PROCESSING -> DONE` (or `ERROR` from any state)
