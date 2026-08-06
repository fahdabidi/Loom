# Ticket status: AuthZ.P6 fix1

## Root cause(s) found

The failures came from a small set of shared identity and readiness problems, plus one fixture omission:

- Production entry-gate race: `LocalExtensionScreen` started `_refreshCommunityEntryGate()` and `_syncEnginePersonaTypes()` independently from `initState`. The gate could become allowed before the account-to-persona mapping had been installed. The first engine-native query then used the signed-in account id without a corresponding persona mapping, returned no authorized content, and had no later event that reliably retried it. This explains the cross-surface failures in notifications, Home, Giving, Marketplace, VotePoll, Messages, and purchase proposals. This was a production bug in the AuthZ.P6 integration.
- Shared test-helper identity mismatch: synthetic helper accounts used ids such as `test-persona-a` while the seeded actor ids were `persona-a`/`persona-b`; the engine intentionally uses the active account id as its actor id. The shared Tabletop helper also selected `tabletop-member-03` while the frozen widget fixtures use the role-level actor id `tabletop-member`. Those mismatches made otherwise valid content appear unauthorized. The helper now uses ids matching the seeded actors; the dedicated individual-account tests still cover the production account-list behavior.
- Shared test-helper readiness bug: the updated helper only performed bounded fake pumps while the asynchronous gate and persona sync were still settling, and it evaluated `.first` on a display-name finder before that finder existed. This caused account-selection races and `Bad state: No element` failures. It now waits for the actual controls and settles the selected account.
- Several updated calendar/Marketplace tests still relied on the old role picker or unbounded `pumpAndSettle()`. A role picker cannot change the persona type of an already authenticated account, and live notification refresh can keep producing frames while the requested widget is already available. Those tests now select the real test account and use bounded waits for the target surface.
- Gate-test fixture omission: the new `authz_p6_entry_gate_test.dart` seeded `entry-content-1` without `createdByPersonaId`, producing the reported engine initialization error. The seed now declares the first persona as its creator.
- A11 fixture wiring: the event-creation test seeded accounts into one discarded `LocalAuthApi`, mounted a different auth instance, and queried yet another instance. It now mounts and queries one explicitly seeded auth instance. This is a test-fixture fix, not a production change.

The remaining A11 organizer failure is confirmed to be the known pre-existing flake, not a changed gate failure: it still fails before event creation when the date field and day are tapped outside the 800x600 test root, so the `OK` date-picker control never appears. The pre-P6 test has the same date-picker interaction and failure path.

## Change applied

Status: done

- Production bug: added an authorization-sync barrier in `part01_local_extension_screen.dart`. The entry-gate refresh now awaits the account/persona mapping, and the duplicate fire-and-forget initialization call was removed, so the first authorized engine query cannot race the mapping.
- Test fixture bug: added `createdByPersonaId` to the entry-content seed in `authz_p6_entry_gate_test.dart` and made its signup helper ensure the off-screen controls are visible before interaction.
- Test helper/fixture fixes: corrected active account ids, added real bounded waits around persona/account selection, and aligned the frozen Tabletop role-level actor used by the shared tests with its seeded data.
- Test harness fixes: updated Marketplace persona selection, repaired A11 auth-instance wiring and persona selection, and replaced the two affected calendar `pumpAndSettle()` calls with bounded target waits. These are test setup/timing fixes.
- No JSON grammar or JSON fixture format was changed, and no AuthZ.P1-P5 production code was touched.

## Verification

flutter analyze: clean. The Flutter analyzer reported `No issues found!` for `loom_communities_app_shell` using the writable Flutter runtime overlay. The normal `flutter analyze` wrapper in this sandbox could not start because its WSL interop attempted a prohibited loopback/vsock bind; this is an environment limitation, not an analyzer diagnostic.

Test suite: 202 passing / 203 total. The total is computed from 162 `testWidgets` declarations plus 39 plain `test` declarations, with two additional runtime cases produced by the three-style `testWidgets` loop in `v3_calr3g_creatable_action_fab_test.dart` (162 + 39 + 2 = 203). There is exactly one failure: `organizer creates an event and one pending response per member`. Its failure is confirmed as the original pre-existing A11 date-picker/off-screen interaction flake described above, before event creation and unrelated to the entry gate.

`authz_p6_entry_gate_test.dart`: all 4 tests pass in the targeted no-loopback verification run. A direct single-file Flutter invocation is blocked in this sandbox because the test runner cannot create its loopback server socket; the four test cases were run successfully through the faster runner with the same source.

## Commit

Commit hash: fdb4dcb8 (implementation commit; the final metadata-amended commit hash is reported in the handoff)
