# Phase 24 - UX Decisions

## Reference Patterns Applied

Modern video surfaces keep the player full-width, keep controls unobscured, and place recommendations outside the video frame. Phase 24 follows that pattern: the YouTube iframe owns the player rectangle, while Loom attribution, compliance copy, and "Next from your AI search" sit below it.

YouTube-style "Up next" rails are recognizable but often platform-owned. Loom labels its rail explicitly as AI-search-driven so fans understand the next item comes from their connected agent and source preferences, not YouTube recommendations.

## Player Compliance Decisions

- The YouTube iframe wrapper uses the official `youtube_player_iframe` package with visible controls and fullscreen support.
- No Loom overlay, ad, or custom chrome is placed over the iframe or its controls.
- The original external title remains visible in the source banner and the accurate-match label is additive.
- Non-YouTube links open outside the app through the OS launcher.

## Workflow Walkthrough

1. The fan searches with a connected AI agent.
2. Tapping a YouTube external result opens the external playback screen.
3. The screen shows source attribution, accurate-match label, original title, and the unobscured iframe player.
4. A compliance row explains that Loom controls and ads stay outside the player frame.
5. The "Next from your AI search" rail lists bounded AI-ranked items from the fan's agent, excluding the currently open item.
6. Tapping a non-YouTube source opens it externally rather than embedding it.

## Implementation Tradeoffs

Widget tests disable the live iframe and render a deterministic mock frame. The production app path leaves `enableLiveYoutubePlayer` enabled so emulator/phone validation can confirm real playback when an Android device and network are available.
