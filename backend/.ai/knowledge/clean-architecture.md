# Clean Architecture (ClipForge Interpretation)

## Layers vs Reality

| Layer | Clean Architecture | ClipForge |
|---|---|---|
| Entities | Business objects with rules | `Project` dataclass (anemic) |
| Use Cases | Application-specific business logic | `run_pipeline()` orchestration |
| Interface Adapters | Controllers, presenters, gateways | FastAPI router, Pydantic schemas |
| Frameworks | DB, web, external APIs | yt-dlp, ffmpeg, whisper, MediaPipe |

## Dependency Rule
- **Outer to Inner**: Router depends on services, services depend on nothing (not even inner layers)
- **Inner never depends on outer**: Project model has no reference to FastAPI or FileStorage
- Violation: `render_service.py` imports `SmartCropService` for fallback (could be passed in)

## Current Simplifications
- No abstract interfaces (YAGNI): `class VideoService` not `class VideoService(ABC)`
- No DI container: services created ad-hoc with `VideoService()`
- No repository interface: `FileStorage` is concrete
- No use case classes: `run_pipeline()` is a function, not a class

## When to Add Abstraction
- Second storage backend (S3/MinIO) → `StorageProtocol` abstract class
- Second highlight strategy → `HighlightDetector` ABC
- Unit testing requiring service mocking → inject mocks via constructor
