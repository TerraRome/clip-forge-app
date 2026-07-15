from pydantic import BaseModel, Field, field_validator
import re


class ClipRequest(BaseModel):
    youtube_url: str = Field(..., description="YouTube video URL")
    start_time: float = Field(..., ge=0, description="Start time in seconds")
    end_time: float = Field(..., ge=0, description="End time in seconds")

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

    @field_validator("end_time")
    @classmethod
    def validate_end_time(cls, v: float, info) -> float:
        start = info.data.get("start_time")
        if start is not None and v <= start:
            raise ValueError("end_time must be greater than start_time")
        if v - (start or 0) > 600:
            raise ValueError("Maximum clip duration is 600 seconds (10 minutes)")
        return v


class ClipResponse(BaseModel):
    title: str
    clip_path: str
    subtitle_path: str
    vtt_path: str
    transcript_path: str
    transcript_txt_path: str
    metadata_path: str
    duration: float


class ErrorResponse(BaseModel):
    detail: str
