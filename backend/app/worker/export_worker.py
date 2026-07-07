import structlog

from app.celery_app import celery_app
from app.state import storage
from app.models.project import ProjectStatus
from app.worker import BaseWorker

logger = structlog.get_logger()


class _ExportWorker(BaseWorker):
    max_retries = 1
    default_retry_delay = 5

    def execute(self, project_id: str) -> dict:
        log = logger.bind(project_id=project_id)
        project = storage.get(project_id)
        if project is None:
            raise RuntimeError("Project not found")

        # Collect clip paths
        from pathlib import Path
        from app.config import settings
        clips_dir = Path(settings.downloads_dir) / project_id / "clips"
        clip_paths = sorted(str(p) for p in clips_dir.iterdir() if p.suffix == ".mp4") if clips_dir.exists() else []

        log.info("export_complete", clips=len(clip_paths))
        storage.update(
            project_id,
            status=ProjectStatus.DONE,
            progress=100.0,
            clip_paths=clip_paths,
            branch_status="done",
        )
        return {"clip_paths": clip_paths}


@celery_app.task(bind=True, max_retries=1, default_retry_delay=5, name="worker.export")
def export_worker_task(self, project_id: str):
    return _ExportWorker().run(project_id)
