import os
import zipfile
import io
import threading
from pathlib import Path

from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse

from app.api.schemas import CreateProjectRequest, ProjectResponse, ErrorResponse
from app.models.project import Project, ProjectStatus
from app.state import storage
from app.worker.pipeline import run_pipeline

router = APIRouter()


@router.post("/projects", response_model=ProjectResponse, status_code=201)
async def create_project(body: CreateProjectRequest):
    project = Project.create(
        youtube_url=body.youtube_url,
        num_clips=body.num_clips,
    )
    storage.save(project)
    return _to_response(project)


@router.post(
    "/projects/{project_id}/process",
    response_model=ProjectResponse,
    responses={404: {"model": ErrorResponse}, 409: {"model": ErrorResponse}},
)
async def process_project(project_id: str):
    project = storage.get(project_id)
    if project is None:
        raise HTTPException(status_code=404, detail="Project not found")
    if project.status != ProjectStatus.PENDING:
        raise HTTPException(
            status_code=409,
            detail=f"Project is already {project.status.value}",
        )

    project.status = ProjectStatus.PROCESSING
    storage.save(project)

    thread = threading.Thread(target=run_pipeline, args=(project_id,), daemon=True)
    thread.start()

    return _to_response(project)


@router.get(
    "/projects/{project_id}",
    response_model=ProjectResponse,
    responses={404: {"model": ErrorResponse}},
)
async def get_project(project_id: str):
    project = storage.get(project_id)
    if project is None:
        raise HTTPException(status_code=404, detail="Project not found")
    return _to_response(project)


@router.get(
    "/download/{project_id}",
    responses={404: {"model": ErrorResponse}, 400: {"model": ErrorResponse}},
)
async def download_clips(project_id: str):
    project = storage.get(project_id)
    if project is None:
        raise HTTPException(status_code=404, detail="Project not found")
    if project.status != ProjectStatus.DONE:
        raise HTTPException(
            status_code=400,
            detail="Clips not ready yet",
        )

    zip_buffer = io.BytesIO()
    with zipfile.ZipFile(zip_buffer, "w", zipfile.ZIP_DEFLATED) as zf:
        for clip_path in project.clip_paths:
            path = Path(clip_path)
            if path.exists():
                zf.write(path, arcname=path.name)

    zip_buffer.seek(0)
    return StreamingResponse(
        zip_buffer,
        media_type="application/zip",
        headers={
            "Content-Disposition": f'attachment; filename="{project_id}.zip"',
            "Content-Length": str(zip_buffer.getbuffer().nbytes),
        },
    )


def _to_response(project: Project) -> ProjectResponse:
    return ProjectResponse(
        id=project.id,
        youtube_url=project.youtube_url,
        num_clips=project.num_clips,
        status=project.status.value,
        error_message=project.error_message,
        progress=project.progress,
    )