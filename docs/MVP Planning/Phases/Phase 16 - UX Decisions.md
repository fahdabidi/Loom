# Phase 16 - UX Decisions

Date: 2026-06-02

## Reference Patterns Applied

The channel renderer follows common modern social/video profile patterns:
- Strong top banner with creator identity, avatar, follow/block actions, and visible theme signal.
- Modular stacked sections that can be reordered by data.
- Interactive extension slots that look intentional while later phases add behavior.
- Persona-aware archive entry and contextual ad disclosure near the top of the channel.

## Implementation Decisions

- The banner uses a two-color gradient from the creator's `ChannelTheme`, with a compact theme label so different worlds are immediately visible.
- `SurfaceModule` ordering is respected exactly after filtering disabled modules.
- Extension placeholders use the installed extension name, version, approved surface, and module config text. They read as installed but not yet interactive.
- AI persona text appears in the archive entry and in the hero module, so the assistant posture is visible before entering Q&A.
- Ad posture is rendered as data-driven copy beside the existing allowed/blocked ad policy summary.
- Non-gaming creators receive a default config path with the same renderer, so Phase 16 does not fork the channel UI.

## UX Validation Notes

Automated widget coverage proves:
- NovaClutch and EmberHollow render different banners, module stacks, persona copy, and ad posture copy.
- Unknown modules render a stable safe placeholder.
- Solar Sarah renders through the generic config path with existing content tile keys preserved.

Manual/emulator screenshots for the five gaming channels are still pending because WSL does not currently see an Android emulator.
