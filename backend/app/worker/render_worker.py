import json
import structlog
from pathlib import Path

from app.celery_app import celery_app
from app.config import settings
from app.state import storage
from app.worker import BaseWorker
from app.services.render_service import RenderService
from app.services.face_service import FaceService
from app.services.smart_crop_service import SmartCropService
from app.services.transcript_service import TranscriptSegment
from app.services.highlight_service import HighlightSegment

logger = structlog.get_logger()


class _RenderWorker(BaseWorker):
    max_retries = 2
    default_retry_delay = 10

    def execute(self, project_id: str) -> dict:
        log = logger.bind(project_id=project_id)
        project = storage.get(project_id)
        if project is None:
            raise RuntimeError("Project not found")

        # Read pre-computed results from disk
        highlights = _read_result(project_id, "highlights", {}).get("highlights", [])
        if not highlights:
            raise RuntimeError("No highlights found for rendering")

        video_result = _read_result(project_id, "video_result", {})
        if not video_result:
            raise RuntimeError("Video result not found")

        audio_result = _read_result(project_id, "audio_result", {})
        segments_data = audio_result.get("segments", [])

        project_dir = Path(settings.downloads_dir) / project_id
        clips_dir = project_dir / "clips"
        clips_dir.mkdir(parents=True, exist_ok=True)

        video_path = video_result["video_path"]
        video_width = video_result["video_width"]
        video_height = video_result["video_height"]
        segs = [TranscriptSegment(s["start"], s["end"], s["text"]) for s in segments_data]

        face_svc = FaceService()
        crop_svc = SmartCropService()
        render_svc = RenderService()

        rendered = []
        for i, hl_data in enumerate(highlights):
            hl = HighlightSegment(hl_data["start"], hl_data["end"], hl_data.get("score", 1.0))
            log.info("step_face_detect", clip=i + 1)
            try:
                face = face_svc.detect_dominant_face(
                    video_path=video_path,
                    highlight_start=hl.start,
                    highlight_end=hl.end,
                    video_width=video_width,
                    video_height=video_height,
                )
            except Exception:
                log.warning("face_detect_skipped", clip=i + 1, exc_info=True)
                face = None
            crop_filter = crop_svc.compute_filter(face, video_width, video_height)
            output_path = str(clips_dir / f"clip_{i + 1:02d}.mp4")
            log.info("step_render", clip=i + 1, crop_filter=crop_filter, face_found=face is not None)
            render_svc.render_clip(
                video_path=video_path, segments=segs, highlight=hl,
                output_path=output_path, video_width=video_width,
                video_height=video_height, crop_filter=crop_filter,
                subtitle_preset=project.subtitle_preset,
            )
            rendered.append(output_path)
            progress = 65.0 + (35.0 * (i + 1) / len(highlights))
            storage.update(project_id, progress=round(progress, 1))

        return {"clip_paths": rendered}


def _read_result(project_id: str, key: str, default: dict) -> dict:
    path = Path(settings.downloads_dir) / project_id / f"_{key}.json"
    if not path.exists():
        return default
    return json.loads(path.read_text())


@celery_app.task(bind=True, max_retries=2, default_retry_delay=10, name="worker.render")
def render_worker_task(self, project_id: str):
    return _RenderWorker().run(project_id)
