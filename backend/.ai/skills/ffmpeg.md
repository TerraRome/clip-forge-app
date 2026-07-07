# FFmpeg Filter Graph Construction

## Description
Build and debug FFmpeg command lines for the ClipForge rendering pipeline: crop to 9:16 vertical, smart-crop to track a face, scale to 1080x1920, burn ASS subtitles, and encode with hardware acceleration. FFmpeg is the core rendering engine.

## When to Use
- Rendering a clip (the main `RenderService.render_clip()` path)
- Adding a new video filter (color grading, speed ramp, transitions, overlays)
- Debugging encoding issues (wrong codec, artifacts, unsupported pixel format)
- Building preview thumbnails or diagnostic frame dumps

## Inputs
- Source video path and timestamp range (`-ss start`, `-t duration`)
- Target dimensions: 1080x1920 (vertical shorts format)
- Crop filter string (from `SmartCropService.compute_filter()`)
- ASS subtitle file path
- Encoding codec and bitrate settings

## Outputs
- Complete FFmpeg subprocess command
- Rendered MP4 file at specified output path
- Captured stderr for error diagnosis

## Steps

1. **Build base command**: `[ffmpeg, "-y", "-hwaccel", "videotoolbox", "-ss", str(start), "-i", video_path, "-t", str(dur)]`. `-ss` before `-i` = fast seek (keyframe precision). After `-i` = frame-accurate but slower. Current code uses input seeking for speed; consider dual `-ss` for accuracy: `-ss start -i input -ss 0 -t dur`.

2. **Build video filter chain**: combine crop and subtitle filters with comma. `-vf "{crop_filter},{ass_filter}"`. Filters execute left-to-right on the video stream. The crop filter produces 1080x1920, then the ASS filter overlays text on that canvas.

3. **Add encoding params**: `-c:v h264_videotoolbox -b:v 5000k -pix_fmt yuv420p -tag:v avc1`. Hardware encoder depends on platform. Add `-profile:v high -level:v 4.2` for broad device compatibility. Always set `-pix_fmt yuv420p` (required by most players for H.264).

4. **Add audio encoding**: `-c:a aac -b:a 128k`. Use AAC for maximum compatibility. Stream copy (`-c:a copy`) only if source audio is already AAC and no processing needed.

5. **Validate command before running**: log the full command at DEBUG level. Run with `subprocess.run(cmd, capture_output=True, text=True, timeout=600, stdin=subprocess.DEVNULL)`. FFmpeg reads from stdin by default and may hang without DEVNULL. Check `returncode`, log `stderr` on failure.

6. **Verify output** — run `ffprobe -v error -show_entries format=duration,size -of json output.mp4`. Confirm duration matches expected, file size is reasonable (not 0 bytes), and the file is playable.

## Example

```python
cmd = [
    settings.ffmpeg_path, "-y",
    "-hwaccel", "videotoolbox",
    "-ss", str(highlight.start),
    "-i", video_path,
    "-t", str(highlight.end - highlight.start),
    "-vf", f"{crop_filter},{ass_filter}",
    "-c:v", "h264_videotoolbox",
    "-b:v", "5000k",
    "-c:a", "aac",
    "-b:a", "128k",
    "-movflags", "+faststart",
    "-pix_fmt", "yuv420p",
    "-tag:v", "avc1",
    str(output_path),
]
```

## Notes
- Hardware encoders: macOS `h264_videotoolbox`, Linux NVIDIA `h264_nvenc`, Linux Intel `h264_qsv`, fallback `libx264` (software). Platform detection should select the best available encoder.
- Frame-accurate seeking with subtitles: `-ss` after `-i` is slower but prevents subtitle drift. The current code uses input seeking, which may cause up to 1 keyframe interval (~2s) of subtitle sync drift.
- ASS subtitles must reference fonts installed on the system. All ClipForge presets use Arial, which is universally available.
- The crop filter from `SmartCropService` outputs one of: center-fill (`scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920`) or face-anchored (`scale=W:H,crop=1080:1920:X:Y`).
