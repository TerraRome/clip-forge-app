# File Storage Strategy

## Purpose

ClipForge manages two categories of storage: project metadata (JSON files, migrating to PostgreSQL) and media files (downloaded videos, audio, rendered clips). This document covers the file organization, naming conventions, and migration path from local filesystem to MinIO/S3.

## Storage Layout

### Current Directory Structure

```
downloads/                        ← settings.downloads_dir
├── _projects/                    ← JSON metadata (FileStorage)
│   ├── {project_id}.json
│   └── {project_id}.json
└── {project_id}/                 ← Per-project media directory
    ├── source.mp4                ← Original YouTube download
    ├── audio.wav                 ← Extracted 16kHz mono PCM
    ├── clips/
    │   ├── clip_01.mp4           ← Rendered output
    │   ├── clip_02.mp4
    │   └── clip_03.mp4
    └── ass/                      ← Intermediate ASS files (debug)
        ├── clip_01.ass
        └── clip_02.ass
```

### Path Convention

All paths are relative to `settings.downloads_dir`:

| File | Pattern | Example |
|---|---|---|
| Project metadata | `_projects/{id}.json` | `_projects/a1b2c3.json` |
| Source video | `{id}/source.mp4` | `a1b2c3/source.mp4` |
| Audio | `{id}/audio.wav` | `a1b2c3/audio.wav` |
| Clip output | `{id}/clips/clip_{nn}.mp4` | `a1b2c3/clips/clip_01.mp4` |
| ASS subtitle | `{id}/clips/clip_{nn}.ass` | `a1b2c3/clips/clip_01.ass` |

The `_projects/` prefix uses underscore to sort before project directories alphabetically and signals it's a system directory, not user data.

## FileStorage (`app/storage/file_storage.py`)

The `FileStorage` class is a thread-safe JSON persistence layer:

- **Thread safety**: `threading.Lock` protects all read/write operations.
- **Serialization**: Project → `to_dict()` → `json.dumps()` → file write. Reverse on read.
- **Directory lifecycle**: Created on first `save()` via `path.parent.mkdir(parents=True, exist_ok=True)`.
- **Consistency**: Writes are atomic at the filesystem level for small JSON files (single `write_text()` call). Not crash-safe for power loss — production migrates to PostgreSQL.

### FileStorage Interface

```python
class FileStorage:
    def save(self, project: Project) -> None
    def get(self, project_id: str) -> Optional[Project]
    def update(self, project_id: str, **kwargs) -> Optional[Project]
    def delete(self, project_id: str) -> None
```

## Target S3/MinIO Architecture

### Object Key Convention

```
projects/{project_id}/metadata.json       ← project state (DB backup)
projects/{project_id}/source.mp4
projects/{project_id}/audio.wav
projects/{project_id}/clips/clip_01.mp4
projects/{project_id}/clips/clip_02.mp4
projects/{project_id}/ass/clip_01.ass
```

### Bucket Organization

| Bucket | Purpose | Retention |
|---|---|---|
| `clipforge-source` | Downloaded source videos | 24 hours after render complete |
| `clipforge-clips` | Rendered output clips | 7 days |
| `clipforge-assets` | Intermediate files (audio, ASS) | 24 hours |

Lifecycle rules auto-expire source and assets after TTL. Clips expire after 7 days unless saved by user.

### Storage Abstraction

A `StorageBackend` protocol abstracts local FS, MinIO, and S3:

```python
from abc import ABC, abstractmethod
from pathlib import Path

class StorageBackend(ABC):
    @abstractmethod
    def read_text(self, key: str) -> str: ...
    @abstractmethod
    def write_text(self, key: str, data: str) -> None: ...
    @abstractmethod
    def read_binary(self, key: str) -> bytes: ...
    @abstractmethod
    def write_binary(self, key: str, data: bytes) -> None: ...
    @abstractmethod
    def exists(self, key: str) -> bool: ...
    @abstractmethod
    def delete(self, key: str) -> None: ...
    @abstractmethod
    def list(self, prefix: str) -> list[str]: ...
```

Implementation: `LocalStorage` (current), `MinioStorage`, `S3Storage`. The `FileStorage` metadata class remains for project state; media storage uses `StorageBackend` directly.

## Migration Path from Local to S3

1. Add `StorageBackend` protocol and `MinioStorage` implementation.
2. Update `state.py` to select backend via `settings.storage_backend`.
3. Create migration script: enumerate `downloads/{id}/`, upload each project directory to MinIO under `projects/{id}/`.
4. Update pipeline services to use `StorageBackend.read_binary`/`write_binary` instead of local paths.
5. Deploy MinIO via Docker Compose. No application code changes beyond config.

## Cleanup Strategy

```python
@celery_app.task
def cleanup_project(project_id: str):
    """Delete project files after retention period."""
    shutil.rmtree(Path(settings.downloads_dir) / project_id, ignore_errors=True)
    Path(settings.downloads_dir / "_projects" / f"{project_id}.json").unlink(missing_ok=True)
```

Schedule via Celery Beat: runs every hour, deletes projects older than `settings.retention_hours` (default 72 for source, 168 for clips).

## Best Practices

- **Never hardcode paths**: All file operations use `settings.downloads_dir` or `settings.clips_dir`.
- **Temp files go to system temp**: Whisper audio extraction uses `tempfile.NamedTemporaryFile` for intermediate artifacts.
- **Path objects over strings**: Internal code uses `pathlib.Path`. String paths only at service boundaries (FFmpeg subprocess args).
- **.gitignore ignores downloads**: `downloads/` is in `.gitignore`. Storage is runtime data, not code.
