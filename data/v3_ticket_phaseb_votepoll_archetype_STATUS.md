# Ticket status: Phase B.2-3 votePoll archetype card

## Change applied
Status: blocked

## New widget
Part35 was free, so the new widget is `part35_votepoll_archetype_card.dart` and is registered in the app-shell part list. The ballot resolves candidates from `resolved.binding.repeater.source` and resolves the repeater's `itemActions` generically: the declared transition id is matched against the engine's available transitions, and `{item.field}` templates are converted into the declared transition inputs. `close-vote` remains an engine transition id because it is the card-level action and is not a repeater item action. No tally or duplicate-vote rule is computed in Dart.

## Live behavior
The bespoke ballot card reads the engine-computed `voteCounts` map and renders the candidate name, live count, per-candidate detail popup, deadline, computed expiring-soon reminder, and outcome winner when present. The organizer persona is blocked by the JSON cross-instance eligibility guard, so the card has no Vote buttons but does expose the organizer-only Close vote action. An eligible tabletop member receives Vote buttons and no Close vote action. The real member-vote path applies the repeater-declared transition with the selected candidate id, then asks the dispatcher to re-query the engine; the accompanying test verifies the genuine `tournament-vote` row and refreshed tally.

## Verification
flutter analyze: clean. The direct Flutter tool invocation completed with `No issues found!`; the standard wrapper remains unable to start in this sandbox because of the known WSL vsock failure (`UtilBindVsockAnyPort:309: socket failed 1`).
Test suite: not completed (pass count unavailable). Both the targeted votePoll test and the full package-suite invocation were blocked before test execution when Flutter tried to create its localhost tester server: `Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0`. The one known pre-existing A.11 date-picker flake could therefore not be re-counted here; no test assertion failure was observed before the harness block.

## Commit
Commit hash: e3f09665.
