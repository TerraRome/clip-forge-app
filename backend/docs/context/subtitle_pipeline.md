# Subtitle Pipeline

## Purpose

ClipForge generates ASS (Advanced SubStation Alpha) subtitle files for burned-in captions. ASS was chosen over SRT because it supports karaoke effects (`\K` override tags), per-word coloring, dynamic positioning, and anti-aliased rendering — all required for the four subtitle presets (classic, tiktok_3words, word_pop, karaoke).

## ASS Format Primer

ASS files have three sections:
- `[V4+ Styles]` — defines font, size, colors, outline, shadow, alignment.
- `[Events]` — dialogue lines with `Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text`.
- Optional `[Script Info]` for metadata.

The `\K` override tag in ASS enables karaoke highlighting: `{\Kduration_cs}text` — the text appears in SecondaryColour for `duration_cs` centiseconds, then reverts to PrimaryColour.

## Pipeline Overview

```
TranscriptionSegments
        │
        ▼
  Filter to highlight window
  (discard segments outside clip range)
        │
        ▼
  Choose preset ↓
  ┌────┬────┬────┬────┐
  │Cls │T3W │WP  │Kar │
  └─┬──┴─┬──┴─┬──┴─┬──┘
    │    │    │    │
    │    │    │    └── Word timestamps → \K per word → cyan highlight
    │    │    │
    │    │    └─────── Word timestamps → \K per word → yellow highlight
    │    │
    │    └──────────── 3-word chunks → rapid-fire dialogue lines
    │
    └───────────────── Full lines → center-bottom static style

                    │
                    ▼
              ASS string → written to .ass file
              │
              ▼
       Passed to FFmpeg as `ass=path.ass` filter
```

## Preset 1: Classic (`_build_classic`)

The default preset. Displays full transcript lines centered at the bottom of the screen.

- **Font**: Arial, 58pt
- **Primary color**: White (`&H00FFFFFF`)
- **Secondary**: Blue (`&H000000FF`)
- **Outline**: 2px black (`&H00000000`)
- **Shadow**: Semi-transparent black (`&H80000000`), 1px
- **Alignment**: Bottom-center (2)
- **Margin**: 10px left/right, 50px vertical

Each `TranscriptSegment` that overlaps the highlight window becomes one `Dialogue:` line. Start/end times are relative to the clip (highlight.start is time 0).

## Preset 2: TikTok 3 Words (`_build_tiktok_3words`)

Three-word chunks displayed in rapid succession, mimicking popular TikTok caption styles.

- **Font**: Arial Bold, 64pt (larger for impact)
- **Capping**: Each chunk displayed for max 2 seconds.
- **Chunking**: Words are split into groups of 3. Partial group (1-2 words) at end is kept.
- **Timing**: Each chunk gets equal duration within its source segment.
- **Duration**: Minimum chunks per segment ensures fast pace.

Example: "I really think this is the best moment ever" →
```
Line 1: "I really think"  (0.0s → 1.5s)
Line 2: "this is the"     (1.5s → 3.0s)
Line 3: "best moment ever" (3.0s → 4.5s)
```

## Preset 3: Word Pop (`_build_word_pop`)

Words appear one at a time in a karaoke-style highlight. All words in the line are visible (dimmed white), and each word briefly turns yellow (SecondaryColour) in sequence.

- **Font**: Arial Bold, 60pt
- **Secondary color**: Yellow (`&H00FFFF00`) for active word
- **Implementation**: Uses `\K` with the delay-to-start as the karaoke duration. The word's duration = time until the next word starts.
- **Requirement**: Word-level timestamps. Re-transcribes the clip segment via Whisper with `word_timestamps=True` and `language="id"`.

The re-transcription is expensive (one Whisper inference per clip). Falls back to Classic preset on any failure (Whisper OOM, empty word list).

**Word Pop ASS example:**
```
Dialogue: 0,0:00:00.00,0:00:03.50,Default,,0,0,0,,{\K30}Saya {\K25}pikir {\K40}ini {\K20}adalah
```
This renders "Saya pikir ini adalah" — each word highlighted yellow sequentially as time progresses through the `\K` durations.

## Preset 4: Karaoke (`_build_karaoke`)

Classic karaoke style: all words visible, previously-sung words dim, current word cyan, upcoming words white.

- **Font**: Arial Bold, 56pt
- **Secondary color**: Cyan (`&H0000FFFF`) for active word
- **Implementation**: Each word gets `\K{duration_cs}` where duration is the word's audio duration. Zero delay between words.
- **Requirement**: Word-level timestamps. Same re-transcription approach as Word Pop.

**Karaoke ASS example:**
```
Dialogue: 0,0:00:00.00,0:00:03.50,Default,,0,0,0,,{\K30}Saya {\K25}pikir {\K40}ini {\K20}adalah
```
Renders "Saya" cyan for 0.3s, "pikir" cyan for 0.25s, etc.

## Shared Utilities

- `_to_ass_time(seconds)` — converts float seconds to ASS time format `h:mm:ss.cs`.
- `_esc(text)` — escapes ASS special characters `{`, `}`, `,`.
- `_clip_segments()` — filters transcript segments to those overlapping the highlight window.
- `_ass_header()` — generates `[V4+ Styles]` section with variable style block.
- `_ass_events()` — generates `[Events]` format line.
- `_get_word_timestamps()` — re-transcribes clip audio with word-level timestamps for WP/Karaoke.

## Rendering Integration

The ASS file is written to disk alongside the output MP4. FFmpeg burns it in during render:
```python
"-vf", f"{crop_filter},ass={ass_file.as_posix()}"
```

The ASS path is positional and must be absolute. The subtitle filter runs after the crop/scale filter in the chain — subtitles are rendered on the final 1080x1920 canvas.
