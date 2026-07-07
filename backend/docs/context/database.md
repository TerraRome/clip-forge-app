# Database Design

## Purpose

ClipForge uses JSON file storage for MVP and will migrate to PostgreSQL via Alembic for production. This document describes the target relational schema, migration strategy, and indexing plan.

## Current MVP Storage

`FileStorage` (`app/storage/file_storage.py`) persists projects as individual JSON files under `downloads/_projects/{id}.json`. Thread safety via `threading.Lock`. One file per project, read/written atomically via `Path.write_text()` / `Path.read_text()`.

**Project JSON shape:**
```json
{
  "id": "uuid-string",
  "youtube_url": "https://...",
  "num_clips": 3,
  "subtitle_preset": "classic",
  "status": "processing",
  "error_message": "",
  "progress": 65.0,
  "clip_paths": ["downloads/uuid/clips/clip_01.mp4", ...]
}
```

## Target PostgreSQL Schema

### `projects` Table

```sql
CREATE TABLE projects (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    youtube_url     TEXT NOT NULL,
    num_clips       SMALLINT NOT NULL CHECK (num_clips IN (1, 3, 5, 10)),
    subtitle_preset VARCHAR(20) NOT NULL DEFAULT 'classic'
                    CHECK (subtitle_preset IN ('classic', 'tiktok_3words', 'word_pop', 'karaoke')),
    status          VARCHAR(20) NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'processing', 'done', 'error')),
    error_message   TEXT NOT NULL DEFAULT '',
    progress        REAL NOT NULL DEFAULT 0.0 CHECK (progress >= 0.0 AND progress <= 100.0),
    clip_paths      TEXT[] NOT NULL DEFAULT '{}',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- YouTube-specific metadata (added at download time)
    video_title     TEXT,
    video_duration  REAL,
    video_width     INT,
    video_height    INT,

    -- Ownership (future)
    user_id         UUID
);
```

### `transcript_segments` Table

Stores per-project transcript segments for reuse and inspection.

```sql
CREATE TABLE transcript_segments (
    id          BIGSERIAL PRIMARY KEY,
    project_id  UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    seq         SMALLINT NOT NULL,
    start_sec   REAL NOT NULL,
    end_sec     REAL NOT NULL,
    text        TEXT NOT NULL,

    CONSTRAINT unique_project_seq UNIQUE (project_id, seq)
);
```

### `clip_renders` Table

Tracks each individual clip render attempt for observability and retry.

```sql
CREATE TABLE clip_renders (
    id              BIGSERIAL PRIMARY KEY,
    project_id      UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    clip_index      SMALLINT NOT NULL,
    highlight_start REAL NOT NULL,
    highlight_end   REAL NOT NULL,
    subtitle_preset VARCHAR(20) NOT NULL,
    crop_filter     TEXT,
    face_detected   BOOLEAN NOT NULL DEFAULT FALSE,
    render_duration_ms INT,
    output_path     TEXT,
    status          VARCHAR(20) NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'processing', 'done', 'error')),
    error_message   TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at    TIMESTAMPTZ
);
```

## Indexing Strategy

```sql
-- Primary lookup: client polls by project ID (PK covers this)

-- Filtering active/in-flight projects
CREATE INDEX idx_projects_status ON projects(status);
CREATE INDEX idx_projects_user_id ON projects(user_id);  -- future

-- Analytics and cleanup
CREATE INDEX idx_projects_created_at ON projects(created_at);

-- Reuse transcript segments by project
CREATE INDEX idx_transcript_project ON transcript_segments(project_id);

-- Observability on per-clip failures
CREATE INDEX idx_clip_renders_project ON clip_renders(project_id);
CREATE INDEX idx_clip_renders_status ON clip_renders(status);
```

## Migrations via Alembic

### Directory Structure
```
backend/
  alembic/
    versions/          # Migration scripts
    env.py             # Alembic configuration
  alembic.ini          # Connection string (env-driven)
```

### Migration Workflow

```bash
# Create migration
alembic revision --autogenerate -m "add projects table"

# Apply
alembic upgrade head

# Rollback
alembic downgrade -1

# Show history
alembic history
```

### First Migration

The initial migration creates the `projects`, `transcript_segments`, and `clip_renders` tables. It migrates data from existing JSON files by reading `downloads/_projects/` and inserting rows.

## Migration Path from FileStorage

1. Deploy PostgreSQL and run Alembic migrations.
2. Write a one-shot script `scripts/migrate_fs_to_pg.py` that reads all JSON files and inserts into `projects` table.
3. Replace `FileStorage` with `PostgresStorage` implementing the same `ProjectRepository` protocol (`get/update/save/delete`).
4. The `state.py` singleton switches to the new repository.
5. Old JSON files become read-only backup.

## Best Practices

- **No raw SQL in application code**: All queries go through SQLAlchemy ORM or a repository class.
- **Migrations are immutable**: Once applied to production, never edit a committed migration. Create a new one.
- **Connection pooling**: Use `SQLAlchemy` with `psycopg2` or `asyncpg` for async. Pool size = `(2 × CPU) + 1` per worker.
- **Soft deletes**: Projects use a `deleted_at` nullable timestamp instead of `DELETE FROM`. Allows admin recovery.
- **Row-level security**: Future multi-tenant isolation via PostgreSQL RLS on `user_id`.
