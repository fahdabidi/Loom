Ticket AuthZ.P5 — membership & invitation flows

## Context

Sixth ticket in a larger data-safety hardening effort. AuthZ.P1-P4b are all merged and independently
verified: commits `6113d194`/`eeb95b48` (persona-picker fix, identity-state refactor), `9498ed77`/`a86ec086`
(JSON grammar: persona `accessMode`, workflow `visibility`/`readGuard`, account `status`,
`LoomCommunityInvite` data shape), `b52da1b9`/`ef89f9c2` (read-path row filtering), `d0f5046c`/`49397abb`
(requiredPermission enforcement + a notification-surface regression fix).

**No new JSON grammar in this ticket.** `accessMode` (on `LoomPersonaDefinition`) and `status` (on
`LoomAccount`) already exist and are parsed, from AuthZ.P3. `LoomCommunityInvite` already exists as a data
shape (unused until now) in `part29_auth_api.dart`. This ticket builds the actual sign-up/sign-in/approval/
invite-redemption behavior and UI on top of that existing grammar and data model -- it does not add or
change any JSON field. If you find you need new JSON grammar to make this work, STOP and describe exactly
what's missing in your STATUS response instead of adding it -- JSON schema changes in this project require
the user's explicit review before implementation.

## Scope

**1. `LocalAuthApi.signUp` branches on `accessMode`** (`app/packages/core/loom_communities_app_shell/lib/src/part30_local_auth_api.dart:120-140`,
extend the existing `personaResolver`-based validation from AuthZ.P1 to also expose each persona's
`accessMode`):
- `open` (default) -> unchanged, today's behavior: immediate `active` account.
- `requiresApproval` -> create the account with `status: MembershipStatus.pendingApproval`. Return a
  distinct result type/value that the UI can tell apart from a normal successful signup (not a usable
  session) -- design this cleanly rather than overloading the existing return shape with a boolean flag if a
  clearer typed result makes more sense; use your judgment on the exact Dart shape, but the caller must be
  able to unambiguously tell "created, pending" apart from "created, active" apart from "rejected."
- `requiresInvite` -> reject direct signup for this specific persona (throw/return a clear rejection, not a
  silent no-op). The UI (`_SignUpForm`, `part31_auth_screens.dart`) must not offer this persona in the open
  signup dropdown at all -- filter it out client-side too, not just rely on the server-side rejection (defense
  in depth, matching the pattern already established for the AuthZ.P1 persona-picker fix).

**2. `LocalAuthApi.signIn` rejects non-active accounts** (`part30_local_auth_api.dart:104-116`): if the
target account's `status != MembershipStatus.active`, reject with a clear error distinguishing
`pendingApproval` (still waiting) from any other non-active state, rather than a generic failure.

**3. New `LocalAuthApi` methods:**
- `redeemInvite({required String code, required String displayName})`: look up the `LoomCommunityInvite` by
  `code`, validate `status == InviteStatus.pending` (reject with a clear error if not found/already
  claimed/revoked), create a new `active` account under the invite's `personaTypeId`, mark the invite
  `claimed`.
- `issueInvite({required String personaTypeId, required String issuedByAccountId})`: create a new
  `LoomCommunityInvite` with a freshly generated `code` (short, human-typeable -- your choice of format, but
  document it), `status: pending`.
- `approveAccount({required String accountId})`: find the `pendingApproval` account, flip its `status` to
  `active`.
- Reachability for issue/approve: gate behind the same kind of check the existing admin tab already uses --
  `_personaCanAdministerAnyWorkflow` (or equivalent) for the *issuing/approving* account's own persona in this
  community. Don't invent a separate, parallel "who can approve" concept; reuse the existing admin-capability
  signal.

**4. UI surfaces** (`part31_auth_screens.dart` and a new small addition, your call on exact placement/naming):
- `_AccountList` (135-201): show `pendingApproval`/`invited`-status accounts, visibly disabled with a status
  label (e.g. "Pending approval"), rather than hiding them silently or letting them be tapped to sign in.
- A small "Pending & Invites" surface (or extend an existing admin-adjacent surface if one is a natural fit --
  check what's already there before adding a new screen from scratch) listing pending-approval accounts with
  an Approve action, and a way to issue a new invite (persona type picker + generated code display) for
  `requiresInvite` personas. Gate this surface's visibility the same way as point 3 above.
- A "Redeem an invite code" entry point in the sign-up flow, shown for personas whose `accessMode` is
  `requiresInvite` instead of the normal signup form for that persona.

## Do not do

- Do not add, remove, or change any JSON field or grammar.
- Do not touch AuthZ.P1-P4b code beyond what's needed to extend the `personaResolver`/reuse
  `_personaCanAdministerAnyWorkflow` -- read, don't modify, unless a genuine bug blocks this ticket (say so
  explicitly if so).
- Do not touch the community-open entry gate -- that is AuthZ.P6, a separate ticket. Communities should
  behave exactly as they do today when opened (this ticket only changes what happens *inside* the sign-up/
  sign-in dialog, not when/whether that dialog is shown).
- Do not change `open`-mode persona behavior in any way -- must remain byte-for-byte identical to today.

## Required verification

1. `flutter analyze` on `packages/core/loom_communities_app_shell` -- clean.
2. Full test suite -- baseline 191 passing / 1 known a11 flake failing, plus new tests below.
3. New tests: signUp for each of the three `accessMode` values produces the correct account `status`/result
   shape; signIn rejects a `pendingApproval` account with a clear distinguishable error; `redeemInvite` with a
   valid/invalid/already-claimed code; `issueInvite` + `approveAccount` end-to-end (issue, redeem, confirm
   active); the `requiresInvite` persona is absent from the open signup dropdown; the
   issue/approve surface is gated the same way the admin tab already is (present for an admin-capable
   persona, absent otherwise).
4. If your sandbox cannot run `flutter analyze`/`flutter test`, say so plainly -- independent verification
   will be re-run outside the sandbox regardless.

## Git safety reminder

This repository lives on a OneDrive-synced path. OneDrive's background sync occasionally races with git's own
atomic index writes, producing errors like `fatal: unable to write new index file` or a stale/stuck
`.git/index.lock`. This is a known, transient environment quirk, not a sign anything is broken, and requires
no creative recovery. On an index-lock error: `rm -f .git/index.lock`, wait ~2 seconds, retry the same
command once. If it fails again, STOP -- do not run `git reset --hard`, any broad `--cached` unstage, or
recreate `.git/index` by hand. Report the exact error in your STATUS response and leave the working tree
as-is.

## Commit

One commit, once verified: `feat: build membership approval and invite-redemption flows on accessMode
(AuthZ.P5)`.

## Required response format (write to `data/v3_ticket_authz_p5_membership_flows_STATUS.md`)

```
# Ticket status: AuthZ.P5

## Change applied
Status: done | blocked
Exact file:line for signUp/signIn changes, the three new LocalAuthApi methods, and each new UI surface.
Confirm no JSON grammar was added or changed. Describe the exact result-type shape you chose to distinguish
pending-vs-active signup outcomes.

## Verification
flutter analyze: clean/not clean.
Test suite: pass count. Confirm baseline 191/192 (only known a11 flake) plus name the new tests.

## Commit
Commit hash, or "staged, not committed" + exact blocker.
```
