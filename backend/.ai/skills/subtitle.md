# ASS Subtitle Generation

## Description
Generate ASS (Advanced SubStation Alpha) subtitle content for clip rendering. Four presets: classic (full lines), tiktok_3words (three words per chunk), word_pop (all words dimmed, one highlighted yellow via karaoke), karaoke (all words visible, active word in cyan). Format is ASS v4+ rendered natively by FFmpeg's `ass=` filter.

## When to Use
- Adding or modifying a subtitle preset
- Debugging subtitle rendering (wrong timing, missing text, encoding artifacts)
- Adding new visual effects (fade-in, slide, color cycling, glow)

## Inputs
- `segments: list[TranscriptSegment]` — transcription with start/end/text
- `highlight: HighlightSegment` — clip window (start, end) to generate subs for
- `preset: str` — one of "classic", "tiktok_3words", "word_pop", "karaoke"
- `video_path: Optional[str]` — needed for word_pop and karaoke (re-transcribes with word timestamps)

## Outputs
- ASS format string written to `.ass` file, passed to FFmpeg via `ass=` filter

## Steps

1. **Filter segments to clip window** — call `_clip_segments()` to keep only segments overlapping `[highlight.start, highlight.end]`. Shift all timestamps relative to clip start (subtract `highlight.start`). This is critical for correct subtitle sync.

2. **Build ASS header** — `[V4+ Styles]` section with style definitions. Each preset uses different parameters: classic (Arial 58, bottom-center, white), tiktok_3words (Arial Bold 64), word_pop (Arial Bold 60, yellow SecondaryColour for highlight), karaoke (Arial Bold 56, cyan SecondaryColour). The `Format:` line defines style field order — must match exactly.

3. **Generate dialogue events** — `[Events]` section with `Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text`. One `Dialogue:` line per subtitle event. Timestamps in ASS format: `H:MM:SS.cs` (centiseconds). Skip empty/silent segments.

4. **Classic preset** — one dialogue line per transcript segment, full text. Simplest, most reliable. Used as fallback when word-timestamp presets fail.

5. **TikTok 3-words preset** — split segment text into groups of 3 words. Calculate per-chunk duration evenly across the segment (capped at 2.0s per chunk). More lines than classic, each shorter and punchier.

6. **Word pop / Karaoke presets** — re-transcribe clip audio with Whisper `word_timestamps=True` to get per-word start/end. Use ASS `\K<centiseconds>` karaoke tags. Word pop: `\K` transitions dimmed text to yellow. Karaoke: `\K` transitions dimmed text to cyan. Fall back to classic if word-timestamp extraction fails (Whisper OOM, empty words, API error).

## Example

```python
ass_content = _ass_header('Style: Default,Arial,58,&H00FFFFFF,&H000000FF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,2,1,2,10,10,50,1')
ass_content += "\n[Events]\nFormat: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text"
for seg in clipped_segments:
    ass_content += f"Dialogue: 0,{_to_ass_time(seg.start)},{_to_ass_time(seg.end)},Default,,0,0,0,,{_esc(seg.text)}\n"
Path(output_path).with_suffix(".ass").write_text(ass_content, encoding="utf-8")
```

## Notes
- ASS color format: `&HAABBGGRR` (alpha, blue, green, red hex). Common values: `&H00FFFFFF`=white, `&H00000000`=black, `&H000000FF`=blue, `&H00FFFF00`=yellow, `&H0000FFFF`=cyan.
- Alignment values: 2=bottom-center (all presets), 8=top-center, 1=bottom-left, etc. Set in the style definition.
- `\K` karaoke duration is in CENTISECONDS (hundredths of second). `\K200` = 2.0 seconds, NOT 200ms.
- Always escape ASS special chars: `{` -> `\{`, `}` -> `\}`, `,` -> `\,` via `_esc()`. Unescaped commas break the ASS parser (comma is field delimiter in dialogue lines).
- Word-pop and karaoke require re-transcribing with `word_timestamps=True`, which doubles transcription time for that clip. Worth it for visual quality, but fallback to classic ensures reliability.
