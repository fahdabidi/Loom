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
| F.5 | Invites: **decide and record** | `sendInvite`/`acceptInvite`/`declineInvite` + `'invite pending'` are named in the renderer contract but have never existed. Either build them, or **explicitly defer them as a named gap and fix the contract to stop claiming them**. A contract that lies is worse than a missing feature. |
| F.6 | Retire `_MessagesEngineStore` | Only once the generic pipeline renders threads correctly. |
| F.7 | Live walk + evidence matrix + random regression re-check | Full-tab audit. |

## Definition of done

- [ ] Threads render from JSON; zero bespoke Dart for `discussion-thread`; `_MessagesEngineStore` deleted.
- [ ] A member can genuinely **start a new thread** — the reported gap is closed.
- [ ] The renderer contract and the implementation **agree** — either invites exist, or the contract no
      longer claims they do.
