"""Entry-point Celery task: orchestrate worker-based DAG via link callbacks.

Sequence: audio+video (parallel) → LLM → render → export.
Each step guarded by flag-files for idempotency.
Error handling done inside each worker — DAG naturally halts if results missing.
"""

import structlog
from pathlib import Path

from app.celery_app import celery_app
from app.config import settings
from app.state import storage

logger = structlog.get_logger()


def _pd(project_id: str) -> Path:
    return Path(settings.downloads_dir) / project_id


def _flag(project_id: str, name: str) -> bool:
    return (_pd(project_id) / f"_{name}").exists()


def _set_flag(project_id: str, name: str) -> None:
    (_pd(project_id) / f"_{name}").touch()


@celery_app.task(bind=True, max_retries=1, default_retry_delay=30, name="pipeline.start")
def start_pipeline(self, project_id: str) -> dict:
    """Dispatch audio + video in parallel with link callback."""
    log = logger.bind(project_id=project_id)
    log.info("pipeline_started")
    storage.update(project_id, progress=2.0)

    from app.worker.audio_worker import audio_worker_task
    from app.worker.video_worker import video_worker_task

    audio_worker_task.apply_async(
        args=[project_id],
        link=advance_dag.s(project_id),
    )
    video_worker_task.apply_async(
        args=[project_id],
        link=advance_dag.s(project_id),
    )
    return {"project_id": project_id, "status": "started"}


@celery_app.task(ignore_result=True, name="pipeline.advance")
def advance_dag(parent_result, project_id: str) -> None:
    """Continuation: check flags, dispatch next node."""
    audio_ready = _flag(project_id, "audio_done")
    video_ready = _flag(project_id, "video_done")
    llm_dispatched = _flag(project_id, "llm_dispatched")
    render_dispatched = _flag(project_id, "render_dispatched")
    export_dispatched = _flag(project_id, "export_dispatched")

    # 1. Audio + Video → LLM
    if audio_ready and video_ready and not llm_dispatched:
        _set_flag(project_id, "llm_dispatched")
        from app.worker.llm_worker import llm_worker_task
        storage.update(project_id, branch_status="llm_done")
        logger.info("dispatching_llm", project_id=project_id)
        llm_worker_task.apply_async(
            args=[project_id],
            link=advance_dag.s(project_id),
        )
        return

    # 2. LLM done → Render
    llm_ready = _flag(project_id, "llm_done")
    if llm_ready and not render_dispatched:
        _set_flag(project_id, "render_dispatched")
        from app.worker.render_worker import render_worker_task
        storage.update(project_id, branch_status="rendering")
        logger.info("dispatching_render", project_id=project_id)
        render_worker_task.apply_async(
            args=[project_id],
            link=advance_dag.s(project_id),
        )
        return

    # 3. Render done → Export
    clips_present = len(list(_pd(project_id).glob("clips/clip_*.mp4"))) > 0
    if render_dispatched and clips_present and not export_dispatched:
        _set_flag(project_id, "export_dispatched")
        from app.worker.export_worker import export_worker_task
        logger.info("dispatching_export", project_id=project_id)
        export_worker_task.apply_async(
            args=[project_id],
            link=advance_dag.s(project_id),
        )
        return
