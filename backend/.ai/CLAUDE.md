# ClipForge — AI Video Clipping Platform

## Vision
AI-powered backend that turns long-form videos into viral-ready short clips. Import, analyze, clip, subtitle, crop, and export — all automated.

## Architecture
- **Clean Architecture** with Use Cases, Repositories, DI
- **FastAPI** API Gateway → **Celery** Workers → **PostgreSQL** + **Redis** + **MinIO**
- Event-driven pipeline: video uploaded → processed → clipped → rendered → exported
- Async worker orchestration for face detection, transcription, clip selection, rendering

## Tech Stack
Python 3.13, FastAPI, Pydantic v2, SQLAlchemy 2, Alembic, PostgreSQL, Redis, Celery, MinIO, Docker, PyTorch, ONNX Runtime, OpenCV, FFmpeg, Whisper, Pyannote, YOLO, MediaPipe, Sentence Transformers, JWT

## Folder Structure (within backend/)
```
.ai/               — Memory, standards, skills, playbooks, prompts
app/               — Application code (Clean Architecture)
docs/              — Documentation (ARCHITECTURE.md, context, etc.)
```

## Coding Rules
- Type hints everywhere. No `Any` unless unavoidable.
- Services are stateless. Inject dependencies via constructor.
- Repositories abstract DB access. Use cases orchestrate business logic.
- No business logic in controllers/endpoints.
- Async for I/O, sync for CPU-bound (delegated to workers).
- Structured logging (structlog) on every entry/exit point.
- Every public function has a docstring.
- Unit test for use cases. Integration test for repositories. E2E for API.

## Do
- Use `Result` types or custom exceptions for error handling
- Validate at boundary (Pydantic), trust inside
- SQLAlchemy 2 style queries (not legacy)
- Alembic for every schema change
- Docker Compose for local dev

## Don't
- Don't put business logic in routers
- Don't hardcode config — use Settings + .env
- Don't mix sync/async in same request path
- Don't import ORM models in use cases (use repository interfaces)

## Current Milestone
AI-powered backend for creators — post-MVP, pre-SaaS.

## Definition of Done
- Code passes `mypy --strict`
- Tests pass (unit + integration)
- API documented in OpenAPI
- Alembic migration generated
- Logs structured
- Error handled at boundary
- PR reviewed
