import uuid
from dataclasses import dataclass, field
from enum import Enum


class ProjectStatus(str, Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    DONE = "done"
    ERROR = "error"


@dataclass
class Project:
    id: str
    youtube_url: str
    num_clips: int
    subtitle_preset: str = "classic"
    status: ProjectStatus = ProjectStatus.PENDING
    error_message: str = ""
    progress: float = 0.0  # 0.0–100.0
    clip_paths: list[str] = field(default_factory=list)
    task_id: str = ""  # Celery pipeline task ID
    branch_status: str = "pending"  # pending/running/audio_done/video_done/llm_done/rendering/done/failed

    @staticmethod
    def create(youtube_url: str, num_clips: int, subtitle_preset: str = "classic") -> "Project":
        return Project(
            id=str(uuid.uuid4()),
            youtube_url=youtube_url,
            num_clips=num_clips,
            subtitle_preset=subtitle_preset,
        )

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "youtube_url": self.youtube_url,
            "num_clips": self.num_clips,
            "subtitle_preset": self.subtitle_preset,
            "status": self.status.value,
            "error_message": self.error_message,
            "progress": self.progress,
            "clip_paths": self.clip_paths,
            "task_id": self.task_id,
            "branch_status": self.branch_status,
        }

    @staticmethod
    def from_dict(data: dict) -> "Project":
        return Project(
            id=data["id"],
            youtube_url=data["youtube_url"],
            num_clips=data["num_clips"],
            subtitle_preset=data.get("subtitle_preset", "classic"),
            status=ProjectStatus(data["status"]),
            error_message=data.get("error_message", ""),
            progress=data.get("progress", 0.0),
            clip_paths=data.get("clip_paths", []),
            task_id=data.get("task_id", ""),
            branch_status=data.get("branch_status", "pending"),
        )
