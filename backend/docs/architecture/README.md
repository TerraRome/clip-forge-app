# Architecture

## Layer Diagram (text-based)
```
┌──────────────────────────────────────────────────┐
│  Client (Flutter Mobile App)                     │
└──────────────────┬───────────────────────────────┘
                   │ HTTP/REST
                   ▼
┌──────────────────────────────────────────────────┐
│  API Layer (FastAPI Routers)                      │
│  - Parse request, validate (Pydantic)             │
│  - Call service, format response                  │
└──────────────────┬───────────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────────┐
│  Worker Pipeline                                  │
│  - Orchestrate: download -> transcribe ->         │
│    highlights -> render -> subtitle -> crop        │
│  - Progress tracking, error boundaries            │
└──────┬────────────────────────────────┬───────────┘
       │                                │
       ▼                                ▼
┌──────────────┐              ┌───────────────────┐
│  Services    │              │  Storage           │
│  - Transcript│              │  - FileStorage     │
│  - Highlight │              │  - Read/write JSON │
│  - Render    │              │  - Thread-safe     │
│  - SmartCrop │              └───────────────────┘
│  - Face      │
│  - Subtitle   │
└──────┬───────┘
       │
       ▼
┌──────────────────────────────────────────────────┐
│  Infrastructure (external tools via subprocess)   │
│  - FFmpeg  - Whisper  - MediaPipe  - yt-dlp     │
└──────────────────────────────────────────────────┘
```

## Data Flow
1. User creates project (POST /api/projects) -> stored as JSON.
2. User triggers processing (POST /api/projects/{id}/process) -> pipeline starts.
3. Pipeline downloads YouTube video via yt-dlp.
4. Audio extracted via FFmpeg -> transcribed via Whisper API.
5. Transcript analyzed for highlight segments (LLM or energy-based).
6. Clips rendered via FFmpeg (trim + concat).
7. Subtitles burned in (ASS format).
8. Smart crop applied (face detection + centering).
9. Status updated to DONE. Clips available for download.

## Layer Isolation Rules
- API never calls Storage directly (except read via state.storage at boundary).
- Services never import from app.api or app.worker.
- Storage never imports from app.services or app.models.
