# FFmpeg Reference (ClipForge)

## Audio Extraction
```bash
ffmpeg -y -i input.mp4 -vn -acodec pcm_s16le -ar 16000 -ac 1 audio.wav
```

## Clip Rendering (Videotoolbox GPU)
```bash
ffmpeg -y -hwaccel videotoolbox \
  -ss 120.5 -i source.mp4 -t 30.0 \
  -vf "scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,ass=clip_01.ass" \
  -c:v h264_videotoolbox -b:v 5000k \
  -c:a aac -b:a 128k \
  -movflags +faststart -pix_fmt yuv420p \
  clip_01.mp4
```

## Smart Crop Filter (Face-Centered)
```bash
# Landscape: scale height to 1920, crop width to 1080 centered on face
scale={w}:{h},crop=1080:1920:{crop_x}:{crop_y}

# No face fallback: fill then crop center
scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920
```

## Filter Graph
- Single `-vf` combining crop scale + ASS burn-in
- Filter order: scale → crop → ass (pixel-perfect overlay)
- No separate subtitle pass

## FFprobe
```bash
ffprobe -v quiet -print_format json -show_format -show_streams input.mp4
```
Returns dict with `streams[]` (codec_type, width, height) and `format` (duration).

## macOS GPU Notes
- `h264_videotoolbox`: only on macOS, limited options (bitrate, quality, preset)
- Not suitable for Linux deployment — use `h264_nvenc` or `libx264` instead
- `-hwaccel videotoolbox` for decode acceleration
