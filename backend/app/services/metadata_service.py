import json
from datetime import datetime, timezone
from pathlib import Path

from app.services.transcript_service import TranscriptSegment


def generate_metadata(
    youtube_url: str,
    title: str,
    start_time: float,
    end_time: float,
    duration: float,
    clip_path: str,
    segments: list[TranscriptSegment],
) -> dict:
    clip = Path(clip_path)
    return {
        "title": title,
        "youtube_url": youtube_url,
        "start_time": start_time,
        "end_time": end_time,
        "duration": duration,
        "clip_filename": clip.name,
        "filesize_bytes": clip.stat().st_size if clip.exists() else 0,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "transcript_segments": len(segments),
        "audio": {
            "sample_rate": 16000,
            "channels": 1,
        },
    }


def save_metadata(metadata: dict, path: str) -> None:
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    Path(path).write_text(json.dumps(metadata, indent=2), encoding="utf-8")
