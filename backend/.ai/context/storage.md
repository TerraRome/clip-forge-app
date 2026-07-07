# File Storage Structure

## Directory Layout
```
{downloads_dir}/
  _projects/
    {project_id}.json          # Project metadata
  {project_id}/
    source.mp4                  # Downloaded YouTube video (1080p max)
    audio.wav                   # Extracted audio (16kHz mono PCM)
    clips/
      clip_01.mp4               # Rendered vertical short 1
      clip_01.ass               # ASS subtitle file for clip 1
      clip_02.mp4
      clip_02.ass
      ...
```

## FileStorage (`app/storage/file_storage.py`)
- `FileStorage._lock`: `threading.Lock()` for thread-safe JSON I/O
- `save(project)`: writes `project.to_dict()` as JSON
- `get(project_id)`: reads JSON → `Project.from_dict(data)`
- `update(project_id, **kwargs)`: read-modify-write with lock held
- `delete(project_id)`: removes JSON file

## Output File Details
- `source.mp4`: h264+aac, 1080p max, merged via yt-dlp
- `audio.wav`: PCM s16le, 16kHz, mono (whisper requirement)
- `clip_*.mp4`: h264_videotoolbox, 1080x1920, 5Mbps, AAC 128k, ASS subtitles burned-in
- `clip_*.ass`: ASS subtitle file per preset

## Paths
- Configured via `settings.downloads_dir` (default: `./downloads`)
- Configurable through `.env` or env vars
- Clips stored inside project directory, not separately
