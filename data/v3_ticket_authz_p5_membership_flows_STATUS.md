# Ticket status: AuthZ.P5

## Change applied
Status: done

Exact file:line references:

- `app/packages/core/loom_communities_app_shell/lib/src/part30_local_auth_api.dart:110-132` — `signIn` now rejects `pendingApproval` and other non-active accounts with distinguishable `LoomAuthErrorCode` values.
- `app/packages/core/loom_communities_app_shell/lib/src/part30_local_auth_api.dart:139-175` — `signUp` resolves `accessMode`, preserves the existing open path, creates `pendingApproval` accounts for approval-gated personas, and rejects invite-only direct signup.
- `app/packages/core/loom_communities_app_shell/lib/src/part30_local_auth_api.dart:178-247` — `redeemInvite` validates and claims pending invite records, then creates an active session.
- `app/packages/core/loom_communities_app_shell/lib/src/part30_local_auth_api.dart:249-282` — `issueInvite` validates the issuing account with the existing `_personaCanAdministerAnyWorkflow` capability signal and creates a pending invite with a `LOOM-` plus six-character, uppercase, human-typeable code.
- `app/packages/core/loom_communities_app_shell/lib/src/part30_local_auth_api.dart:284-326` — `approveAccount` uses the current active admin-capable session, verifies the target is pending in the same community, and activates it.
- `app/packages/core/loom_communities_app_shell/lib/src/part31_auth_screens.dart:151-242` — `_AccountList` renders pending/invited accounts as disabled rows with status labels.
- `app/packages/core/loom_communities_app_shell/lib/src/part31_auth_screens.dart:261-484` — `_PendingAndInvitesSurface` is gated by the same admin-capability helper and provides pending-account approval plus invite issuance/code display.
- `app/packages/core/loom_communities_app_shell/lib/src/part31_auth_screens.dart:486-758` — `_SignUpForm` filters invite-only personas from the open signup dropdown and provides the invite redemption entry point.
- `app/packages/core/loom_communities_app_shell/lib/src/part01_local_extension_screen.dart:179-198` — supplies the resolved community experience to the local auth API so API reachability and the generated Admin tab share the same capability calculation.

No JSON grammar was added or changed. The existing `LoomPersonaAccessMode` and membership/invite data shapes are reused as-is.

Signup outcomes use the sealed `LoomSignUpResult` hierarchy in `part29_auth_api.dart`: `LoomActiveSignUpResult` contains a usable session and becomes `currentSession`; `LoomPendingApprovalSignUpResult` contains the created pending account but has a null `session` and never becomes `currentSession`. Rejected signup attempts throw `LoomAuthException` with a stable `LoomAuthErrorCode` (invite-only direct signup uses `personaRequiresInvite`).

## Verification
flutter analyze: not run to completion in this sandbox. Direct `dart analyze packages/core/loom_communities_app_shell` completed cleanly (`No issues found!`). The Flutter SDK startup also cannot write its read-only cache, and the cached runner reaches test loading but cannot create its loopback server socket: `Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0`.

Test suite: runtime pass count unavailable here; zero test assertions executed because of the loopback socket restriction. The ticket's stated baseline remains 191/192 (the one known `a11` flake), but that baseline was not independently re-confirmed in this sandbox. New tests are in `app/packages/core/loom_communities_app_shell/test/authz_p5_membership_flows_test.dart`:

- `signUp returns active, pending, and rejected outcomes by accessMode`
- `signIn rejects pending approval with a distinguishable error`
- `redeemInvite accepts valid codes and rejects invalid or claimed codes`
- `issueInvite and approveAccount complete the membership lifecycle`
- `requiresInvite personas are absent from the open signup picker`
- `pending and invite surface follows the admin capability gate`
- `admin can issue an invite from the visible surface`

## Commit
Commit hash: 50ded181 (initial commit object before final status metadata amend; the final amended hash is reported in the handoff)
