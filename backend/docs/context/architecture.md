# Clean Architecture

## Purpose

ClipForge follows Clean Architecture principles to isolate business logic from frameworks, infrastructure, and external services. This enables testability, swapping of AI providers, storage backends, or queue systems without changing core logic.

## Layer Diagram

```
┌──────────────────────────────────────────────────────┐
│                   API / Controllers                   │
│           (FastAPI router, Pydantic schemas)          │
├──────────────────────────────────────────────────────┤
│                   Use Cases                           │
│   (run_pipeline, detect_highlights, render_clip)      │
├──────────────────────────────────────────────────────┤
│                Domain / Entities                      │
│      (Project, TranscriptSegment, HighlightSegment,   │
│                FaceBox, ProjectStatus)                │
├──────────────────────────────────────────────────────┤
│              Interface Adapters                       │
│  (VideoService, Storage protocol, LLM client wrapper) │
├──────────────────────────────────────────────────────┤
│              Frameworks & Infrastructure              │
│ (FastAPI, Whisper, FFmpeg, yt-dlp, MediaPipe, Redis)  │
└──────────────────────────────────────────────────────┘
```

## Layer Details

### Controllers (API Layer) — `app/api/`

FastAPI router (`router.py`) is the sole controller. It handles HTTP concerns only: request parsing, validation via Pydantic, response serialization, status codes, error responses. No business logic lives here.

- `create_project` — validates input via `CreateProjectRequest`, delegates to `Project.create()` factory, persists via `storage.save()`.
- `process_project` — validates project exists and is in `PENDING` state, transitions to `PROCESSING`, spawns pipeline thread.
- `get_project` — reads project from storage, returns status/progress.
- `download_clips` — builds zip archive of rendered clips on demand.
- `health` — liveness probe.

### Use Cases — `app/worker/pipeline.py`

`run_pipeline()` is the primary use case orchestrator. It defines the sequence of operations without knowing how each step works internally. Each service call is a use-case step:

1. `video_svc.download()` → acquire raw video
2. `video_svc.extract_audio()` → prepare audio for transcription
3. `transcript_svc.transcribe()` → produce segments
4. `video_svc.get_info()` → get dimensions + duration
5. `highlight_svc.detect()` → select highlight windows
6. Per highlight: `face_svc.detect_dominant_face()`, `crop_svc.compute_filter()`, `render_svc.render_clip()`
7. `storage.update(status=DONE)` → finalize

Each step updates progress and logs structured events. Error handling at the pipeline level catches all exceptions and transitions the project to `ERROR` state.

### Domain Entities — `app/models/`, shared value objects

- **Project**: Core aggregate root. `id`, `youtube_url`, `num_clips`, `subtitle_preset`, `status` (PENDING/PROCESSING/DONE/ERROR), `progress`, `error_message`, `clip_paths`. Has `create()` factory and `to_dict()`/`from_dict()` serialization.
- **TranscriptSegment**: `start`/`end` (float seconds), `text`. Produced by Whisper.
- **HighlightSegment**: `start`/`end`/`score`. Produced by highlight detectors.
- **FaceBox**: `x`/`y`/`w`/`h` (normalized 0-1), `score`. Produced by FaceService.
- **ProjectStatus**: String enum with 4 states. Used as state machine guard in controllers.

### Interface Adapters — `app/services/`

Services wrap external dependencies behind stable interfaces:

- **VideoService**: Adapter for yt-dlp and FFmpeg subprocesses. Methods: `download()`, `extract_audio()`, `get_info()`. All accept/return plain strings and dicts.
- **TranscriptService**: Adapter for OpenAI Whisper. Loads model once, `transcribe()` returns `list[TranscriptSegment]`. The Whisper model reference is an implementation detail.
- **LLMHighlightService / HighlightService**: Two implementations of highlight detection. Primary uses Groq API via OpenAI-compatible client. Fallback uses word-density heuristic. Both return `list[HighlightSegment]`. The `LLMHighlightService` imports and delegates to `HighlightService` as fallback — a Strategy pattern.
- **FaceService**: Adapter for MediaPipe BlazeFace. Lazy-loads the TFLite model on first call. Returns `FaceBox` or `None`.
- **SmartCropService**: Pure computation. No external deps. `compute_filter()` returns an FFmpeg filter string.
- **SubtitleService**: Pure functions. `build_ass()` returns ASS format string. No state.
- **RenderService**: Adapter for FFmpeg. Assembles and runs the rendering subprocess with correct filter chains.

### Frameworks & Infrastructure

- **FastAPI**: HTTP framework, dependency injection via module-level imports.
- **FFmpeg**: Video/audio processing invoked via `subprocess.run()`. Path configurable via `settings.ffmpeg_path`.
- **Whisper**: ML model loaded in-process via Python package.
- **MediaPipe**: ML model loaded in-process for face detection.
- **FileStorage**: JSON file persistence. `threading.Lock` for thread safety. Location under `settings.downloads_dir / "_projects"`.
- **OpenAI SDK**: Used with Groq-compatible API endpoint for LLM highlight detection.

## Dependency Rule

Dependencies point inward. Controllers depend on use cases and domain. Use cases depend on domain and interface adapters. Domain entities depend on nothing. Interface adapters depend on domain. Every layer depends only on the layer directly inside it.

Current violations (acceptable for MVP): `pipeline.py` (use case) directly instantiates service classes (interface adapters) rather than receiving them via dependency injection. The `LLMHighlightService` directly instantiates its heuristic fallback. These will be addressed with a DI container when the service count grows.

## Migration Path

Adding Celery: `run_pipeline()` becomes a Celery task. The use case remains unchanged; only the invocation mechanism changes. Adding PostgreSQL: `FileStorage` is replaced with a `ProjectRepository` implementing the same `get/update/save/delete` interface. The rest of the application never imports `file_storage` directly (only via `state.py`).
