# Phase 12 - UX Decisions

## References Applied

- Bluesky-style starter packs: default-selected creator lists, one-tap follow, and creator/community context before confirmation.
- Instagram/TikTok shared-profile landings: creator identity first, compact handle, immediate relationship action, and clear social context.
- YouTube subscribe prompts: recognizable creator card, content preview language, and no empty state after subscription.
- WhatsApp/community invite flows: invited-by context, list preview, and a single confirmation action.
- Modern onboarding account suggestions: avatar, handle, short recommendation reason, selected state, and persistent progress.

## Key Decisions

- The fan capture entry opens from the normal discovery toolbar through a deterministic seeded capture token so the workflow is manually reachable without deep-link plumbing.
- The landing screen leads with a dark creator-branded panel: avatar initials, creator display name, handle, and invitation copy.
- Starter-pack rows use avatar blocks, handles, recommendation reasons, selected check states, and an invite badge for the source creator.
- Already-following members stay visibly selected and locked, matching the idempotent API behavior rather than implying an unfollow action.
- Confirmation sends fans directly back to a populated discovery feed when `feedReady` is true.
- Existing Phase 1 onboarding now reuses starter-pack row language so first-time onboarding and launch-link onboarding feel consistent.

## Workflow Walkthrough

1. Fan taps the creator invite action from discovery.
2. Capture landing resolves the token and displays the invited creator before any write happens.
3. The starter pack appears default-selected with the source creator plus recommendations.
4. Fan can toggle non-followed recommendations and confirms with one `Follow selected` action.
5. The app records the re-follow, bulk-follows the selected set, dedupes existing follows, and returns to discovery with visible feed content.
