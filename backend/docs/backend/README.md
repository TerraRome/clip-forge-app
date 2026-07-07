# Backend Architecture Overview

## Stack
- **Runtime**: Python 3.13
- **Framework**: FastAPI
- **Task Queue**: Celery (sync worker thread in MVP)
- **Storage**: JSON filesystem (MVP), PostgreSQL + MinIO (future)
- **Media**: FFmpeg, Whisper (OpenAI), MediaPipe, yt-dlp

## Folder Structure
```
backend/
├── app/
│   ├── api/              # FastAPI routers (endpoints, schemas, deps)
│   │   ├── router.py     # Main router (health, projects, download)
│   │   └── schemas.py    # Pydantic request/response models
│   ├── services/         # Business logic (transcript, highlight, render, crop, face)
│   ├── storage/          # Persistence (FileStorage, protocol)
│   ├── worker/           # Pipeline orchestration (run_pipeline)
│   ├── models/           # Domain dataclasses (Project, Clip, Segment, etc.)
│   ├── core/             # Config (logging, settings, exceptions)
│   ├── config.py         # pydantic-settings BaseSettings
│   └── state.py          # Module-level singletons (storage, model caches)
├── tests/                # Unit + integration tests
├── requirements.txt
└── Dockerfile
```

## Entry Points
- **API server**: `python -m uvicorn app.main:app` (FastAPI)
- **Worker**: Triggered via `state.storage` + daemon thread in current MVP
- **Future**: `celery -A app.worker worker` for distributed processing

## Key Design Decisions
- File-based storage for MVP (zero infrastructure dependencies for development).
- Sync pipeline thread with cooperative locking (threading.Lock).
- All external tools (FFmpeg, Whisper, yt-dlp) called via subprocess.
- Graceful degradation chain for LLM/face detection failures.
