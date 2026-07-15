from pathlib import Path

from app.services.transcript_service import TranscriptSegment


def _to_srt_time(seconds: float) -> str:
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = int(seconds % 60)
    ms = int((seconds - int(seconds)) * 1000)
    return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"


def _to_vtt_time(seconds: float) -> str:
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = int(seconds % 60)
    ms = int((seconds - int(seconds)) * 1000)
    return f"{h:02d}:{m:02d}:{s:02d}.{ms:03d}"


def segments_to_srt(segments: list[TranscriptSegment]) -> str:
    lines = []
    for i, seg in enumerate(segments, 1):
        start = _to_srt_time(seg.start)
        end = _to_srt_time(seg.end)
        lines.append(f"{i}")
        lines.append(f"{start} --> {end}")
        lines.append(seg.text)
        lines.append("")
    return "\n".join(lines)


def segments_to_vtt(segments: list[TranscriptSegment]) -> str:
    lines = ["WEBVTT", ""]
    for seg in segments:
        start = _to_vtt_time(seg.start)
        end = _to_vtt_time(seg.end)
        lines.append(f"{start} --> {end}")
        lines.append(seg.text)
        lines.append("")
    return "\n".join(lines)


def save_subtitles(segments: list[TranscriptSegment], srt_path: str, vtt_path: str) -> None:
    Path(srt_path).parent.mkdir(parents=True, exist_ok=True)
    Path(srt_path).write_text(segments_to_srt(segments), encoding="utf-8")
    Path(vtt_path).write_text(segments_to_vtt(segments), encoding="utf-8")
