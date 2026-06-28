# Phase B19 - UX Decisions

## Patterns Reviewed

- Local test UX should make permission differences explicit without adding instructional overlay text.
- Workflow tiles should not shift layout when switching personas.

## Decisions

- Actor personas see the existing `Complete` action.
- Receiver personas see waiting chips until prerequisite state exists, then a receive action.
- Read-only personas see a read-only chip and explanatory row text.
- Disabled personas see an unavailable chip and reason text.

## Evidence

- B19 Android screenshots prove member-owned care request, member-blocked public announcement, and
  admin-enabled public announcement.
