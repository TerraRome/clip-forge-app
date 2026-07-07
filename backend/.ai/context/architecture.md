# Architecture: Layered but Lightweight

## Layers (top-down)

```
Routers (app/api/router.py)
  → Pydantic schemas (app/api/schemas.py)
  → Project model + FileStorage (app/models/, app/storage/)
  → Services (app/services/*)
    → CLI tools: yt-dlp, ffmpeg, ffprobe
    → ML models: whisper, MediaPipe, ONNX Runtime
```

## Router Layer (`app/api/router.py`)
- 4 endpoints: POST `/projects`, POST `/projects/{id}/process`, GET `/projects/{id}`, GET `/download/{id}`
- Input validation via Pydantic v2 `field_validator`
- Returns `ProjectResponse` with status + progress
- Process endpoint spawns background thread, returns immediately

## Domain Model (`app/models/project.py`)
- `Project` dataclass with `id`, `youtube_url`, `num_clips`, `subtitle_preset`, `status` (Enum: PENDING/PROCESSING/DONE/ERROR), `error_message`, `progress`, `clip_paths`
- `Project.create()` generates UUID
- `to_dict()` / `from_dict()` for JSON serialization

## Storage (`app/storage/file_storage.py`)
- `FileStorage` — thread-safe JSON file persistence
- Each project stored as `{downloads_dir}/_projects/{id}.json`
- Methods: `save`, `get`, `update`, `delete`
- Thread safety via `threading.Lock()`

## Services Layer
- Stateless service classes instantiated per-pipeline run
- No abstract interfaces (YAGNI: single impl per service)
- Services call subprocess (yt-dlp, ffmpeg) or load ML models (whisper, MediaPipe)
