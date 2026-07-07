# Architecture Standards — ClipForge

## Layers (strict dependency direction)
```
api/  ->  service/  ->  domain/  <-  storage/
│               │                 │
└───worker/ ────┘                 └── infrastructure/
```
- **api/** — FastAPI routers. Request parsing, response formatting. No business logic.
- **service/** — Orchestration. Calls domain + storage. Transaction boundaries here.
- **domain/** — Pure business logic. Zero I/O. Zero dependency on framework.
- **storage/** — DB repos, file storage abstractions. Implementation depends on domain interfaces.
- **worker/** — Celery tasks. Thin adapter calling services. No logic.
- **infrastructure/** — FFmpeg, Whisper, MediaPipe wrappers. Replaceable.

## Rules
- Outer layers depend on inner layers, never the reverse.
- `domain/` imports NOTHING from `api/`, `worker/`, or `storage/`.
- `service/` injects dependencies; `domain/` defines them as abstract protocols.
- Every layer communicates via Pydantic models from `domain/` — never raw dicts.

## Dependency Injection
- FastAPI `Depends()` for request-scoped deps (DB session, auth user).
- Service classes receive deps via constructor — wired by `lifespan` or factory.
- Worker tasks receive deps via Celery `__init__` task base class.

## Repository Pattern
- `storage/repositories/` implement domain protocols.
- One repo per aggregate root. Methods map to domain concepts, not SQL.
- Queries return domain models, not ORM objects.

## File Storage
- Current MVP: `FileStorage` (JSON on disk) with `threading.Lock`.
- Future: `S3Storage` implementing same protocol.
- Uploaded media cleaned by TTL sweep in worker.

## State
- Module-level singleton for shared resources (storage, model caches).
- Lazy init for expensive resources (Whisper model, MediaPipe detector).
- Initialized at import time via `app/state.py`.

## Forbidden
- Services importing from `app.api` or `app.worker`.
- Business logic in `config.py` or `state.py`.
- Circular imports between `services/` and `storage/`.
- Importing `settings` in domain model files — models must be pure Python.

ponytail: Add CQRS event bus when cross-aggregate consistency needed.
