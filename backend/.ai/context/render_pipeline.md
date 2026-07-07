# Render Pipeline: Clip Encoding

## `RenderService.render_clip(...)`

### Inputs
- `video_path`: source MP4 file
- `segments`: full transcript
- `highlight`: start/end timestamps for this clip
- `output_path`: where to write clip_XX.mp4
- `video_width/height`: source dimensions
- `crop_filter`: FFmpeg filter string from SmartCropService
- `subtitle_preset`: one of 4 presets

### Process
1. Build ASS subtitle content via `subtitle_service.build_ass()`
2. Write ASS file alongside output (e.g., `clip_01.ass`)
3. Build FFmpeg command:
```python
ffmpeg -y
  -hwaccel videotoolbox
  -ss {highlight.start}
  -i {video_path}
  -t {highlight.duration}
  -vf "{crop_filter},{ass_filter}"
  -c:v h264_videotoolbox -b:v 5000k
  -c:a aac -b:a 128k
  -movflags +faststart
  -pix_fmt yuv420p
  {output_path}
```

### Crop Filter
- From `SmartCropService.compute_filter(face, video_width, video_height)`
- Strategy: scale → face-centered 1080x1920 crop
- No face fallback: `scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920`

### Output Format
- 1080x1920 (9:16 vertical) — TikTok/Shorts compliant
- h264_videotoolbox (macOS GPU encoder)
- 5 Mbps video bitrate
- AAC 128 kbps audio
- yuv420p pixel format (broad compatibility)
- faststart (moov atom at front for streaming)
