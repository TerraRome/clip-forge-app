from pydantic_settings import BaseSettings


from pydantic_settings import BaseSettings


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
    celery_broker_url: str = "redis://localhost:6379/0"
    celery_result_backend: str = "redis://localhost:6379/0"

    model_config = {"env_prefix": "", "env_file": ".env"}


settings = Settings()