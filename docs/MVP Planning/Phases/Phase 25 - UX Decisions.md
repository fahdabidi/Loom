# Phase 25 - UX Decisions

## Reference Patterns Applied

- Creator link flows should behave like modern creator tools: paste URL or ID, resolve a preview, verify title/source/thumbnail, then confirm placement.
- External media should render as native feed tiles while keeping a clear source chip and the original platform title.
- Creator notes are additive context only; they do not replace external titles or attribution.
- Indexing/AI controls should be near the link action so creators understand whether a public reference can appear in search or connected-agent answers.

## Implementation Decisions

- Added a compact Studio link panel inside the customize console, near theme/banner/module controls.
- Used source chips for YouTube, Twitch, Discord, Blog, and Webpage so future sources use the same UX.
- Rendered linked items as feed-style tiles with a source pill, unaltered title, summary, thumbnail fallback, creator note, and search/AI gate footer.
- Fan-channel taps reuse Phase 24 embedded playback for YouTube and external-open handling for non-YouTube sources.

## Workflow Walkthrough

1. Creator opens Customize fan experience.
2. Creator pastes a YouTube URL/ID or generic source ID and adds an optional note.
3. Creator resolves the preview and verifies source attribution, title, summary, thumbnail, and search/AI gates.
4. Creator confirms Add to feed.
5. Fan opens the creator channel and sees the linked reference as a native external-content tile.
6. Fan taps the tile and enters the Phase 24 external playback flow with attribution intact.
