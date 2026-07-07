# Pyannote-Audio Speaker Diarization

## Description
Identify "who spoke when" in audio using pyannote-audio's speaker diarization pipeline. Labels each transcribed segment with a speaker ID (SPEAKER_00, SPEAKER_01), enabling speaker-aware highlight selection and speaker-labeled subtitles. Not currently integrated in the pipeline.

## When to Use
- Multi-speaker content (podcasts, interviews, panel discussions, debates)
- Adding speaker labels to subtitle output (e.g., "Host: ... | Guest: ...")
- Weighting highlight selection toward the primary speaker
- Counting speaking time per speaker for analytics or content structuring

## Inputs
- `audio_path: str` — 16kHz mono WAV (same file as Whisper input)
- `num_speakers: Optional[int]` — hint for number of speakers (improves accuracy)
- `hf_token: str` — HuggingFace auth token (required; model is gated)

## Outputs
- `list[SpeakerSegment]` — `(start, end, speaker_id)` tuples
- `dict[str, float]` — speaker -> total speaking time in seconds
- Transcript segments enriched with speaker labels

## Steps

1. **Load pyannote pipeline**: `Pipeline.from_pretrained("pyannote/speaker-diarization-3.1", use_auth_token=hf_token)`. First call downloads ~1GB model (takes several minutes). Cache the pipeline instance as a module-level singleton like FaceDetector.

2. **Run diarization**: `diarization = pipeline(audio_path, num_speakers=num_speakers)`. Returns a `pyannote.core.Annotation` object with speaker-labeled segments. Iterate with `diarization.itertracks(yield_label=True)` to get `(Segment(start, end), _, speaker_label)`.

3. **Merge with transcript**: for each `TranscriptSegment`, find overlapping speaker segments using `pyannote.core.Segment(seg.start, seg.end)`. Calculate overlap duration for each speaker. Assign the speaker with the most overlap time. Segments with no overlap get `speaker="UNKNOWN"`.

4. **Identify primary speaker**: count total speaking time per speaker across the entire video. The speaker with the most time is the primary. Optionally boost their segments in highlight selection weighting (e.g., 1.5x score multiplier).

5. **Format for subtitles**: prepend speaker label to dialogue text, e.g., `"SPEAKER_00: text"`. If a speaker-to-name mapping is available (from LLM or config), use friendly names instead.

## Example

```python
from pyannote.audio import Pipeline
from pyannote.core import Segment

pipeline = Pipeline.from_pretrained("pyannote/speaker-diarization-3.1", use_auth_token=settings.hf_token)
diarization = pipeline(audio_path, num_speakers=2)

speaker_map = {}
for segment, _, speaker in diarization.itertracks(yield_label=True):
    speaker_map.setdefault(speaker, []).append(Segment(segment.start, segment.end))

def assign_speaker(seg_start, seg_end):
    best_speaker, best_overlap = "UNKNOWN", 0
    for spk, segments in speaker_map.items():
        for s in segments:
            overlap = max(0, min(seg_end, s.end) - max(seg_start, s.start))
            if overlap > best_overlap:
                best_overlap, best_speaker = overlap, spk
    return best_speaker
```

## Notes
- Pyannote 3.x requires PyTorch (~2GB for model + inference). GPU recommended (2-4GB VRAM), CPU runs at ~2-5x realtime.
- First run downloads the model (~5 min). Cache the pipeline instance globally to avoid re-downloading.
- HuggingFace token (`HF_TOKEN`) is required — the pyannote model is gated and requires accepting terms of use on HF Hub.
- Speaker labels are arbitrary IDs (SPEAKER_00, SPEAKER_01). To get real names, pass the transcript + speaker segments to the LLM for name assignment.
- Short segments (<1s) may be mislabeled due to insufficient audio for classification. Post-process with a smoothing filter (remove alternations shorter than 0.5s).
