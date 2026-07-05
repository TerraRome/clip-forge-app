# AI YouTube Clipper — Architecture

## Overall Architecture

```mermaid
graph TB
    subgraph Client ["Flutter Mobile App"]
        F[Flutter UI\nScreen Layer]
        B[Bloc Layer\nState Management]
        R[Repository Layer\nData Abstraction]
        D[Data Layer\nAPI + Hive]
    end

    subgraph Server ["FastAPI Backend"]
        API[API Layer\nFastAPI Endpoints]
        S[Service Layer\nBusiness Logic]
        P[Pipeline\nProcessing Engine]
    end

    subgraph Pipeline ["AI Pipeline"]
        DL[Downloader\nyt-dlp]
        AE[Audio Extractor\nFFmpeg]
        WP[Whisper\nTranscription]
        HL[Highlight\nDetection]
        RE[Renderer\nFFmpeg + subtitles]
    end

    subgraph Storage ["Storage"]
        FS[File System\nTemp Storage]
    end

    F -->|HTTP/REST| API
    API --> S
    S --> P
    P --> DL --> AE --> WP --> HL --> RE
    RE --> FS
    FS -->|Serve files| API
    API -->|ZIP stream| F
```

## Responsibilities

### Flutter (Client)

- **UI layer**: Render screens, handle gestures, show progress
- **Bloc layer**: Business logic per feature, state transitions, API polling
- **Repository layer**: Abstract data sources (API + Hive) behind interface
- **Data layer**: HTTP client (Dio), local cache (Hive), DTOs

### FastAPI (Backend)

- **API layer**: Endpoints, validation, error handling, CORS
- **Service layer**: Orchestration, project lifecycle management
- **Pipeline**: Sequential processing stages (download → transcribe → highlight → render)

### AI Pipeline

- **yt-dlp**: Download YouTube video in best quality available
- **FFmpeg**: Audio extraction, video cropping/resizing, subtitle burning
- **Whisper (openai-whisper)**: Speech-to-text transcription with timestamps
- **Highlight Detection**: Heuristic algorithm based on transcript features (speech rate, keyword density, silence gaps)

## Communication Pattern

```
Flutter                     FastAPI                      Pipeline
   │                          │                            │
   │── POST /api/projects ───→│                            │
   │←──── { id, status } ─────│                            │
   │                          │── Start background task ──→│
   │                          │                            │
   │── GET /api/projects/id ─→│                            │── Downloading ──→ ...
   │←─── { status: 30% } ─────│                            │
   │                          │                            │
   │── GET /api/projects/id ─→│                            │── Rendering ────→ ...
   │←─── { status: 70% } ─────│                            │
   │                          │                            │
   │── GET /api/projects/id ─→│                            │── Done
   │←─── { status: done } ────│                            │
   │                          │                            │
   │── GET /api/download/id ─→│                            │
   │←───── ZIP stream ────────│                            │
```

## Data Flow (End-to-End)

```mermaid
sequenceDiagram
    participant User
    participant Flutter
    participant FastAPI
    participant Pipeline
    participant FS as File System

    User->>Flutter: Paste YouTube URL
    User->>Flutter: Select clip count (3)
    User->>Flutter: Tap "Start"
    Flutter->>FastAPI: POST /api/projects {url, clip_count}
    FastAPI->>FastAPI: Validate input
    FastAPI-->>Flutter: 201 { id: "proj_abc123" }
    Flutter->>FastAPI: POST /api/projects/proj_abc123/process
    FastAPI-->>Flutter: 202 { status: "processing" }
    FastAPI->>Pipeline: Start background task

    Pipeline->>Pipeline: Download video (yt-dlp)
    Pipeline->>FS: Save video.mp4
    Pipeline->>Pipeline: Extract audio (FFmpeg)
    Pipeline->>FS: Save audio.wav
    Pipeline->>Pipeline: Transcribe (Whisper)
    Pipeline->>Pipeline: Detect highlights
    Pipeline->>Pipeline: Render clips (FFmpeg + subtitles)
    Pipeline->>FS: Save clip_0.mp4...clip_2.mp4
    Pipeline->>FastAPI: Update status → "done"

    loop every 3s
        Flutter->>FastAPI: GET /api/projects/proj_abc123
        FastAPI-->>Flutter: { status: "done", progress: 100 }
    end

    User->>Flutter: Tap "Download"
    Flutter->>FastAPI: GET /api/download/proj_abc123
    FastAPI->>FS: Read clip files
    FastAPI-->>Flutter: ZIP stream
    Flutter->>User: Save to device / Share
```

## Folder Structure

### Flutter

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   ├── router/
│   ├── theme/
│   └── ui/
├── data/
│   ├── datasources/
│   │   ├── api/
│   │   └── local/
│   ├── dto/
│   └── repositories/
├── domain/
│   ├── entities/
│   └── repositories/     # abstract interfaces
└── features/
    ├── home/
    │   └── presentation/
    │       ├── pages/
    │       └── widgets/
    ├── new_project/
    │   ├── bloc/
    │   └── presentation/
    ├── processing/
    │   ├── bloc/
    │   └── presentation/
    └── results/
        ├── bloc/
        └── presentation/
```

### Python (Backend)

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI app entry
│   ├── config.py            # pydantic-settings
│   ├── logging_config.py    # structlog setup
│   ├── api/
│   │   ├── __init__.py
│   │   ├── router.py        # all endpoint routes
│   │   ├── schemas.py       # pydantic request/response models
│   │   └── dependencies.py  # DI
│   ├── services/
│   │   ├── __init__.py
│   │   ├── project_service.py
│   │   ├── video_service.py
│   │   ├── audio_service.py
│   │   ├── transcript_service.py
│   │   ├── highlight_service.py
│   │   └── render_service.py
│   ├── pipeline/
│   │   ├── __init__.py
│   │   ├── orchestrator.py  # pipeline coordinator
│   │   └── exceptions.py
│   └── models/
│       ├── __init__.py
│       └── project.py       # Project dataclass/model
├── temp/                     # working directory for downloads/outputs
├── pyproject.toml
├── Dockerfile
└── .env.example
```

## Key Architecture Decisions

| Decision              | Choice                       | Rationale                                                         |
| --------------------- | ---------------------------- | ----------------------------------------------------------------- |
| State management      | Bloc                         | Predictable, testable, scales with features                       |
| API communication     | REST + polling               | Simpler than WebSocket for MVP; polling sufficient for 5-min jobs |
| Background processing | FastAPI BackgroundTasks      | Avoids Celery/Redis complexity for MVP; revisit if load grows     |
| Highlight detection   | Heuristic (transcript-based) | No ML model training needed; decent results for MVP               |
| Local storage         | File system (temp dir)       | Simple, no DB needed for MVP; ZIP on demand                       |
| Client caching        | Hive                         | Lightweight, fast, no native dependencies                         |
| DI                    | Injectable + GetIt           | Generated DI, minimal boilerplate                                 |
| Code generation       | Freezed                      | Immutable state/events, union types, equality                     |

## Non-Functional Architecture

### Concurrency

- **Flutter**: Single isolate (no isolates for MVP)
- **Backend**: BackgroundTasks runs in same process; GIL-bound but I/O-heavy pipeline benefits from async
- **Pipeline stages**: Sequential within a project; parallel across projects (up to 10 concurrent)

### Scalability

- Limited by server CPU (Whisper) and disk I/O
- Future: Celery workers, GPU inference, S3 storage

### Security

- No auth for MVP (closed deployment)
- Input validation on both client and server
- Temp file cleanup after download or on failure
- Rate limiting per IP (future)
