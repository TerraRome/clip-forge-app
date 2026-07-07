# ClipForge Project Memory

## Current Architecture Decisions
- **Monolith first** — Single FastAPI app with Celery workers. Extract to microservices when scaling warrants it.
- **File-based storage for MVP** — MinIO/S3 added when SaaS multi-tenant required.
- **LLM as judge** — Groq (Llama-3.3-70B) for highlight selection. Configurable via env to swap provider.
- **ASS subtitle format** — Enables karaoke-style word highlighting, not possible with SRT.
- **GPU encoding** — VideoToolbox on Mac, NVENC on Linux. Configurable via ffmpeg_path.

## Completed Features
- YouTube download via yt-dlp
- Audio extraction via FFmpeg
- Speech-to-text via Whisper (language="id")
- LLM-based highlight selection (Groq)
- Face detection via MediaPipe BlazeFace
- Smart crop 9:16 (face-aware, fallback center)
- Subtitle presets: classic, tiktok_3words, word_pop, karaoke
- GPU-accelerated rendering
- Structured folder layout per project
- ZIP download endpoint

## Known Issues
- Whisper on CPU is slow. GPU acceleration needed for production.
- Word Pop/Karaoke subtitle presets re-transcribe each clip (adds latency).
- No speaker diarization — assumes single speaker per highlight.
- No scene detection — highlight boundaries may cut mid-scene.
- Haar cascade was replaced by MediaPipe; old dependency remains in requirements.

## Current Feature
Multi-speaker pan — detect multiple faces and pan between speakers.

## Next Feature
- Multi-speaker face tracking with FFmpeg expression-based crop
- Scene detection for better clip boundaries
- Auto-generate titles/descriptions/hashtags via LLM

## Long-Term Goals
- SaaS with auth, billing, workspaces
- Direct social media API upload
- Real-time livestream clipping
- Team collaboration

## Lessons Learned
- Haar cascade fails on profile faces. MediaPipe BlazeFace handles all angles.
- Whisper on CPU is ~3× slower than using GPU acceleration.
- LLM highlight selection is far superior to energy-based heuristics.
- GPU encoding (VideoToolbox) gives ~3× speedup over software x264.
- Project-wide `.ai/` context files dramatically reduce context loss between sessions.
