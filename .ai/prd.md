# AI YouTube Clipper — Product Requirements Document

## Overview

AI YouTube Clipper is a Flutter + FastAPI application that converts long-form YouTube videos into batches of short, vertical clips with embedded subtitles. Users paste a URL, select a clip count (1/3/5/10), and download the results.

## Problem Statement

Creating short-form video content from long-form sources requires manual downloading, trimming, subtitling, and reformatting — a 30-60 minute workflow per clip. Content creators need a one-click solution that handles the entire pipeline automatically.

## Goals

1. Reduce clip creation time from 30+ min to under 5 min for batches of 10
2. Eliminate the need for video editing skills
3. Produce platform-ready vertical videos (1080×1920) with burnt-in subtitles
4. Support batch generation to maximize output per processing run

## Non-Goals (MVP)

- No user accounts or authentication
- No video editing timeline or manual trim controls
- No AI-generated titles, hashtags, or thumbnails
- No cloud storage or project sync
- No multi-language subtitle support (English only)
- No custom subtitle styling or repositioning
- No direct social media posting

## User Personas

### Cara Creator

- **Role:** Independent content creator (TikTok, Shorts, Reels)
- **Needs:** 5-10 clips/day from YouTube sources
- **Pain point:** Spends 2+ hours/day on manual clipping
- **Behavior:** Uses mobile, wants batch output, no patience for tutorials

### Sam Social

- **Role:** Social media manager at an agency
- **Needs:** Bulk clips for multiple client accounts
- **Pain point:** Juggling multiple video projects with tight deadlines
- **Behavior:** Processes 20+ URLs/week, needs reliable batch output

### Noah Newbie

- **Role:** Casual user, no video editing experience
- **Needs:** Extract 1-3 highlights from a podcast or tutorial
- **Pain point:** Daunted by professional editing tools
- **Behavior:** Uses app once or twice, expects instant results

## User Stories

| ID    | Title             | Description                                                                           | Priority |
| ----- | ----------------- | ------------------------------------------------------------------------------------- | -------- |
| US-01 | Paste YouTube URL | As a user, I want to paste a YouTube URL so that the app knows which video to process | P0       |
| US-02 | Choose clip count | As a user, I want to select how many clips to generate (1/3/5/10)                     | P0       |
| US-03 | Start processing  | As a user, I want to initiate processing with one tap                                 | P0       |
| US-04 | View progress     | As a user, I want to see processing progress so I know the app is working             | P0       |
| US-05 | Download clips    | As a user, I want to download all generated clips at once                             | P0       |
| US-06 | Preview clips     | As a user, I want to preview clips before downloading                                 | P1       |
| US-07 | Retry on failure  | As a user, I want to retry processing if something goes wrong                         | P1       |
| US-08 | Cancel processing | As a user, I want to cancel an in-progress job                                        | P2       |

## User Flow

```
[Home Screen] → Paste URL → [Clip Count Screen] → Select 1/3/5/10
    → [Processing Screen] → Progress bar → [Results Screen]
        → Preview clips → Download ZIP
```

### Detailed Flow

1. **Home Screen:** Single URL input field + "Next" button. URL validation on paste.
2. **Clip Count Screen:** Chip selector with 4 options (1, 3, 5, 10). "Start" button.
3. **Processing Screen:** Animated progress indicator, status messages, cancel button.
4. **Results Screen:** Grid of clip previews, "Download All" button, retry for failed clips.

## Functional Requirements

### FR-01: URL Input

- Accept YouTube URLs in formats: `youtube.com/watch?v=`, `youtu.be/`, `youtube.com/shorts/`
- Validate URL format client-side before submission
- Strip playlist and timestamp parameters silently

### FR-02: Clip Count Selection

- Display 4 options: 1, 3, 5, 10
- Single-select chip group
- Default selection: 3

### FR-03: Processing Initiation

- POST request to `/api/projects` then `/api/process`
- Return project ID immediately (non-blocking)
- Transition to processing screen

### FR-04: Progress Tracking

- Poll `GET /api/projects/{id}` every 3 seconds
- Progress states: `pending` → `downloading` → `transcribing` → `highlighting` → `rendering` → `done`
- Show percentage and current stage label

### FR-05: Cancel Processing

- Send cancellation request to backend
- Backend cleans up partial files
- Return to clip count screen

### FR-06: Download Results

- Download ZIP containing all clips
- Each clip: `{project_id}_clip_{n}.mp4`
- Include manifest.json with metadata

### FR-07: Error Handling

- Show user-friendly error messages for: invalid URL, processing failure, network error
- Exponential backoff on retry (max 3 attempts)
- Log detailed errors server-side

## Non-Functional Requirements

| NFR                                | Target                                                             |
| ---------------------------------- | ------------------------------------------------------------------ |
| Processing time                    | < 5 min for 10 clips from 60-min video                             |
| Output format                      | 1080×1920, H.264, 30fps, AAC audio                                 |
| Subtitle format                    | Burned-in, bottom-aligned, white text on semi-transparent black bg |
| API response time (non-processing) | < 500ms                                                            |
| App startup time                   | < 3s on mid-range device                                           |
| Crash-free rate                    | > 99.5%                                                            |
| Max file size per clip             | 50MB                                                               |
| Supported video duration           | 1-120 min YouTube videos                                           |
| Concurrent users (MVP)             | 10 simultaneous processing jobs                                    |

## MVP Scope

**In scope:**

- YouTube video → clips pipeline
- Burnt-in English subtitles via Whisper
- Vertical format (1080×1920) export
- Batch download as ZIP
- Basic error handling and retry

**Out of scope:**

- User accounts
- Manual editing
- Multi-language subtitles
- AI metadata generation
- Thumbnails
- Social posting
- Cloud storage
- Mobile app stores (MVP = web + sideload)

## Future Scope

1. **User accounts** — project history, favorites, usage tracking
2. **AI title & hashtags** — auto-generate metadata per clip
3. **Thumbnails** — auto-select best frame from each highlight
4. **Multi-language** — subtitle generation in 10+ languages
5. **Manual editing** — simple trim handles, subtitle review
6. **Direct upload** — post to TikTok/Shorts/Reels from app
7. **Team workspaces** — shared projects, roles, approvals
8. **API for developers** — programmatic clip generation
9. **Custom branding** — watermark, intro/outro overlay
10. **Monetization** — credits/subscription model

## Acceptance Criteria

### AC-01: URL Validation

- [ ] Invalid URLs show inline error within 100ms
- [ ] Valid YouTube URLs proceed to clip count screen
- [ ] Non-YouTube URLs rejected with clear message

### AC-02: Clip Count Selection

- [ ] All 4 options selectable and visually distinct
- [ ] Only one option selected at a time
- [ ] Default is 3

### AC-03: Processing

- [ ] Processing starts within 2s of tapping "Start"
- [ ] Progress screen updates with correct stage and percentage
- [ ] Processing completes within 5 min for 10 clips
- [ ] All generated clips playable in device video player
- [ ] Subtitles visible and readable in every clip

### AC-04: Download

- [ ] ZIP downloads within 10s of completion
- [ ] ZIP contains correct number of clips
- [ ] Each clip is 1080×1920, plays correctly
- [ ] Manifest.json present with clip metadata

### AC-05: Error States

- [ ] Network timeout shows retry option
- [ ] Invalid YouTube URL (deleted/private) shows error within 30s
- [ ] Processing failure shows error with retry option
- [ ] Cancel stops processing within 5s
