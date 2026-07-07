import os
import structlog
from pathlib import Path
from typing import Optional

from app.celery_app import celery_app
from app.config import settings
from app.state import storage
from app.worker import BaseWorker
from app.services.video_service import VideoService

logger = structlog.get_logger()


class _VideoWorker(BaseWorker):
    max_retries = 2
    default_retry_delay = 15

    def execute(self, project_id: str) -> dict:
        log = logger.bind(project_id=project_id)
        project = storage.get(project_id)
        if project is None:
            raise RuntimeError("Project not found")
        project_dir = Path(settings.downloads_dir) / project_id
        project_dir.mkdir(parents=True, exist_ok=True)
        video_path = str(project_dir / "source.mp4")
        video_svc = VideoService()
        _exclusive_download(project_id, project.youtube_url, video_path, log)
        log.info("step_video_info")
        info = video_svc.get_info(video_path)
        video_stream = _find_video_stream(info)
        if video_stream is None:
            raise RuntimeError("No video stream found")

        result = {
            "video_path": video_path,
            "video_width": video_stream.get("width", 1920),
            "video_height": video_stream.get("height", 1080),
            "total_duration": float(info.get("format", {}).get("duration", 0)),
        }

        current = storage.get(project_id)
        bs = current.branch_status if current else "pending"
        # Only advance if not already past video_done
        if bs in ("pending", "running"):
            storage.update(project_id, branch_status="video_done")
        _set_flag(project_id, "video_done")
        _store_result(project_id, "video_result", result)

        return result


def _set_flag(project_id: str, name: str) -> None:
    (Path(settings.downloads_dir) / project_id / f"_{name}").touch()


def _exclusive_download(project_id: str, url: str, video_path: str, log) -> None:
    """Download only if file missing. Use lockfile to prevent concurrent yt-dlp."""
    if Path(video_path).exists():
        log.info("step_video_exists_skipping_download")
        return
    lock = Path(settings.downloads_dir) / project_id / "_downloading"
    # Try to acquire the download lock (O_EXCL = fail if exists)
    try:
        fd = os.open(str(lock), os.O_CREAT | os.O_EXCL | os.O_RDWR, 0o644)
        os.close(fd)
    except FileExistsError:
        log.info("step_download_in_progress_by_other_worker_waiting")
        # Other worker is downloading; wait for it to finish
        import time
        waited = 0
        while not Path(video_path).exists() and waited < 120:
            time.sleep(2)
            waited += 2
        if not Path(video_path).exists():
            raise RuntimeError("Download timed out waiting for other worker")
        return

    try:
        log.info("step_download")
        VideoService().download(url, video_path)
    finally:
        if lock.exists():
            lock.unlink()


def _store_result(project_id: str, key: str, value: dict) -> None:
    import json
    from pathlib import Path
    path = Path(settings.downloads_dir) / project_id / f"_{key}.json"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2))


def _find_video_stream(info: dict) -> Optional[dict]:
    for stream in info.get("streams", []):
        if stream.get("codec_type") == "video":
            return stream
    return None


@celery_app.task(bind=True, max_retries=2, default_retry_delay=15, name="worker.video")
def video_worker_task(self, project_id: str):
    return _VideoWorker().run(project_id)
