# Whisper Reference (ClipForge)

## Model Loading
```python
import whisper
model = whisper.load_model("base")  # or "small", "medium", "large"
```
- Global model per process (loaded once in `TranscriptService.__init__`)
- Model size from `settings.whisper_model` (default: "base")
- ~1.5GB RAM for "base", ~6GB for "large"

## Transcription
```python
result = model.transcribe(
    audio_path,
    language="id",           # Indonesian (forced)
    # word_timestamps=True   # Only for word_pop/karaoke presets
)
```

## Output Structure
```python
result = {
    "segments": [
        {
            "start": 0.0,      # float seconds
            "end": 2.5,        # float seconds
            "text": "Halo semua",
            "words": [          # Only if word_timestamps=True
                {"word": "Halo", "start": 0.0, "end": 0.8},
                {"word": "semua", "start": 0.9, "end": 2.5},
            ]
        }
    ]
}
```

## Capturing Word Timestamps
```python
# Used in subtitle_service._get_word_timestamps()
# Re-transcribes a short audio clip for per-word timing
result = model.transcribe(audio_path, language="id", word_timestamps=True, fp16=False)
```

## Performance
- "base" model: ~2x realtime on M1 Mac (60s audio → ~30s transcribe)
- "large" model: ~10x slower but better accuracy for noisy audio
- No GPU acceleration currently (CUDA/MPS not configured)
- Audio must be 16kHz mono PCM WAV
