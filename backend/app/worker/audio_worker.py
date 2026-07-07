import os
import structlog
from pathlib import Path

from app.celery_app import celery_app
from app.config import settings
from app.state import storage
from app.worker import BaseWorker
from app.services.video_service import VideoService
from app.services.transcript_service import TranscriptService

logger = structlog.get_logger()


class _AudioWorker(BaseWorker):
    max_retries = 2
    default_retry_delay = 15

    def execute(self, project_id: str) -> dict:
        log = logger.bind(project_id=project_id)
        project = storage.get(project_id)
        if project is None:
            raise RuntimeError("Project not found")
        storage.update(project_id, progress=5.0)
        project_dir = Path(settings.downloads_dir) / project_id
        project_dir.mkdir(parents=True, exist_ok=True)
        video_path = str(project_dir / "source.mp4")
        audio_path = str(project_dir / "audio.wav")
        video_svc = VideoService()
        _exclusive_download(project_id, project.youtube_url, video_path, log)
        log.info("step_extract_audio")
        video_svc.extract_audio(video_path, audio_path)
        storage.update(project_id, progress=30.0)
        log.info("step_transcribe")
        transcript_svc = TranscriptService(model_name=settings.whisper_model)
        segments = transcript_svc.transcribe(audio_path)
        storage.update(project_id, progress=50.0)
        serialized = [{"start": s.start, "end": s.end, "text": s.text} for s in segments]

        # Store result in project for downstream workers
        storage.update(project_id, branch_status="audio_done")
        _store_result(project_id, "audio_result", {"video_path": video_path, "segments": serialized})

        _set_flag(project_id, "audio_done")
        return {"video_path": video_path, "segments": serialized}


def _set_flag(project_id: str, name: str) -> None:
    (Path(settings.downloads_dir) / project_id / f"_{name}").touch()


def _exclusive_download(project_id: str, url: str, video_path: str, log) -> None:
    """Download only if file missing, with lockfile to prevent concurrent yt-dlp."""
    if Path(video_path).exists():
        log.info("step_video_exists_skipping_download")
        return
    lock = Path(settings.downloads_dir) / project_id / "_downloading"
    try:
        fd = os.open(str(lock), os.O_CREAT | os.O_EXCL | os.O_RDWR, 0o644)
        os.close(fd)
    except FileExistsError:
        log.info("step_download_in_progress_by_other_worker_waiting")
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
        storage.update(project_id, progress=20.0)
    finally:
        if lock.exists():
            lock.unlink()


def _store_result(project_id: str, key: str, value: dict) -> None:
    """Persist worker result to project JSON."""
    import json
    from app.config import settings
    from pathlib import Path
    path = Path(settings.downloads_dir) / project_id / f"_{key}.json"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2))


@celery_app.task(bind=True, max_retries=2, default_retry_delay=15, name="worker.audio")
def audio_worker_task(self, project_id: str):
    return _AudioWorker().run(project_id)
