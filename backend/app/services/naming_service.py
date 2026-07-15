import re
import subprocess
from pathlib import Path

from app.config import settings


def get_youtube_title(url: str) -> str:
    cmd = [
        "python3", "-m", "yt_dlp",
        "--print", "title",
        "--no-warnings",
        "--extractor-args", "youtube:player_client=android",
        url,
    ]
    if settings.yt_dlp_cookies_file:
        cmd.extend(["--cookies", settings.yt_dlp_cookies_file])

    result = subprocess.run(cmd, capture_output=True, text=True, timeout=30, stdin=subprocess.DEVNULL)
    if result.returncode != 0:
        stderr_lines = [l for l in result.stderr.splitlines()
                       if "NotOpenSSLWarning" not in l
                       and "Deprecated Feature" not in l
                       and "urllib3" not in l
                       and "warnings.warn" not in l]
        err_text = "\n".join(stderr_lines).strip()
        if err_text:
            raise RuntimeError(f"Failed to get video title: {err_text}")
    return result.stdout.strip()


def sanitize_filename(title: str) -> str:
    cleaned = re.sub(r'[<>:"/\\|?*]', "", title)
    cleaned = re.sub(r"\s+", " ", cleaned).strip()
    if len(cleaned) > 120:
        cleaned = cleaned[:120].rstrip()
    return cleaned


def next_available_path(output_dir: str, base_name: str, ext: str) -> str:
    base_dir = Path(output_dir)
    base_dir.mkdir(parents=True, exist_ok=True)
    counter = 0
    while True:
        suffix = f" {counter}" if counter > 0 else ""
        path = base_dir / f"{base_name}{suffix}{ext}"
        if not path.exists():
            return str(path)
        counter += 1


def resolve_output_paths(output_dir: str, youtube_url: str) -> dict[str, str]:
    title = get_youtube_title(youtube_url)
    base_name = sanitize_filename(title)
    clip_path = next_available_path(output_dir, base_name, ".mp4")

    stem = Path(clip_path).stem
    base_dir = Path(output_dir)

    return {
        "title": title,
        "clip": clip_path,
        "wav": str(base_dir / f"{stem}.wav"),
        "srt": str(base_dir / f"{stem}.srt"),
        "vtt": str(base_dir / f"{stem}.vtt"),
        "transcript_json": str(base_dir / f"{stem}.json"),
        "transcript_txt": str(base_dir / f"{stem}.txt"),
        "metadata": str(base_dir / f"{stem}.metadata.json"),
    }
