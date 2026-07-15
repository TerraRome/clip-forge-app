import json
import structlog
import whisper
from pathlib import Path

logger = structlog.get_logger()


class TranscriptSegment:
    def __init__(self, start: float, end: float, text: str):
        self.start = start
        self.end = end
        self.text = text

    def to_dict(self) -> dict:
        return {"start": self.start, "end": self.end, "text": self.text}


class TranscriptService:
    def __init__(self, model_name: str = "base"):
        logger.info("loading_whisper_model", model=model_name)
        self._model = whisper.load_model(model_name)

    def transcribe(self, audio_path: str) -> list[TranscriptSegment]:
        logger.info("transcribing", audio=audio_path)
        result = self._model.transcribe(audio_path, language="en")
        segments = []
        for seg in result["segments"]:
            text = seg["text"].strip()
            if text:
                segments.append(
                    TranscriptSegment(
                        start=seg["start"],
                        end=seg["end"],
                        text=text,
                    )
                )
        logger.info("transcription_complete", segments=len(segments))
        return segments

    def save_transcript(self, segments: list[TranscriptSegment], json_path: str, txt_path: str) -> None:
        Path(json_path).parent.mkdir(parents=True, exist_ok=True)
        data = [s.to_dict() for s in segments]
        Path(json_path).write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")

        lines = [f"[{_fmt_time(s.start)} --> {_fmt_time(s.end)}] {s.text}" for s in segments]
        Path(txt_path).write_text("\n".join(lines), encoding="utf-8")


def _fmt_time(seconds: float) -> str:
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = int(seconds % 60)
    ms = int((seconds - int(seconds)) * 1000)
    return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"
