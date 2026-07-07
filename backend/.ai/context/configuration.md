# Configuration: Pydantic Settings

## `Settings` Class (`app/config.py`)
```python
class Settings(BaseSettings):
    host: str = "0.0.0.0"
    port: int = 9999
    downloads_dir: str = "./downloads"
    clips_dir: str = "./clips"
    whisper_model: str = "base"
    yt_dlp_cookies_file: str = ""
    ffmpeg_path: str = "ffmpeg"
    ffprobe_path: str = "ffprobe"
    llm_api_base: str = "https://api.groq.com/openai/v1"
    llm_api_key: str = ""
    llm_model: str = "llama-3.3-70b-versatile"

    model_config = {"env_prefix": "", "env_file": ".env"}
```

## Resolution Order (Pydantic v2)
1. Explicit kwargs (not used currently)
2. Environment variables (case-insensitive match on field name)
3. `.env` file in CWD
4. Default values in class definition

## Loaded Once
- Global singleton: `settings = Settings()` at module import time
- Accessed via `from app.config import settings` throughout the codebase

## Effective Config (.env.example)
```env
HOST=0.0.0.0
PORT=8000
DOWNLOADS_DIR=./downloads
CLIPS_DIR=./clips
WHISPER_MODEL=base
FFMPEG_PATH=./ffmpeg_bin
YT_DLP_COOKIES_FILE=
```

## Secrets
- `llm_api_key` is stored in plaintext in `.env` (dev only)
- **Production**: use environment variables, not `.env` file
- Never commit `.env` to VCS (already in `.gitignore`)
