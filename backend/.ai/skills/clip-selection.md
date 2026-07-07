# LLM-Based Highlight / Clip Selection

## Description
Use a Groq-hosted LLM (Llama-3.3-70B-Versatile) to select engaging 20-60 second clip windows from a transcript. The LLM evaluates transcript segments for emotional peaks, surprising revelations, strong opinions, punchlines, and hooks — producing higher-quality highlights than word-density heuristics.

## When to Use
- Selecting highlights from a transcript (main highlight path via `LLMHighlightService`)
- Modifying the system prompt to tune selection criteria per content type
- Debugging why LLM selection produces poor clips (wrong content, wrong timing, malformed JSON)

## Inputs
- `segments: list[TranscriptSegment]` — full video transcription with start/end/timestamps
- `total_duration: float` — video length in seconds
- `num_clips: int` — desired number of highlight clips (1, 3, 5, or 10)
- System prompt (in `LLMHighlightService.SYSTEM_PROMPT`)

## Outputs
- `list[HighlightSegment]` — non-overlapping clips sorted by start time, each 20-60s
- Fallback `list[HighlightSegment]` from word-density heuristic if LLM fails

## Steps

1. **Format transcript** — convert segments to prompt-friendly text: `[MM:SS] text` per line, one segment per line. Keep within ~8000 tokens (~6000 words). If transcript exceeds this, truncate from the middle (keep first 10% and last 10%, replace middle with `[...SKIPPED...]`).

2. **Call LLM API** — `client.chat.completions.create(model=settings.llm_model, messages=[system_prompt, user_prompt], temperature=0.3, max_tokens=1024, timeout=60)`. Low temperature (0.3) for consistent, reproducible JSON output. Include `timeout=60` to prevent hanging.

3. **Parse response** — `raw = resp.choices[0].message.content`. Strip markdown code fences (` ```json ... ``` `). Parse JSON array: `[{"start": float, "end": float, "reason": string}]`. Validate each entry: `start >= 0`, `end <= total_duration`, `duration >= 10`, `duration <= 120`. Clamp each clip to max 60s.

4. **Deduplicate overlaps** — sort by priority (LLM returns them ordered by quality). Keep the first clip, skip any subsequent clip that overlaps with already-selected ones. Use overlap check: `new.start < existing.end and new.end > existing.start`.

5. **Sort by start time** ascending. Trim to `num_clips`. Convert to `list[HighlightSegment]` with `score=1.0`.

6. **Handle failures** — if JSON parsing fails, LLM returns None/empty, or all clips fail validation, log warning with the raw response preview and fall back to `HighlightService.detect()` (word-density sliding window). The fallback always produces results, even on edge cases (evenly-spaced segments for empty transcripts).

## Example

```python
resp = client.chat.completions.create(
    model="llama-3.3-70b-versatile",
    messages=[
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": f"Find {num_clips} highlights in this transcript:\n\n{transcript_text}"},
    ],
    temperature=0.3,
    max_tokens=1024,
    timeout=60,
)
raw = resp.choices[0].message.content.strip()
raw = raw.removeprefix("```json").removeprefix("```").removesuffix("```").strip()
clips = json.loads(raw)
results = [HighlightSegment(start=c["start"], end=min(c["end"], c["start"]+60), score=1.0) for c in clips]
```

## Notes
- Llama-3.3-70B on Groq has ~8K token context. Very long transcripts (>6000 words) need truncation before sending.
- API key in `settings.llm_api_key`. Base URL defaults to `https://api.groq.com/openai/v1`. Customize for other providers (e.g., OpenAI, Together, Anthropic).
- The `reason` field from each clip is logged at INFO level for debugging/analytics but NOT exposed in the API response.
- Groq free tier allows ~30 req/min. The pipeline makes ONE LLM call per video, so rate limits are not a concern.
- If switching to a different model, update `settings.llm_model` and adjust the system prompt — different models have different output format reliability.
