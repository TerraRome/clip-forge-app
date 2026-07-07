# Database Migration (JSON File Storage)

## Context
ClipForge uses file-based JSON storage (`app/storage/file_storage.py`), not SQL.
Projects are stored as `downloads/{project_id}/project.json`. "Migration" means
evolving the `Project` dataclass (`app/models/project.py`) schema and adding a
versioned migration in `FileStorage.get()`.

## Prerequisites
- `Project` dataclass changed in `app/models/project.py`
- Existing `project.json` files in `downloads/` from pre-migration projects
- Backup of `downloads/` created before any migration code runs

## Steps

1. **Add `schema_version` field** to `Project` dataclass:
   ```python
   @dataclass
   class Project:
       schema_version: int = field(default=2, compare=False)
       # ... existing fields ...
   ```
   Bump default when schema changes. Track current version in `FileStorage`:
   ```python
   CURRENT_SCHEMA_VERSION = 2
   ```

2. **Write migration function** in `app/storage/file_storage.py`:
   ```python
   _MIGRATIONS: dict[int, Callable[[dict], dict]] = {}

   def _register_migration(from_version: int):
       def wrapper(fn):
           _MIGRATIONS[from_version] = fn
           return fn
       return wrapper

   @_register_migration(from_version=1)
   def _migrate_v1_to_v2(data: dict) -> dict:
       """v1->v2: Add duration_seconds field, rename clip_count -> num_clips."""
       data["schema_version"] = 2
       if "num_clips" not in data and "clip_count" in data:
           data["num_clips"] = data.pop("clip_count")
       data.setdefault("duration_seconds", 0.0)
       data.setdefault("subtitle_preset", "classic")
       return data
   ```

3. **Run migration on load** — in `FileStorage.get()`:
   ```python
   def get(self, project_id: str) -> Optional[Project]:
       with self._lock:
           data = self._read_json(project_id)
       if data is None:
           return None
       version = data.get("schema_version", 1)
       while version < CURRENT_SCHEMA_VERSION:
           migrator = _MIGRATIONS.get(version)
           if migrator:
               data = migrator(data)
           version += 1
       # Auto-save migrated data
       if data.get("schema_version", 1) != CURRENT_SCHEMA_VERSION:
           self._write_json(project_id, data)
       return Project.from_dict(data)
   ```

4. **Backup existing data**:
   ```bash
   cp -r downloads downloads.backup.$(date +%Y%m%d_%H%M%S)
   ```

5. **Test migration on all existing projects**:
   ```python
   python3 -c "
   from pathlib import Path
   from app.state import storage
   count = errors = 0
   for d in Path('./downloads').iterdir():
       if (d / 'project.json').exists():
           p = storage.get(d.name)
           if p is None:
               print(f'FAIL: {d.name}')
               errors += 1
           else:
               count += 1
   print(f'Migrated {count} projects, {errors} errors')
   assert errors == 0
   "
   ```

6. **Deploy** — restart server (migration runs transparently on first `get()`):
   ```bash
   pkill -f "uvicorn app.main:app" || true
   nohup uvicorn app.main:app --host 0.0.0.0 --port 9999 > clipforge.log 2>&1 &
   ```

## Verification
- New project creation works with new schema
- Old projects loadable, with migrated fields populated
- `python3 -c "from app.state import storage; p = storage.get('some-old-id'); print(p.schema_version)"` prints `2`

## Rollback
```bash
# Restore old JSON files
cp -r downloads.backup.*/ downloads/
# Revert code
git revert HEAD --no-edit
```
