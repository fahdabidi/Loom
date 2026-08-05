# Ticket status: Phase F.1-F.4 fix1

## Root cause of the mark-read bug
The frozen JSON seeds `thread-game-suggestions` with `unread: true`. Its
`mark-read` transition is real, guarded for the two tabletop personas, and has
the unconditional effect `set unread false`. The generic card passes
`instance.instanceId` directly to `applyTransition`, so the tapped key and
engine target are both `thread-game-suggestions`.

A direct probe using the frozen definition and `LocalWorkflowEngineApi`
confirmed the full persistence path: the row started `unread: true`, exposed
`mark-read`, and returned and persisted `unread: false` after the transition.
The failure was in the widget test's synchronization. The action callback
starts an async mutation, while the test immediately waited for the subject
text, which was already rendered before the tap. The engine was then queried
before the mutation completed.

## Change applied
Status: blocked

## Verification
flutter analyze: clean.
Test suite: not executable in this sandbox. The focused command reached 0/2
test files executed, and the full app-shell command reached 0/50 test files
executed; each stopped at Flutter tester startup with `Failed to create server
socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1,
port = 0`. The direct engine mark-read probe passed. Because no widget test
executed, I cannot truthfully confirm that the only full-suite failure is the
known a11 flake; independent rerun outside this sandbox is required.

## Commit
c9bd4a66b71002e5acfe7d50ba2b69a1edc7019b; runtime widget tests are blocked by
the exact server-socket restriction above.
