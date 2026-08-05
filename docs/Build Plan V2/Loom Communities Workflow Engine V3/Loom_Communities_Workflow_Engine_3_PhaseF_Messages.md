# Phase F — Messages tab (threads + the missing "new thread")

Part of [tracker 3](./Loom_Communities_Workflow_Engine_3.md). Phase A, B, C, D, and E are all closed —
including Phase E, whose creation-grammar work (GAP-2) this phase needs and which is now proven real and
tab-agnostic (see Phase E's closure evidence).

## Process note (2026-08-05, before starting)

Unlike Phase C/D/E, this doc's own scoping held up under investigation — nothing here was already secretly
done. Confirmed: `'messages'` is genuinely absent from `_enabledTabs`, no test exercises the real frozen
`discussion-thread` JSON, and the tab today renders entirely through the legacy `_MessagesTabSurface`/
`_MessagesEngineStore` (the same private-in-widget-engine anti-pattern already retired elsewhere this
session). F.1-F.7 are all genuinely open — this phase needs the full build, not a "close what's already
real" pass. Also confirmed: the frozen JSON's `discussion-thread` type declares no `sendInvite`/
`acceptInvite`/`declineInvite` transitions at all — F.5's "renderer contract lies" framing is exactly right,
there is nothing to build there, only a contract correction.

## Goal

Move discussion threads onto the engine and build the action the user found missing: **there is no way to
start a new thread.**

## The gap, precisely

The Messages tab's own renderer contract (`part11_shell_models.dart:911-951`) **already requires**
`createThread`, `sendInvite`, `acceptInvite`, `declineInvite`, and an `'invite pending'` state. The
implementation (`_MessagesEngineStore`, `part02_tab_shell.dart:927-980`) has **only** `mark-read` and
`post-message` (reply-within-thread). Threads exist solely because they were seeded. A member can reply
forever but can never start a conversation.

So this is not a "nice to have" — the tab has been shipping against a contract it doesn't meet.

## Messages is a fixed App Shell tab — confirmed, not a bug

Worth recording, since it was asked directly: `appShellTabsFor` (`part12_persona_and_tabs.dart:196-497`)
adds `home` and `messages` **unconditionally** — they are the only two guaranteed tabs. And
`_mergeDeclarativeTabSpecs` **force-includes** `messages` even against a declarative override trying to
remove it. Its default label is the literal `'Messages'`, but that label **is** overridable via
`appShellConfiguration['tabs']`.

**So: Messages is structurally part of the App Shell, always present in every community, and renameable
but not removable.** That is the existing, correct behavior — this phase does not change it.

## What must genuinely work

| Workflow type | Instances | Must genuinely work |
|---|---|---|
| `discussion-thread` | `thread-welcome`, `thread-game-suggestions` | Post a message (real `append` effect onto the `messages` list, stamped `$actor` + `$timestamp`); mark read; archive; **start a brand-new thread** |

## User stories

- *As a member, I read the club's threads and reply within one.*
- *As a member, I mark a thread read and the unread state really clears.*
- *As a member, **I start a new thread** with a subject and a first message — and it appears in the list
  for everyone in it.*
- *As a member, I archive a thread I'm done with.*

## Milestones

| # | Milestone | Notes |
|---|---|---|
| F.1 | ✅ Closed (2026-08-05, commit `cadb2af2` + fix1 `c9bd4a66`). Turn on `tabId: "messages"` in the binding dispatcher | Same flip as prior phases. |
| F.2 | ✅ Closed (same commits). Threads render from JSON `discussion-thread` instances | Reused `EngineNativeListSurface` for the thread list and `GenericWorkflowInstanceCard` for each thread — zero bespoke `discussionThread` widget. The nested `messages` list (a list-of-maps field) needed a new **generic** structured-list renderer added to the shared card (not Messages-specific — detects any list field whose items are maps and renders sender/body/timestamp generically, falling back gracefully for unknown shapes). |
| F.3 | ✅ Closed (same commits). Post message / mark read / archive as real transitions | Real `applyTransition` calls through the existing generic action row and transition-input dialog (`post-message`'s real `input.body`). One fix round: the test's own timing (querying the engine before an async mutation completed) initially made mark-read look broken; a direct engine probe confirmed the real transition and persistence path were correct all along. |
| F.4 | ✅ Closed (same commits). **Start a new thread** | Reused Phase E's proven generic creation-FAB grammar unmodified. Needed one real, generic (not Messages-specific) extension: `personaId[]`-typed creation fields now use the existing `AudienceMultiSelectPicker` automatically, closing a gap Phase E's own creation form didn't need (no `personaId[]` field there) but this one does (`participantPersonaIds`). |
| F.5 | ✅ Closed (2026-08-05, commit `a8c8c92c`). Invites: **decide and record** | **Decision: defer, and correct the contract to stop claiming them.** The frozen JSON declares no invite transitions at all — never a scope gap, a false claim in `part11_shell_models.dart`'s `LoomTabRendererContract`. Removed the invite anatomy/interactions/state/evidence claims; corrected `fallbackPolicy` (which previously said Messages "must not render as a generic workflow list" — now factually wrong given F.1-F.4). `rendererId: 'MessagesTabSurface'` kept unchanged as the shared legacy/engine-native dispatch identifier. Confirmed nothing else in the codebase depended on the removed claims. Verified independently: `flutter analyze` clean, 177/178 green (only the known a11 flake). First-try success. |
| F.6 | ✅ Closed (2026-08-05, no code change needed). Retire `_MessagesEngineStore` | Confirmed the legacy path is already unreachable for Tabletop Club — F.1's `_hasEngineNativeBinding(experience, 'messages')` gate is checked ahead of `_MessagesTabSurface`'s dispatch and evaluates true for the real fixture. Unlike Marketplace's C.6, there was no Messages-equivalent of `_marketplaceListingsFromEngineNative` (no dead legacy projection function) to remove — `_MessagesTabSurface`/`_MessagesEngineStore` remain fully intact for other communities' schema-v1 path, untouched. Verified independently: `flutter analyze` clean, 177/178 green (only the known a11 flake). |
| F.7 | Live walk + evidence matrix + random regression re-check | Full-tab audit. |

## Definition of done

- [x] Threads render from JSON; zero bespoke Dart for `discussion-thread` (F.1-F.4). `_MessagesEngineStore`
      is not literally deleted — it's genuinely unreachable for Tabletop Club and stays intentionally intact
      for other communities' schema-v1 path (F.6), matching this session's established pattern for shared
      legacy widgets (Marketplace's `_MarketplaceBrowseSurface`).
- [x] A member can genuinely **start a new thread** — the reported gap is closed (F.4).
- [x] The renderer contract and the implementation **agree** — invites don't exist in the JSON, and the
      contract no longer claims they do (F.5).
