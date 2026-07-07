# Backend Overview: ClipForge FastAPI App

## Entry Point
- `app/__main__.py`: `uvicorn.run("app.main:app", host=settings.host, port=settings.port)`
- Supports `--no-reload` flag for production

## FastAPI App (`app/main.py`)
- `FastAPI(title="AI YouTube Clipper", version="0.1.0")`
- Lifespan handler configures `structlog` (JSON rendering, ISO timestamps, INFO level)
- CORS middleware: allows all origins
- Router prefix: `/api`
- Health check: `GET /health` returns `{"status": "ok"}`

## Config (`app/config.py`)
- `Settings(BaseSettings)` from `pydantic-settings`
- Fields: `host`, `port`, `downloads_dir`, `clips_dir`, `whisper_model`, `yt_dlp_cookies_file`, `ffmpeg_path`, `ffprobe_path`, `llm_api_base`, `llm_api_key`, `llm_model`
- Reads from `.env` file, no env prefix
- Global singleton: `settings = Settings()`

## DI Container
- No DI framework. `app/state.py` instantiates `storage = FileStorage()` as a module-level singleton
- Services are instantiated ad-hoc in `run_pipeline()`: `VideoService()`, `TranscriptService()`, `LLMHighlightService()`, `FaceService()`, `SmartCropService()`, `RenderService()`

## Threading Model
- Pipeline runs in a daemon thread (`threading.Thread(target=run_pipeline, args=(project_id,), daemon=True)`)
- No Celery/Redis — pure threading for simplicity
- FileStorage uses `threading.Lock()` for thread-safe JSON persistence
