# Backend Architecture

## Purpose

ClipForge backend is a FastAPI Python application that ingests YouTube URLs, downloads videos, transcribes speech with OpenAI Whisper, AI-selects highlight moments, generates stylized subtitles, smart-crops to vertical 9:16 format, and renders finished clips with GPU-accelerated encoding. Serves a Flutter mobile frontend.

## Module Layout

```
backend/
  app/
    main.py              # FastAPI app factory, lifespan, middleware
    config.py            # Pydantic Settings (env-driven)
    state.py             # Global storage singleton
    api/
      router.py          # 5 REST endpoints
      schemas.py         # Pydantic request/response models
    models/
      project.py         # Project dataclass + ProjectStatus enum
    services/
      video_service.py       # yt-dlp download, ffmpeg audio extract, ffprobe info
      transcript_service.py  # Whisper transcription → TranscriptSegment list
      highlight_service.py   # Word-density sliding-window heuristic
      llm_highlight_service.py  # LLM-based (Groq) highlight detection with fallback
      face_service.py        # MediaPipe BlazeFace face detection in keyframes
      smart_crop_service.py  # Compute FFmpeg crop filter centered on face
      subtitle_service.py    # ASS subtitle generation, 4 presets
      render_service.py      # FFmpeg render pipeline (crop + subtitle + encode)
    worker/
      pipeline.py         # Sequential pipeline orchestrator
    storage/
      file_storage.py     # Thread-safe JSON file persistence
```

## How Modules Fit Together

1. **API layer** (`router.py`) receives HTTP requests, validates via Pydantic schemas, creates `Project` domain objects, and delegates processing to the worker pipeline.

2. **Worker** (`pipeline.py`) orchestrates the 7-stage sequential pipeline: download → extract audio → transcribe → probe video → detect highlights → face detect + smart crop per clip → render. Each stage updates `Project.progress` (0-100 scale) for polling clients.

3. **Services** are stateless singletons instantiated per pipeline run. `VideoService` wraps yt-dlp and FFmpeg subprocesses. `TranscriptService` loads a Whisper model once. `LLMHighlightService` calls Groq API with a system prompt, falling back to heuristic `HighlightService` on failure. `FaceService` and `SmartCropService` compute crop coordinates per clip. `SubtitleService` generates ASS format strings. `RenderService` assembles the final FFmpeg command.

4. **Storage** (`FileStorage`) persists projects as JSON files under `downloads/_projects/`. Thread-safe via `threading.Lock`. Provides `save/get/update/delete`.

5. **State** (`state.py`) is a global singleton holding the storage instance, imported by both API and worker modules.

## Pipeline Execution Model

Currently synchronous and single-threaded. Each `POST /api/projects/{id}/process` spawns a `threading.Thread` running `run_pipeline(project_id)`. The daemon thread updates project status in the JSON file as it progresses. The API polls progress via `GET /api/projects/{id}`.

This is an MVP threading model. The presence of a `worker/` module anticipates migration to Celery for production (see `worker.md` and `queue.md`).

## Data Flow

```
Client → POST /api/projects (create)
       → POST /api/projects/{id}/process (start)
       → GET  /api/projects/{id} (poll, progress 0→100)
       → GET  /api/download/{id} (fetch zip)
```

Internal:
```
yt-dlp → 16kHz WAV → Whisper → segments
                                → LLM → highlights
                                        → per clip:
                                            face detect → smart crop
                                            subtitle gen → ASS file
                                            ffmpeg: crop + ass burn + h264_vt → .mp4
```

## Key Design Decisions

- **Threading over Celery for MVP**: Avoids Redis dependency during early development. The `pipeline.py` structure mirrors a Celery task signature, making migration straightforward.
- **JSON file storage over PostgreSQL for MVP**: Projects are the only persisted entity. File-based storage eliminates DB setup friction. Schema is designed for one-to-one mapping to a `projects` table.
- **MacOS Videotoolbox GPU encoding**: `h264_videotoolbox` with 5000k bitrate. Platform-specific; production Linux targets would use `h264_nvenc` (NVIDIA) or `h264_vaapi`.
- **LLM fallback chain**: LLM highlight detection → heuristic word-density → evenly-spaced fallback. Graceful degradation at every level.
- **ASS subtitles over SRT**: ASS supports karaoke effects (`\K`), colored highlights, and per-word animation required by tiktok_3words, word_pop, and karaoke presets.

## Future Architecture

The planned production architecture adds: Celery workers (GPU + CPU pools), PostgreSQL with Alembic migrations, MinIO/S3 for file storage, Redis for result backend and task queue, and horizontal scaling via Docker Compose or Kubernetes.
