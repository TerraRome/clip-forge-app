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

    model_config = {"env_prefix": "", "env_file": ".env"}


settings = Settings()