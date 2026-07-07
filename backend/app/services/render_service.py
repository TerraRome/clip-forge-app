import subprocess
import structlog
from pathlib import Path

from typing import Optional

from app.config import settings
from app.services.transcript_service import TranscriptSegment
from app.services.highlight_service import HighlightSegment
from app.services import subtitle_service

logger = structlog.get_logger()

OUTPUT_WIDTH = 1080
OUTPUT_HEIGHT = 1920


class RenderService:
    def render_clip(
        self,
        video_path: str,
        segments: list[TranscriptSegment],
        highlight: HighlightSegment,
        output_path: str,
        video_width: int,
        video_height: int,
        crop_filter: Optional[str] = None,
        subtitle_preset: str = "classic",
    ) -> str:
        path = Path(output_path)
        path.parent.mkdir(parents=True, exist_ok=True)

        ass_content = subtitle_service.build_ass(
            segments, highlight, preset=subtitle_preset, video_path=video_path
        )

        ass_file = path.with_suffix(".ass")
        ass_file.write_text(ass_content, encoding="utf-8")

        if crop_filter is None:
            from app.services.smart_crop_service import SmartCropService
            crop_filter = SmartCropService().compute_filter(None, video_width, video_height)

        ass_filter = f"ass={ass_file.as_posix()}"
        cmd = [
            settings.ffmpeg_path, "-y",
            "-hwaccel", "videotoolbox",
            "-ss", str(highlight.start),
            "-i", video_path,
            "-t", str(highlight.end - highlight.start),
            "-vf", f"{crop_filter},{ass_filter}",
            "-c:v", "h264_videotoolbox",
            "-b:v", "5000k",
            "-c:a", "aac",
            "-b:a", "128k",
            "-movflags", "+faststart",
            "-pix_fmt", "yuv420p",
            str(path),
        ]

        logger.info("rendering_clip", output=output_path, crop_filter=crop_filter, subtitle_preset=subtitle_preset)
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=600, stdin=subprocess.DEVNULL)
        if result.returncode != 0:
            logger.error("render_failed", stderr=result.stderr)
            raise RuntimeError(f"FFmpeg render failed: {result.stderr}")

        logger.info("render_complete", output=output_path)
        return output_path
