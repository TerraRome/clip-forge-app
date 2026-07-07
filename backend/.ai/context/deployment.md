# Deployment: Current State

## Current Setup
- No Docker. Runs directly with Python on macOS.
- Dependencies installed via `pip install -r requirements.txt`
- Run: `python -m app` (with optional `--no-reload`)

## Dependencies
```
fastapi, uvicorn, pydantic, pydantic-settings
openai-whisper, yt-dlp, python-multipart, structlog
opencv-python, mediapipe, numpy          # face detection
openai                                   # LLM highlights
```

## System Dependencies (manual)
- `ffmpeg` / `ffprobe` (with `h264_videotoolbox` encoder for macOS GPU encoding)
- `blaze_face_short_range.tflite` (MediaPipe model file at backend root)

## Future Docker Setup
- `Dockerfile` multi-stage: builder → runtime
- `docker-compose.yml` services: api (FastAPI + uvicorn worker), celery-worker (GPU), redis, postgres
- Volumes: `downloads/`, `clips/`, TFLite model
- GPU passthrough: `--device /dev/dri` (Linux VAAPI) or nvidia-container-toolkit

## Environment Variables
| Variable | Default | Description |
|---|---|---|
| HOST | 0.0.0.0 | Bind address |
| PORT | 9999 | HTTP port |
| DOWNLOADS_DIR | ./downloads | Media storage root |
| WHISPER_MODEL | base | Whisper model size |
| LLM_API_KEY | (none) | Groq/OpenAI API key |
| LLM_API_BASE | https://api.groq.com/openai/v1 | LLM endpoint |
| LLM_MODEL | llama-3.3-70b-versatile | Model name |
