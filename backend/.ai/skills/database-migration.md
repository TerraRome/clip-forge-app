# Alembic Migration: Generate and Apply Safely

## Description
Generate, review, and apply Alembic database migrations. Alembic tracks schema versions and enables repeatable, reversible upgrades. ClipForge does not yet use Alembic (uses file-based storage); use this skill when adding a database.

## When to Use
- Schema changes after model definition or modification
- Adding indexes, constraints, or new tables
- Reverting a schema change safely
- Syncing development/staging/production databases

## Inputs
- Model changes (new table, new column, column type change, constraint change)
- Migration message (short description of the change)
- Target database URL (from `app.config.settings` or `.env`)

## Outputs
- Migration script in `alembic/versions/` with `upgrade()` and `downgrade()` functions
- Applied or rolled-back database schema state

## Steps

1. **Set up Alembic** if not already: `alembic init alembic`. Configure `alembic.ini` with `sqlalchemy.url = postgresql://...` or use env var. In `alembic/env.py`, set `target_metadata = Base.metadata` (your SQLAlchemy `DeclarativeBase` subclass). Import all models in `env.py` or `app/models/__init__.py`.

2. **Auto-generate migration**: `alembic revision --autogenerate -m "description of change"`. This compares `Base.metadata` against the actual database and produces a version file. Models must be imported before running.

3. **Review generated migration** in `alembic/versions/`. Check: column types match intent (Alembic may infer `VARCHAR(255)` when you want `Text`), new columns have defaults or nullable (NOT NULL on existing tables with rows will fail), no accidental table drops, indexes correct.

4. **Edit if needed** — use `with op.batch_alter_context()` for SQLite (no ALTER TABLE support). Add `op.execute("UPDATE ...")` for data migrations. Add `op.create_index()` / `op.drop_index()` for index changes. Never edit a migration already committed to shared branches.

5. **Apply locally**: `alembic upgrade head`. Verify with `alembic current` (shows current revision). Test downgrade: `alembic downgrade -1`, then `alembic upgrade head` again. Verify all tests pass.

6. **Commit migration to version control** alongside the model changes that triggered it. The migration should be in the same PR/commit as the model.

## Example

```python
"""add clip_paths column to projects
Revision ID: a1b2c3d4e5f6
Revises: previous_revision
"""
from alembic import op
import sqlalchemy as sa

def upgrade():
    op.add_column("projects", sa.Column("clip_paths", sa.Text(), nullable=True))
    op.create_index("idx_projects_status", "projects", ["status"])

def downgrade():
    op.drop_index("idx_projects_status", table_name="projects")
    op.drop_column("projects", "clip_paths")
```

## Notes
- Run `alembic upgrade head` and pass all tests before committing. Verify `alembic downgrade -1` works for rollback safety.
- SQLite requires `with op.batch_alter_table("projects")` for any ALTER TABLE operation (rename column, drop column, add NOT NULL).
- Data migrations (backfill new columns) go in `upgrade()` AFTER schema changes, with reverse transform in `downgrade()`.
- Never run `--autogenerate` against production directly — generate from a local copy, review, then apply to production.
- Common pitfalls: column rename (Alembic sees as drop+add), NOT NULL on populated tables, forgetting to import new models before autogenerate.
