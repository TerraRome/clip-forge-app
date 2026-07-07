import structlog

from app.celery_app import celery_app
from app.config import settings
from app.state import storage
from app.worker import BaseWorker
from app.services.llm_highlight_service import LLMHighlightService
from app.services.transcript_service import TranscriptService

logger = structlog.get_logger()


class _LLMWorker(BaseWorker):
    max_retries = 2
    default_retry_delay = 10

    def execute(self, project_id: str) -> dict:
        project = storage.get(project_id)
        if project is None:
            raise RuntimeError("Project not found")

        audio_path = f"{settings.downloads_dir}/{project_id}/audio.wav"
        ts = TranscriptService(model_name=settings.whisper_model)
        segments = ts.transcribe(audio_path)
        total_duration = segments[-1].end if segments else 0
        service = LLMHighlightService()
        highlights = service.detect(segments, total_duration, project.num_clips)
        if not highlights:
            raise RuntimeError("No highlights detected")

        storage.update(project_id, progress=65.0, branch_status="llm_done")

        serialized = [{"start": h.start, "end": h.end, "score": h.score} for h in highlights]

        # Store highlights for render workers
        _store_result(project_id, "highlights", {"highlights": serialized})
        _set_flag(project_id, "llm_done")

        return {"highlights": serialized}


def _set_flag(project_id: str, name: str) -> None:
    from pathlib import Path
    (Path(settings.downloads_dir) / project_id / f"_{name}").touch()


def _store_result(project_id: str, key: str, value: dict) -> None:
    import json
    from pathlib import Path
    path = Path(settings.downloads_dir) / project_id / f"_{key}.json"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2))


@celery_app.task(bind=True, max_retries=2, default_retry_delay=10, name="worker.llm")
def llm_worker_task(self, project_id: str):
    return _LLMWorker().run(project_id)
