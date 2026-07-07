"""Subtitle preset generators — output ASS format strings."""

import structlog
import json
from pathlib import Path
from typing import Optional

from app.config import settings
from app.services.transcript_service import TranscriptSegment
from app.services.highlight_service import HighlightSegment

logger = structlog.get_logger()


def build_ass(
    segments: list[TranscriptSegment],
    highlight: HighlightSegment,
    preset: str = "classic",
    video_path: Optional[str] = None,
) -> str:
    if preset == "tiktok_3words":
        return _build_tiktok_3words(segments, highlight)
    elif preset == "word_pop":
        return _build_word_pop(segments, highlight, video_path)
    elif preset == "karaoke":
        return _build_karaoke(segments, highlight, video_path)
    else:
        return _build_classic(segments, highlight)


# ── Classic (existing style, refactored) ──

def _ass_header(style_block: str) -> str:
    return (
        "[V4+ Styles]\n"
        "Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, "
        "Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, "
        "Shadow, Alignment, MarginL, MarginR, MarginV, Encoding\n"
        f"{style_block}\n"
    )


def _ass_events() -> str:
    return "[Events]\nFormat: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text"


def _to_ass_time(seconds: float) -> str:
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = int(seconds % 60)
    cs = int((seconds - int(seconds)) * 100)
    return f"{h:01d}:{m:02d}:{s:02d}.{cs:02d}"


def _esc(text: str) -> str:
    return text.replace("{", "\\{").replace("}", "\\}").replace(",", "\\,")


def _clip_segments(segments: list[TranscriptSegment], highlight: HighlightSegment) -> list[TranscriptSegment]:
    clipped = []
    for seg in segments:
        if seg.start >= highlight.end or seg.end <= highlight.start:
            continue
        clipped.append(seg)
    return clipped


# ── Preset 1: Classic ──

def _build_classic(segments: list[TranscriptSegment], highlight: HighlightSegment) -> str:
    style = 'Style: Default,Arial,58,&H00FFFFFF,&H000000FF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,2,1,2,10,10,50,1'
    ass = _ass_header(style)
    ass += "\n" + _ass_events() + "\n"
    for seg in _clip_segments(segments, highlight):
        start_ts = _to_ass_time(max(seg.start - highlight.start, 0))
        end_ts = _to_ass_time(min(seg.end - highlight.start, highlight.end - highlight.start))
        ass += f"Dialogue: 0,{start_ts},{end_ts},Default,,0,0,0,,{_esc(seg.text)}\n"
    return ass


# ── Preset 2: TikTok 3 Kata ──

def _build_tiktok_3words(segments: list[TranscriptSegment], highlight: HighlightSegment) -> str:
    style = 'Style: Default,Arial Bold,64,&H00FFFFFF,&H000000FF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,2,1,2,10,10,80,1'
    ass = _ass_header(style)
    ass += "\n" + _ass_events() + "\n"

    clipped = _clip_segments(segments, highlight)
    for seg in clipped:
        words = seg.text.split()
        if not words:
            continue
        chunk_size = 3
        dur = min(seg.end, highlight.end) - max(seg.start, highlight.start)
        chunk_dur = dur / max(len(words) / chunk_size, 1)
        chunk_dur = min(chunk_dur, 2.0)  # cap per chunk
        base_start = max(seg.start, highlight.start)

        for i in range(0, len(words), chunk_size):
            chunk = words[i:i + chunk_size]
            line = " ".join(chunk)
            s = base_start + (i / len(words)) * dur
            e = min(s + chunk_dur, highlight.end)
            start_ts = _to_ass_time(max(s - highlight.start, 0))
            end_ts = _to_ass_time(e - highlight.start)
            ass += f"Dialogue: 0,{start_ts},{end_ts},Default,,0,0,0,,{_esc(line)}\n"

    return ass


# ── Helper: get word-level timestamps via Whisper ──

def _get_word_timestamps(video_path: str, highlight: HighlightSegment) -> list[dict]:
    """Re-transcribe just the clip with word timestamps."""
    import whisper
    import subprocess
    import tempfile

    model = whisper.load_model(settings.whisper_model)
    # Extract short audio segment for the clip
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        audio_path = tmp.name

    cmd = [
        settings.ffmpeg_path, "-y",
        "-ss", str(highlight.start),
        "-t", str(highlight.end - highlight.start),
        "-i", video_path,
        "-vn", "-ac", "1", "-ar", "16000",
        audio_path,
    ]
    subprocess.run(cmd, capture_output=True, check=True)

    result = model.transcribe(audio_path, language="id", word_timestamps=True, fp16=False)
    Path(audio_path).unlink(missing_ok=True)
    return result


