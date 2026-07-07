"""Quick script: download + transcribe + LLM analyze (no render).
Shows top highlight candidates with reasons and timestamps."""

import sys
import json
from pathlib import Path

# Add backend root to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))  # app/services -> app -> backend

from app.config import settings
from app.services.video_service import VideoService
from app.services.transcript_service import TranscriptService
from app.services.llm_highlight_service import LLMHighlightService

URL = sys.argv[1] if len(sys.argv) > 1 else "https://www.youtube.com/watch?v=n2AUMch06qw&t=1250s"

video_svc = VideoService()
transcript_svc = TranscriptService(model_name=settings.whisper_model)
llm_svc = LLMHighlightService()

tmp_dir = Path("/tmp/klip_analyze")
tmp_dir.mkdir(parents=True, exist_ok=True)
video_path = str(tmp_dir / "source.mp4")
audio_path = str(tmp_dir / "audio.wav")

print("1/4 Downloading...")
video_svc.download(URL, video_path)

print("2/4 Extracting audio...")
video_svc.extract_audio(video_path, audio_path)

print("3/4 Transcribing (this may take a while)...")
segments = transcript_svc.transcribe(audio_path)

print("4/4 Analyzing with LLM...")
highlights = llm_svc.detect(segments, 0, 3)

print("\n" + "=" * 60)
print("TOP 3 HIGHLIGHT CANDIDATES")
print("=" * 60)
for i, h in enumerate(highlights):
    mins = int(h.start // 60)
    secs = int(h.start % 60)
    end_m = int(h.end // 60)
    end_s = int(h.end % 60)
    print(f"\n  Clip {i+1}: {mins:02d}:{secs:02d} → {end_m:02d}:{end_s:02d}  ({h.score:.1f})")

# Show transcript around each highlight
print("\n" + "=" * 60)
print("TRANSCRIPT AROUND HIGHLIGHTS")
print("=" * 60)
for i, h in enumerate(highlights):
    mins = int(h.start // 60)
    secs = int(h.start % 60)
    end_m = int(h.end // 60)
    end_s = int(h.end % 60)
    print(f"\n--- Clip {i+1}: {mins:02d}:{secs:02d} → {end_m:02d}:{end_s:02d} ---")
    for seg in segments:
        if seg.start >= h.start and seg.end <= h.end:
            m = int(seg.start // 60)
            s = int(seg.start % 60)
            print(f"  [{m:02d}:{s:02d}] {seg.text}")

print("\nDone.")
