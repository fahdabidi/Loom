Ticket AuthZ.P6 — community-open entry gate

## Context

Final ticket in this data-safety hardening effort. AuthZ.P1-P5 are all merged and independently verified:
commits `6113d194`/`eeb95b48` (persona-picker fix, identity-state refactor), `9498ed77`/`a86ec086` (JSON
grammar), `b52da1b9`/`ef89f9c2` (read-path row filtering), `d0f5046c`/`49397abb` (requiredPermission
enforcement), `004b200f`/`b347f919` (membership approval + invite-redemption flows).

This ticket ties everything together at the actual entry point the original bug report was about: "is the
user authorized to view the community at all." Confirmed from source: `CommunityLaunchCard.onTap`
(`app/apps/loom_communities_demo/lib/main.dart:187-199`) pushes straight into `LocalExtensionScreen` with no
check at all; `_activePersona()` (`app/packages/core/loom_communities_app_shell/lib/src/part01_local_extension_screen.dart:463-483`,
line numbers may have shifted slightly across AuthZ.P1-P5, re-verify) silently defaults to `personas.first`
when nobody is signed in -- a community currently renders full content for an anonymous, zero-authentication
default persona the instant it's opened.

**No new JSON grammar in this ticket.** This is pure app-flow wiring using `LoomAccount.status` and
`LoomPersonaAccessMode` (both already exist from AuthZ.P3) and `LoomAuthScreen`/`LocalAuthApi` (already
built/fixed in AuthZ.P1 and AuthZ.P5). If you find you need new JSON grammar, STOP and describe exactly
what's missing in your STATUS response instead of adding it.

**This ticket is a real, visible UX change, not just an internal fix -- do not soften or work around this.**
Every community open will now require an account-selection/creation step first, even the most open,
`accessMode: "open"`-only community. That is the direct, necessary consequence of actually checking
authorization before showing content. For `open`-only communities this should still be a fast "pick a name,
go" flow -- friction should scale with how restrictive the community actually is, not add unnecessary steps
to the open case.

## Scope

1. `LocalExtensionScreen` (or the earliest reasonable point in its build/init lifecycle) checks whether
   `ActiveIdentityScope` (from AuthZ.P2) has a signed-in, `MembershipStatus.active` account for this specific
   `communityExtensionId`. If not, show `LoomAuthScreen` (the community-scoped sign-in/sign-up screen from
   AuthZ.P1, already extended with membership/invite flows in AuthZ.P5) **first**, blocking normal community
   content until a real active account exists for this community -- replacing the current silent
   `personas.first` anonymous fallback.
2. This must correctly route through every `accessMode` path already built in AuthZ.P5: `open` personas ->
   fast sign-up, immediately active, content shows right after. `requiresApproval` -> after signing up, the
   pending-approval state/messaging already built in AuthZ.P5 should show (not a broken/stuck screen) -- the
   user does not get into the community until an admin approves them (in a real product this would need a
   way to check back; use your judgment on the minimal reasonable UX for this demo -- e.g., a manual retry/
   refresh action -- and say clearly in your STATUS response what you chose and why, since this is a genuine
   product decision this ticket doesn't fully specify). `requiresInvite` -> the redeem-invite entry point
   already built in AuthZ.P5 should be reachable from this same gate.
3. Once a real active account exists for a community (in this session), reopening that community should not
   re-prompt sign-in every time -- respect whatever session/persistence `ActiveIdentityScope`/`LocalAuthApi`
   already provide (check what "signed in" actually persists across navigation in the current app -- likely
   just for the lifetime of the app process, given this is a local demo with no real backend -- and match
   that existing behavior rather than inventing new persistence).
4. Communities with a legacy schema (no `workflowDefinitions`, i.e. `experience.workflowDefinitions == null
   || .isEmpty` -- the same check AuthZ.P4b's `_syncEnginePersonaTypes` already uses to no-op) may not have
   personas/accessMode declared in a way this gate can meaningfully act on. Handle this case explicitly and
   sensibly (most likely: skip the gate entirely for such communities, preserving today's behavior for them)
   -- state your handling of this case clearly in your STATUS response.

## Do not do

- Do not add or change any JSON field or grammar.
- Do not touch AuthZ.P1-P5 code beyond what's needed to call into `LoomAuthScreen`/`ActiveIdentityScope`/
  `LocalAuthApi` from this new gate -- read, don't modify, unless a genuine bug blocks this ticket (say so
  explicitly if so).
- Do not weaken or bypass the gate for any community "to make tests pass easier" -- if existing tests assume
  the old anonymous-open behavior, update those tests to go through the new gate correctly (sign in first,
  then assert on content), don't special-case the gate away.
- Do not change what happens *inside* the sign-in/sign-up dialog itself (AuthZ.P1/P5's job, already done) --
  this ticket only changes *when* that dialog is shown.

## Required verification

1. `flutter analyze` on `packages/core/loom_communities_app_shell` -- clean.
2. Full test suite. This ticket is highly likely to require updating existing tests that currently assume a
   community opens straight to content -- that's expected and correct (their assumption was the bug), not a
   regression to avoid. Report the before/after pass count explicitly and explain any test you had to update
   and why, rather than just reporting a final number.
3. New tests: opening an `open`-only community prompts sign-in/sign-up first, then shows content once an
   account exists. Opening a community with a `requiresApproval` persona shows the pending state after
   signup, not content. Opening a community with a `requiresInvite` persona surfaces the redeem-invite path.
   A legacy-schema community's behavior is unchanged (explicitly test this, don't just assume it from the
   no-op check).
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

One commit, once verified: `feat: require a real account before rendering any community's content
(AuthZ.P6)`.

## Required response format (write to `data/v3_ticket_authz_p6_entry_gate_STATUS.md`)

```
# Ticket status: AuthZ.P6

## Change applied
Status: done | blocked
Exact file:line for the gate itself. Explain your handling of: the requiresApproval "waiting" UX, session
persistence across navigation, and legacy-schema communities. Confirm no JSON grammar was added or changed.
List every existing test you had to update to go through the new gate, and why.

## Verification
flutter analyze: clean/not clean.
Test suite: before/after pass counts, explained. Name the new tests added.

## Commit
Commit hash, or "staged, not committed" + exact blocker.
```
