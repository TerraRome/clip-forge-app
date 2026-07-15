import subprocess
import structlog
from pathlib import Path

from app.config import settings

logger = structlog.get_logger()


class VideoService:
    def download_clip(self, url: str, output_path: str, start_time: float, end_time: float) -> str:
        path = Path(output_path)
        path.parent.mkdir(parents=True, exist_ok=True)

        duration = end_time - start_time
        cmd = [
            "python3", "-m", "yt_dlp",
            "--download-sections", f"*{start_time}-{end_time}",
            "-f", "best[height<=1080]",
            "--ffmpeg-location", settings.ffmpeg_path,
            "--no-warnings",
            "-o", str(path),
            url,
        ]
        if settings.yt_dlp_cookies_file:
            cmd.extend(["--cookies", settings.yt_dlp_cookies_file])

        logger.info("downloading_clip", url=url, start=start_time, end=end_time, output=output_path)
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=600, stdin=subprocess.DEVNULL)
        if result.returncode != 0:
            stderr_lines = [l for l in result.stderr.splitlines()
                           if "NotOpenSSLWarning" not in l
                           and "Deprecated Feature" not in l
                           and "urllib3" not in l
                           and "warnings.warn" not in l]
            err_text = "\n".join(stderr_lines).strip()
            if err_text:
                logger.error("download_failed", stderr=err_text)
                raise RuntimeError(f"yt-dlp failed: {err_text}")

        logger.info("download_complete", path=output_path)
        return output_path

    def extract_audio(self, video_path: str, audio_path: str) -> str:
        path = Path(audio_path)
        path.parent.mkdir(parents=True, exist_ok=True)

        cmd = [
            settings.ffmpeg_path, "-y",
            "-i", video_path,
            "-vn",
            "-acodec", "pcm_s16le",
            "-ar", "16000",
            "-ac", "1",
            str(path),
        ]

        logger.info("extracting_audio", video=video_path, output=audio_path)
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=600, stdin=subprocess.DEVNULL)
        if result.returncode != 0:
            logger.error("audio_extraction_failed", stderr=result.stderr)
            raise RuntimeError(f"FFmpeg audio extraction failed: {result.stderr}")

        logger.info("audio_extraction_complete", path=audio_path)
        return audio_path

    def get_info(self, video_path: str) -> dict:
        cmd = [
            settings.ffprobe_path, "-v", "quiet",
            "-print_format", "json",
            "-show_format",
            "-show_streams",
            video_path,
        ]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30, stdin=subprocess.DEVNULL)
        if result.returncode != 0:
            raise RuntimeError(f"ffprobe failed: {result.stderr}")
        import json
        return json.loads(result.stdout)
