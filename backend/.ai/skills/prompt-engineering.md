# Prompt Engineering for Groq/LLM Highlight Selection

## Description
Craft and iterate on prompts for the LLM-based clip selection service. The prompt defines highlight quality — bad prompts produce boring or malformed clips. ClipForge uses one system prompt in `LLMHighlightService.SYSTEM_PROMPT` targeting Indonesian podcast content with Llama-3.3-70B.

## When to Use
- Tuning which transcript segments the LLM selects as highlights
- Adapting the prompt for different content types (podcast, vlog, tutorial, sports, news)
- Improving JSON output reliability (reducing malformed response rate)
- Adding new selection criteria (sentiment, speaker preference, topic focus)

## Inputs
- Content type (e.g., "Indonesian podcast", "English tech review", "gaming commentary")
- Selection criteria (what makes a good clip for this content type)
- Target model name (LLaMA 3.3 70B, GPT-4o, Claude 3.5, etc.)
- Current prompt that needs improvement

## Outputs
- Revised `SYSTEM_PROMPT` constant in `app/services/llm_highlight_service.py`
- Updated user prompt template if needed

## Steps

1. **Define the role clearly**: "You are a video highlight detector for ClipForge. Given a podcast transcript with timestamps [MM:SS], find the most engaging 20-60 second moments." Establish persona, task, and output format upfront.

2. **Specify hard constraints with concrete values**: "Each clip MUST be 20-60 seconds long." "Clips MUST NOT overlap." "Sort by start time ascending." "Return ONLY the JSON array, no markdown, no explanation." Use MUST/SHALL for rules the model must never violate.

3. **Provide prioritized selection criteria**: "Prioritise: emotional peaks, surprising revelations, strong opinions, punchlines, hooks." Order matters — items listed first get highest weight. These appear AFTER the format rules as the model tends to prioritize later instructions.

4. **Include an inline format example**: "Return a JSON array: [{"start": float, "end": float, "reason": string}]". Show the exact structure. If the model frequently returns malformed JSON, add a one-line valid example.

5. **Set temperature and tokens**: `temperature=0.3` for deterministic, reproducible output. `max_tokens=1024` for up to 10 clips with reasons. Higher temperature (0.7+) produces more variety but increases JSON formatting errors.

6. **Add edge-case handling instructions**: tell the model what to do when constraints can't be met: "If you cannot find enough highlights, return fewer clips rather than violating the duration or overlap rules." This prevents the model from stretching short clips or creating invalid outputs.

## Example

```python
SYSTEM_PROMPT = """You are a video highlight detector. Given a podcast transcript with timestamps [MM:SS], find the most engaging 20-60 second moments.

Rules:
- Each clip MUST be 20-60 seconds long (e.g. start=120, end=180 = 60s clip).
- Prioritise: emotional peaks, surprising revelations, strong opinions, punchlines, hooks.
- Return a JSON array: [{"start": float, "end": float, "reason": string}]
- start/end are in seconds from video beginning (e.g. 2min = 120.0).
- Clips MUST NOT overlap.
- Sort by start time ascending.
- Return ONLY the JSON array, no markdown, no explanation."""
```

## Notes
- The current prompt targets Indonesian podcast content (Whisper `language="id"`). For English content, remove the "podcast" context or make it language-agnostic.
- Model behavior varies significantly: Llama-3.3-70B is reliable with structured JSON output. Smaller models (Llama-3.1-8B) need more explicit format instructions and lower temperature.
- If the model frequently returns markdown-wrapped JSON, add "Do NOT wrap JSON in markdown code blocks" to the prompt. The code strips fences regardless as defense-in-depth.
- Test prompt changes with 5+ diverse transcripts (short/long, mono/dialog, high/low energy) before deploying. Log raw responses to detect formatting regressions.
- For different content types, keep a dict of prompts keyed by content type and pass the appropriate one from the pipeline.
