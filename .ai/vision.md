# AI YouTube Clipper — Vision

## Vision

Democratize video repurposing. Turn any long-form YouTube video into a batch of short, subtitle-burned clips in seconds — no editing skills required.

## Mission

Build the simplest AI-native tool that takes a YouTube URL and a desired clip count, and delivers ready-to-post vertical videos with embedded subtitles.

## Product Goals

1. **Zero friction** — paste, pick count, download. No sign-up, no timeline, no tutorial.
2. **Batch intelligence** — AI finds the best moments; user trusts the algorithm.
3. **Mobile-first** — built in Flutter; works on iOS, Android, and web from day one.
4. **Subtitle-native** — every clip has readable, burnt-in subtitles by default.
5. **Production speed** — process up to 10 clips from a 1-hour video in under 5 minutes.

## Target Users

- **Content creators** repurposing YouTube material for TikTok/Shorts/Reels
- **Social media managers** needing bulk clips for multi-platform posting
- **Podcast/educational teams** extracting quotable moments
- **Casual users** who want highlights without learning video editing

## Problems Solved

| Problem                     | Solution                            |
| --------------------------- | ----------------------------------- |
| Manual clipping takes hours | AI detects highlights automatically |
| Subtitling is tedious       | Whisper transcript → burnt-in SRT   |
| Vertical export is fiddly   | FFmpeg crops + pads to 9:16         |
| Batch is painful            | One URL → N clips in one request    |

## Product Philosophy

- **AI-first, editor-zero** — the algorithm picks highlights; no timeline, no trim handles.
- **Batch over single** — generate multiple clips at once; single-clip is a use case of batch (N=1).
- **Download over stream** — clips are files you own; no cloud locker.
- **Opinionated defaults** — every clip is 1080×1920, H.264, 30fps, with bottom-aligned subtitles.
- **YAGNI** — no accounts, no cloud sync, no manual subtitle edit. Ship the 80 % that delivers 100 % of value.

## Success Metrics

| Metric                     | Target                                                 |
| -------------------------- | ------------------------------------------------------ |
| Clip generation time       | < 5 min for 10 clips from 60-min video                 |
| Processing success rate    | > 95 %                                                 |
| Clip playback-ready        | 100 % — H.264, correct aspect ratio, subtitles visible |
| User drop-off at URL input | < 20 %                                                 |
| Download rate              | > 60 % of processed projects                           |

## Future Vision (Post-MVP)

- AI title & hashtag generation
- Thumbnails with auto-captions
- Editable timeline (trim, reorder, merge)
- Cloud project sync
- User accounts with history
- Team/collab workspaces
- API for programmatic access
- Mobile app store distribution
