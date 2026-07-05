import subprocess
import structlog
from pathlib import Path

from app.config import settings
from app.services.transcript_service import TranscriptSegment
from app.services.highlight_service import HighlightSegment

logger = structlog.get_logger()

OUTPUT_WIDTH = 1080
OUTPUT_HEIGHT = 1920


def _build_ass_style() -> str:
    """Return ASS subtitle style block for white text with black outline."""
    return (
        "[V4+ Styles]\n"
        "Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, "
        "Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, "
        "Shadow, Alignment, MarginL, MarginR, MarginV, Encoding\n"
        "Style: Default,Arial,28,&H00FFFFFF,&H000000FF,&H00000000,&H80000000,"
        "-1,0,0,0,100,100,0,0,1,2,1,2,10,10,10,1\n"
    )


def _segments_to_ass(segments: list[TranscriptSegment], highlight: HighlightSegment) -> str:
    """Generate ASS subtitle events for a given highlight window."""
    lines = ["[Events]", "Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text"]
    for seg in segments:
        if seg.start >= highlight.end or seg.end <= highlight.start:
            continue
        start_ts = _to_ass_time(max(seg.start - highlight.start, 0))
        end_ts = _to_ass_time(min(seg.end - highlight.start, highlight.end - highlight.start))
        escaped = seg.text.replace("{", "\\{").replace("}", "\\}").replace(",", "\\,")
        lines.append(f"Dialogue: 0,{start_ts},{end_ts},Default,,0,0,0,,{escaped}")
    return "\n".join(lines)


def _to_ass_time(seconds: float) -> str:
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = int(seconds % 60)
    cs = int((seconds - int(seconds)) * 100)
    return f"{h:01d}:{m:02d}:{s:02d}.{cs:02d}"


def _get_crop_filter(video_width: int, video_height: int) -> str:
    """Center-crop to 9:16 vertical aspect ratio."""
    target_ratio = OUTPUT_WIDTH / OUTPUT_HEIGHT  # 0.5625
    input_ratio = video_width / video_height

    if input_ratio > target_ratio:
        # Wider than target → crop width
        crop_w = int(video_height * target_ratio)
        crop_h = video_height
        x = (video_width - crop_w) // 2
        y = 0
    else:
        # Taller than target → crop height
        crop_w = video_width
        crop_h = int(video_width / target_ratio)
        x = 0
        y = (video_height - crop_h) // 2

    return f"crop={crop_w}:{crop_h}:{x}:{y}"


class RenderService:
    def render_clip(
        self,
        video_path: str,
        segments: list[TranscriptSegment],
        highlight: HighlightSegment,
        output_path: str,
        video_width: int,
        video_height: int,
    ) -> str:
        path = Path(output_path)
        path.parent.mkdir(parents=True, exist_ok=True)

        ass_content = _build_ass_style()
        ass_content += "\n" + _segments_to_ass(segments, highlight)

        ass_file = path.with_suffix(".ass")
        ass_file.write_text(ass_content, encoding="utf-8")

        crop_filter = _get_crop_filter(video_width, video_height)

        ass_filter = f"ass={ass_file.as_posix()}"
        cmd = [
            settings.ffmpeg_path, "-y",
            "-ss", str(highlight.start),
            "-i", video_path,
            "-t", str(highlight.end - highlight.start),
            "-vf", f"{crop_filter},{ass_filter}",
            "-c:v", "libx264",
            "-crf", "23",
            "-preset", "fast",
            "-c:a", "aac",
            "-b:a", "128k",
            "-movflags", "+faststart",
            "-pix_fmt", "yuv420p",
            str(path),
        ]

        logger.info("rendering_clip", output=output_path)
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=600, stdin=subprocess.DEVNULL)
        if result.returncode != 0:
            logger.error("render_failed", stderr=result.stderr)
            raise RuntimeError(f"FFmpeg render failed: {result.stderr}")

        logger.info("render_complete", output=output_path)
        return output_path