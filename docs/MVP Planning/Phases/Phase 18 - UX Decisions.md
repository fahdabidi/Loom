# Phase 18 - UX Decisions

Date: 2026-06-02

## Reference Patterns Applied

The collaborative modules use common social/creator mechanics:
- Quest and achievement patterns: clear challenge, completion CTA, badge shelf, and completion count.
- Community gallery patterns: compact two-column gallery, featured state, and vote/submit actions.
- Shared-goal patterns: progress bar, milestone chips, and aggregate community-only copy.

## Implementation Decisions

- Quest Log keeps the action simple: one visible quest, one completion action, and a badge chip that changes after completion.
- Build Showcase uses a compact grid instead of a long list, matching social gallery expectations on phone width.
- Guild Quest emphasizes aggregate progress and milestones rather than individual contributor history.
- DriftAndChill and IronVael now both expose Guild Quest, while EmberHollow and IronVael expose Build Showcase/Quest Log variations.
- All three modules stay inside the channel module stack and reuse the same extension host as Phase 17.

## UX Validation Notes

Automated widget coverage validates:
- EmberHollow Quest Log completion shows the Shrine keeper badge.
- EmberHollow Build Showcase accepts a fan build submission.
- DriftAndChill Guild Quest contribution advances aggregate progress.

Manual emulator screenshots remain pending until WSL sees an Android emulator.
