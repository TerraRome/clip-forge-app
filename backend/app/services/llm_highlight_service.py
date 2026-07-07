import json
import structlog
from openai import OpenAI

from app.config import settings
from app.services.transcript_service import TranscriptSegment
from app.services.highlight_service import HighlightSegment, HighlightService as EnergyHighlightService

logger = structlog.get_logger()

SYSTEM_PROMPT = """You are a video highlight detector. Given a podcast transcript with timestamps [MM:SS], find the most engaging 20-60 second moments.

Rules:
- Each clip MUST be 20-60 seconds long (e.g. start=120, end=180 = 60s clip).
- Prioritise: emotional peaks, surprising revelations, strong opinions, punchlines, hooks.
- Return a JSON array: [{"start": float, "end": float, "reason": string}]
- start/end are in seconds from video beginning (e.g. 2min = 120.0).
- Clips MUST NOT overlap.
- Sort by start time ascending.
- Return ONLY the JSON array, no markdown, no explanation."""


class LLMHighlightService:
    def __init__(self):
        self._client = OpenAI(
            api_key=settings.llm_api_key,
            base_url=settings.llm_api_base,
        )
        self._fallback = EnergyHighlightService()

    def detect(
        self, segments: list[TranscriptSegment], total_duration: float, num_clips: int
    ) -> list[HighlightSegment]:
        transcript_text = self._format_transcript(segments)
        logger.info("llm_highlight_detecting", input_chars=len(transcript_text))

        try:
            resp = self._client.chat.completions.create(
                model=settings.llm_model,
                messages=[
                    {"role": "system", "content": SYSTEM_PROMPT},
                    {
                        "role": "user",
                        "content": f"Find {num_clips} highlights in this transcript:\n\n{transcript_text}",
                    },
                ],
                temperature=0.3,
                max_tokens=1024,
                timeout=60,
            )
            raw = resp.choices[0].message.content
            if raw is None:
                raise ValueError("Empty response from LLM")

            raw = raw.strip()
            logger.info("llm_raw_response", preview=raw[:500])

            if not raw:
                raise ValueError("Empty response from LLM")

            # Strip markdown fences if present
            if raw.startswith("```"):
                raw = raw.split("\n", 1)[-1]
                raw = raw.rsplit("```", 1)[0].strip()
            clips = json.loads(raw)
            results = []
            for c in clips:
                s, e = float(c["start"]), float(c["end"])
                dur = e - s
                if dur < 10 or dur > 120 or e > total_duration:
                    continue
                # Clamp to max 60s
                if dur > 60:
                    e = s + 60
                results.append(HighlightSegment(start=s, end=e, score=1.0))

            if not results:
                raise ValueError("LLM returned empty clips after filtering")

            # Deduplicate overlap — keep higher priority (first = best from LLM)
            deduped = []
            for r in results:
                if not any(r.start < rr.end and r.end > rr.start for rr in deduped):
                    deduped.append(r)
            deduped.sort(key=lambda x: x.start)

            logger.info("llm_highlight_detected", count=len(deduped), reasons=[c.get("reason", "") for c in clips])
            return deduped[:num_clips]

        except Exception as e:
            logger.warning("llm_highlight_failed_falling_back", error=str(e))
            return self._fallback.detect(segments, total_duration, num_clips)

    def _format_transcript(self, segments: list[TranscriptSegment]) -> str:
        lines = []
        for seg in segments:
            start_m = int(seg.start // 60)
            start_s = int(seg.start % 60)
            lines.append(f"[{start_m:02d}:{start_s:02d}] {seg.text}")
        return "\n".join(lines)
