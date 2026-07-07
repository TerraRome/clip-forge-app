from __future__ import annotations

import structlog
from pathlib import Path

from app.config import settings
from app.state import storage
from app.models.project import ProjectStatus
from app.services.video_service import VideoService
from app.services.transcript_service import TranscriptService
from app.services.highlight_service import HighlightService
from app.services.llm_highlight_service import LLMHighlightService
from app.services.render_service import RenderService
from app.services.face_service import FaceService
from app.services.smart_crop_service import SmartCropService

logger = structlog.get_logger()


def run_pipeline(project_id: str) -> None:
    log = logger.bind(project_id=project_id)
    log.info("pipeline_started")

    video_svc = VideoService()
    transcript_svc = TranscriptService(model_name=settings.whisper_model)
    highlight_svc = LLMHighlightService()
    face_svc = FaceService()
    crop_svc = SmartCropService()
    render_svc = RenderService()

    try:
        project = storage.get(project_id)
        if project is None:
            log.error("project_not_found")
            return

        downloads_dir = Path(settings.downloads_dir)
        downloads_dir.mkdir(parents=True, exist_ok=True)
        project_dir = downloads_dir / project_id
        project_dir.mkdir(parents=True, exist_ok=True)
        clips_dir = project_dir / "clips"
        clips_dir.mkdir(parents=True, exist_ok=True)

        # 1. Download video
        log.info("step_download")
        storage.update(project_id, progress=5.0)
        video_path = str(project_dir / "source.mp4")
        video_svc.download(project.youtube_url, video_path)
        storage.update(project_id, progress=20.0)

        # 2. Extract audio
        log.info("step_extract_audio")
        audio_path = str(project_dir / "audio.wav")
        video_svc.extract_audio(video_path, audio_path)
        storage.update(project_id, progress=30.0)

        # 3. Transcribe
        log.info("step_transcribe")
        segments = transcript_svc.transcribe(audio_path)
        storage.update(project_id, progress=50.0)

        # 4. Get video info for dimensions
        info = video_svc.get_info(video_path)
        video_stream = _find_video_stream(info)
        if video_stream is None:
            raise RuntimeError("No video stream found")
        video_width = video_stream.get("width", 1920)
        video_height = video_stream.get("height", 1080)
        total_duration = float(info.get("format", {}).get("duration", 0))

        # 5. Detect highlights
        log.info("step_highlights")
        highlights = highlight_svc.detect(segments, total_duration, project.num_clips)
        if not highlights:
            raise RuntimeError("No highlights detected")
        storage.update(project_id, progress=65.0)

        # 6. Render clips
        log.info("step_render", clip_count=len(highlights))
        clip_paths = []

        for i, hl in enumerate(highlights):
            output_path = str(clips_dir / f"clip_{i + 1:02d}.mp4")

            # Face detection + smart crop
            log.info("step_face_detect", clip=i + 1)
            face = face_svc.detect_dominant_face(
                video_path=video_path,
                highlight_start=hl.start,
                highlight_end=hl.end,
                video_width=video_width,
                video_height=video_height,
            )
            crop_filter = crop_svc.compute_filter(face, video_width, video_height)
            log.info(
                "step_render",
                clip=i + 1,
                crop_filter=crop_filter,
                face_found=face is not None,
            )

            render_svc.render_clip(
                video_path=video_path,
                segments=segments,
                highlight=hl,
                output_path=output_path,
                video_width=video_width,
                video_height=video_height,
                crop_filter=crop_filter,
                subtitle_preset=project.subtitle_preset,
            )
            clip_paths.append(output_path)
            progress = 65.0 + (35.0 * (i + 1) / len(highlights))
            storage.update(project_id, progress=round(progress, 1))

        # 7. Done
        storage.update(
            project_id,
            status=ProjectStatus.DONE,
            progress=100.0,
            clip_paths=clip_paths,
        )
        log.info("pipeline_complete", clips=len(clip_paths))

    except Exception as e:
        log.error("pipeline_failed", error=str(e))
        storage.update(
            project_id,
            status=ProjectStatus.ERROR,
            error_message=str(e),
        )


def _find_video_stream(info: dict) -> Optional[dict]:
    for stream in info.get("streams", []):
        if stream.get("codec_type") == "video":
            return stream
    return None