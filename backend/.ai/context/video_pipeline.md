# Video Pipeline: Download & Audio

## Download (`VideoService.download`)
```python
yt-dlp command:
  python3 -m yt_dlp
    -f "bestvideo[height<=1080]+bestaudio/best[height<=1080]"
    --merge-output-format mp4
    --ffmpeg-location {ffmpeg_path}
    --no-warnings
    --extractor-args "youtube:player_client=android"
    -o {project_dir}/source.mp4
    {youtube_url}
```
- Strips `NotOpenSSLWarning` / `Deprecated Feature` from stderr
- Timeout: 600s
- Returns output path on success

## Audio Extraction (`VideoService.extract_audio`)
```python
ffmpeg -y -i {video_path}
  -vn -acodec pcm_s16le -ar 16000 -ac 1
  {project_dir}/audio.wav
```
- PCM 16-bit signed little-endian
- 16kHz sampling rate (whisper requirement)
- Mono channel
- Timeout: 600s

## Video Info (`VideoService.get_info`)
```python
ffprobe -v quiet -print_format json -show_format -show_streams {video_path}
```
- Returns parsed JSON dict with streams + format
- Used to get video dimensions and total duration
