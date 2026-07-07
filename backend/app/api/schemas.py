from pydantic import BaseModel, Field, field_validator
import re


VALID_PRESETS = {"classic", "tiktok_3words", "word_pop", "karaoke"}


class CreateProjectRequest(BaseModel):
    youtube_url: str = Field(..., description="YouTube video URL")
    num_clips: int = Field(..., ge=1, le=10, description="Number of clips (1, 3, 5, 10)")
    subtitle_preset: str = Field("classic", description="Subtitle style: classic, tiktok_3words, word_pop, karaoke")

    @field_validator("num_clips")
    @classmethod
    def validate_num_clips(cls, v: int) -> int:
        if v not in {1, 3, 5, 10}:
            raise ValueError("num_clips must be 1, 3, 5, or 10")
        return v

    @field_validator("youtube_url")
    @classmethod
    def validate_url(cls, v: str) -> str:
        patterns = [
            r"(?:https?://)?(?:www\.)?youtube\.com/watch\?v=[\w-]{11}",
            r"(?:https?://)?(?:www\.)?youtu\.be/[\w-]{11}",
            r"(?:https?://)?(?:www\.)?youtube\.com/shorts/[\w-]{11}",
        ]
        if not any(re.match(p, v) for p in patterns):
            raise ValueError("Invalid YouTube URL")
        return v

    @field_validator("subtitle_preset")
    @classmethod
    def validate_preset(cls, v: str) -> str:
        if v not in VALID_PRESETS:
            raise ValueError(f"subtitle_preset must be one of: {', '.join(sorted(VALID_PRESETS))}")
        return v


class ProjectResponse(BaseModel):
    id: str
    youtube_url: str
    num_clips: int
    subtitle_preset: str = "classic"
    status: str
    error_message: str = ""
    progress: float = 0.0
    task_id: str = ""
    branch_status: str = "pending"


class ErrorResponse(BaseModel):
    detail: str
