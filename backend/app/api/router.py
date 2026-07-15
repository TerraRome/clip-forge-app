import structlog
import os
from pathlib import Path

from fastapi import APIRouter, HTTPException

from app.api.schemas import ClipRequest, ClipResponse, ErrorResponse
from app.config import settings
from app.services.video_service import VideoService
from app.services.transcript_service import TranscriptService
from app.services.naming_service import resolve_output_paths
from app.services.subtitle_formatter import save_subtitles
from app.services.metadata_service import generate_metadata, save_metadata

logger = structlog.get_logger()
router = APIRouter()


@router.post(
    "/clip",
    response_model=ClipResponse,
    responses={400: {"model": ErrorResponse}, 500: {"model": ErrorResponse}},
)
async def create_clip(body: ClipRequest):
    duration = body.end_time - body.start_time
    log = logger.bind(url=body.youtube_url, start=body.start_time, end=body.end_time)

    try:
        paths = resolve_output_paths(settings.output_dir, body.youtube_url)
        log.info("resolved_paths", title=paths["title"])

        log.info("step_download_clip")
        VideoService().download_clip(body.youtube_url, paths["clip"], body.start_time, body.end_time)

        log.info("step_extract_audio")
        VideoService().extract_audio(paths["clip"], paths["wav"])

        log.info("step_transcribe")
        ts = TranscriptService(model_name=settings.whisper_model)
        segments = ts.transcribe(paths["wav"])

        log.info("step_save_transcript")
        ts.save_transcript(segments, paths["transcript_json"], paths["transcript_txt"])

        log.info("step_save_subtitles")
        save_subtitles(segments, paths["srt"], paths["vtt"])

        log.info("step_save_metadata")
        metadata = generate_metadata(
            youtube_url=body.youtube_url,
            title=paths["title"],
            start_time=body.start_time,
            end_time=body.end_time,
            duration=duration,
            clip_path=paths["clip"],
            segments=segments,
        )
        save_metadata(metadata, paths["metadata"])

        log.info("step_cleanup_wav")
        Path(paths["wav"]).unlink(missing_ok=True)

        log.info("clip_complete")
        return ClipResponse(
            title=paths["title"],
            clip_path=paths["clip"],
            subtitle_path=paths["srt"],
            vtt_path=paths["vtt"],
            transcript_path=paths["transcript_json"],
            transcript_txt_path=paths["transcript_txt"],
            metadata_path=paths["metadata"],
            duration=duration,
        )

    except Exception as e:
        log.error("clip_failed", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/health")
async def health():
    return {"status": "ok"}
