# Database: No Database (File-Based)

## Current State
- **No PostgreSQL or SQLAlchemy**. All persistence uses JSON files on disk.
- Each project stored as `{downloads_dir}/_projects/{uuid}.json`
- FileStorage provides CRUD with thread-safe reads/writes

## Why File-Based
- Single-user development phase
- Eliminates DB infra requirement
- Sufficient for current project volume

## Project JSON Schema
```json
{
  "id": "uuid-string",
  "youtube_url": "https://youtube.com/watch?v=...",
  "num_clips": 3,
  "subtitle_preset": "classic",
  "status": "pending",
  "error_message": "",
  "progress": 0.0,
  "clip_paths": []
}
```

## When to Migrate
- Add async SQLAlchemy 2.0 with `mapped_column`, `select()` style queries
- Alembic for migrations
- PostgreSQL with `projects` table mirroring the JSON shape
- Add `created_at` / `updated_at` timestamps
- Migration path: keep FileStorage as fallback, add optional `DatabaseStorage` implementing same interface

## Current Model
- `app/models/project.py`: `@dataclass` Project + `ProjectStatus(str, Enum)`
- `to_dict()` / `from_dict()` handles serialization
