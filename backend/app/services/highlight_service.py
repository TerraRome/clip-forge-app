import structlog
from app.services.transcript_service import TranscriptSegment

logger = structlog.get_logger()

MIN_CLIP_DURATION = 20.0  # seconds
MAX_CLIP_DURATION = 60.0


class HighlightSegment:
    def __init__(self, start: float, end: float, score: float):
        self.start = start
        self.end = end
        self.score = score


class HighlightService:
    def detect(self, segments: list[TranscriptSegment], total_duration: float, num_clips: int) -> list[HighlightSegment]:
        """
        Sliding-window highlight detection.

        For each 1s step along the timeline, computes a cumulative word-density
        score over a MAX_CLIP_DURATION window. Merges overlapping high-score
        windows. Returns up to `num_clips` non-overlapping highlights sorted by
        start time, each between MIN..MAX seconds long.
        """
        if not segments or total_duration <= 0:
            logger.warning("no_segments_for_highlight")
            return []

        # Build word-density array (words-per-second per segment, linearized)
        timeline = self._build_word_density_timeline(segments, total_duration)

        # Slide a window of MAX_CLIP_DURATION, score each position
        windowed = []
        max_window = int(MAX_CLIP_DURATION)
        t_len = len(timeline)

        step = 1
        max_start = max(t_len - max_window, 0) if t_len > max_window else 0
        for start_sec in range(0, max_start + 1, step):
            end_sec = min(start_sec + max_window, t_len)
            window_duration = end_sec - start_sec
            if window_duration < MIN_CLIP_DURATION:
                continue
            word_count = sum(timeline[start_sec:end_sec])
            score = word_count / window_duration if window_duration > 0 else 0
            windowed.append((float(start_sec), float(end_sec), score))

        if not windowed:
            # Fallback: return evenly-spaced segments covering the video
            return self._fallback_segments(total_duration, num_clips)

        # Sort by score descending, pick top num_clips, deduplicate overlaps
        windowed.sort(key=lambda x: x[2], reverse=True)

        selected = []
        for s, e, sc in windowed:
            if len(selected) >= num_clips:
                break
            # Check no overlap with already-selected
            if not any(self._overlaps(s, e, ss, ee) for ss, ee, _ in selected):
                selected.append((s, e, sc))

        selected.sort(key=lambda x: x[0])

        logger.info(
            "highlights_detected",
            count=len(selected),
            total_candidates=len(windowed),
        )
        return [HighlightSegment(start=s, end=e, score=sc) for s, e, sc in selected]

    def _build_word_density_timeline(self, segments: list[TranscriptSegment], total_duration: float) -> list[int]:
        """Convert segments into a per-second word-count array."""
        duration_int = max(1, int(total_duration) + 1)
        timeline = [0] * duration_int
        for seg in segments:
            s = max(0, int(seg.start))
            e = min(duration_int, int(seg.end) + 1)
            words = len(seg.text.split())
            seg_dur = e - s
            if seg_dur <= 0:
                continue
            # Distribute words evenly across seconds
            for sec in range(s, e):
                timeline[sec] += words / seg_dur
        return timeline

    def _overlaps(self, s1: float, e1: float, s2: float, e2: float) -> bool:
        return s1 < e2 and s2 < e1

    def _fallback_segments(self, total_duration: float, num_clips: int) -> list[HighlightSegment]:
        """Evenly-spaced segments when no highlight detected (edge case)."""
        clip_dur = min(MAX_CLIP_DURATION, total_duration / max(num_clips, 1))
        results = []
        for i in range(num_clips):
            start = i * clip_dur
            end = min(start + clip_dur, total_duration)
            if end - start < 1.0:
                break
            results.append(HighlightSegment(start=start, end=end, score=0))
        logger.warning("using_fallback_highlights", count=len(results))
        return results