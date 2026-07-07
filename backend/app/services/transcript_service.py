import structlog
import whisper

logger = structlog.get_logger()


class TranscriptSegment:
    def __init__(self, start: float, end: float, text: str):
        self.start = start
        self.end = end
        self.text = text


class TranscriptService:
    def __init__(self, model_name: str = "base"):
        logger.info("loading_whisper_model", model=model_name)
        self._model = whisper.load_model(model_name)

    def transcribe(self, audio_path: str) -> list[TranscriptSegment]:
        logger.info("transcribing", audio=audio_path)
        result = self._model.transcribe(audio_path, language="id")
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