# ── Preset 3: Word Pop (tiap kata muncul bertahap, highlight kuning) ──

def _build_word_pop(
    segments: list[TranscriptSegment],
    highlight: HighlightSegment,
    video_path: Optional[str] = None,
) -> str:
    style = (
        'Style: Default,Arial Bold,60,&H00FFFFFF,&H00FFFF00,&H00000000,&H80000000,'
        '-1,0,0,0,100,100,0,0,1,2,1,2,10,10,80,1\n'
    )
    ass = _ass_header(style)
    ass += "\n" + _ass_events() + "\n"

    if video_path:
        try:
            result = _get_word_timestamps(video_path, highlight)
            clip_start = highlight.start
            for seg in result.get("segments", []):
                words = seg.get("words", [])
                # Show all words in the line initially dimmed, highlight one at a time
                line_words = [w for w in words if w.get("word", "").strip()]
                if not line_words:
                    continue
                # Visible for the whole segment
                seg_start = max(seg["start"], 0)
                seg_end = min(seg["end"], highlight.end - highlight.start)
                whole_line = " ".join(w["word"].strip() for w in line_words)
                # ASS karaoke: show dimmed white, use \\K for highlighting
                # \\K{highlight_seconds}text — text before \\K is visible, after is highlight-colored
                k_line = ""
                running = 0.0
                for w in line_words:
                    w_start_rel = w["start"]
                    w_end_rel = w["end"]
                    w_dur = w_end_rel - w_start_rel
                    # delay from segment start
                    k_delay = max(w_start_rel - seg_start, 0)
                    k_dur = min(w_dur, seg_end - seg_start)
                    # how many seconds into the seg this word starts
                    k_start = int(k_delay * 100)  # centiseconds
                    k_line += "{\\K" + str(k_start) + "}" + _esc(w["word"].strip()) + " "
                start_ts = _to_ass_time(seg_start)
                end_ts = _to_ass_time(seg_end)
                ass += f"Dialogue: 0,{start_ts},{end_ts},Default,,0,0,0,,{k_line}\n"
            return ass
        except Exception as e:
            logger.warning("word_pop_failed_falling_back_to_classic", error=str(e))

    return _build_classic(segments, highlight)


# ── Preset 4: Classic Karaoke (all words visible, active word cyan highlight) ──

def _build_karaoke(
    segments: list[TranscriptSegment],
    highlight: HighlightSegment,
    video_path: Optional[str] = None,
) -> str:
    style = (
        'Style: Default,Arial Bold,56,&H00FFFFFF,&H0000FFFF,&H00000000,&H80000000,'
        '-1,0,0,0,100,100,0,0,1,2,1,2,10,10,80,1\n'
    )
    ass = _ass_header(style)
    ass += "\n" + _ass_events() + "\n"

    if video_path:
        try:
            result = _get_word_timestamps(video_path, highlight)
            clip_start = highlight.start
            for seg in result.get("segments", []):
                words = seg.get("words", [])
                line_words = [w for w in words if w.get("word", "").strip()]
                if not line_words:
                    continue
                seg_start = max(seg["start"], 0)
                seg_end = min(seg["end"], highlight.end - highlight.start)
                # Karaoke: use \\K so all words visible, active word in SecondaryColour
                k_line = ""
                for w in line_words:
                    w_dur = max(w["end"] - w["start"], 0.05)
                    k_dur_cs = int(w_dur * 100)  # centiseconds
                    k_line += "{\\K" + str(k_dur_cs) + "}" + _esc(w["word"].strip()) + " "
                start_ts = _to_ass_time(seg_start)
                end_ts = _to_ass_time(seg_end)
                ass += f"Dialogue: 0,{start_ts},{end_ts},Default,,0,0,0,,{k_line}\n"
            return ass
        except Exception as e:
            logger.warning("karaoke_failed_falling_back_to_classic", error=str(e))

    return _build_classic(segments, highlight)
