# Subtitle Pipeline: ASS Generation

## Entry Point
`subtitle_service.build_ass(segments, highlight, preset, video_path) → ASS string`

Dispatches to preset-specific builder based on `preset` param.

## Presets

### classic
- Single style: white Arial 58, black outline, semi-transparent background
- One dialogue line per transcript segment
- Text visible for segment duration

### tiktok_3words
- Bold Arial 64, centered bottom
- Splits segment text into 3-word chunks
- Each chunk appears sequentially, max 2s per chunk
- Fast-paced, TikTok-style captioning

### word_pop
- Karaoke-style: all words visible in dim white, current word highlighted yellow
- Requires word-level timestamps from whisper (`word_timestamps=True`)
- Falls back to classic on error
- Uses ASS `\K` karaoke opcode

### karaoke
- All words visible white, current word highlighted cyan
- Same karaoke mechanism as word_pop but different secondary color
- Falls back to classic on error

## Key Functions
- `_to_ass_time(seconds) → "H:MM:SS.cs"`: Convert seconds to ASS time format
- `_esc(text)`: Escape `{}`, `,` for ASS
- `_clip_segments(segments, highlight)`: Filter transcript segments to highlight window
- `_get_word_timestamps(video_path, highlight)`: Re-transcribe clip audio with word-level timestamps

## ASS Output Structure
```
[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, ...

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,start,end,Default,,0,0,0,,text
```
