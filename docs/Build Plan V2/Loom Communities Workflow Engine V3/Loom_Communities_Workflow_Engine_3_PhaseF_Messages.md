# Phase F — Messages tab (threads + the missing "new thread")

Part of [tracker 3](./Loom_Communities_Workflow_Engine_3.md). **Blocked on Phase A** (and best done
**after Phase E**, which closes the instance-creation grammar gap this phase needs).

> **Scoping note.** Firm on scope, light on snippets — detailed kickoffs are written after Phase A's
> human gate, against the revised JSON.

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
| F.1 | Turn on `tabId: "messages"` in the binding dispatcher | Same flip as prior phases. |
| F.2 | Threads render from JSON `discussion-thread` instances | Thread list + per-thread message list, both via the Repeater (the message list is the in-instance-list shape from Phase B). |
| F.3 | Post message / mark read / archive as real transitions | Effects append to the real `messages` list — no local state. |
| F.4 | **Start a new thread** | Uses the generic instance-creation affordance built in Phase E. If Phase E hasn't landed, this milestone builds it — but generically, not as a Messages special case. Test: create a thread, it appears in the list, is independently readable and repliable. |
| F.5 | Invites: **decide and record** | `sendInvite`/`acceptInvite`/`declineInvite` + `'invite pending'` are named in the renderer contract but have never existed. Either build them, or **explicitly defer them as a named gap and fix the contract to stop claiming them**. A contract that lies is worse than a missing feature. |
| F.6 | Retire `_MessagesEngineStore` | Only once the generic pipeline renders threads correctly. |
| F.7 | Live walk + evidence matrix + random regression re-check | Full-tab audit. |

## Definition of done

- [ ] Threads render from JSON; zero bespoke Dart for `discussion-thread`; `_MessagesEngineStore` deleted.
- [ ] A member can genuinely **start a new thread** — the reported gap is closed.
- [ ] The renderer contract and the implementation **agree** — either invites exist, or the contract no
      longer claims they do.
