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
    status: ProjectStatus = ProjectStatus.PENDING
    error_message: str = ""
    progress: float = 0.0  # 0.0–100.0
    clip_paths: list[str] = field(default_factory=list)

    @staticmethod
    def create(youtube_url: str, num_clips: int) -> "Project":
        return Project(
            id=str(uuid.uuid4()),
            youtube_url=youtube_url,
            num_clips=num_clips,
        )

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "youtube_url": self.youtube_url,
            "num_clips": self.num_clips,
            "status": self.status.value,
            "error_message": self.error_message,
            "progress": self.progress,
            "clip_paths": self.clip_paths,
        }

    @staticmethod
    def from_dict(data: dict) -> "Project":
        return Project(
            id=data["id"],
            youtube_url=data["youtube_url"],
            num_clips=data["num_clips"],
            status=ProjectStatus(data["status"]),
            error_message=data.get("error_message", ""),
            progress=data.get("progress", 0.0),
            clip_paths=data.get("clip_paths", []),
        )