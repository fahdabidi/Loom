# Phase B17 - UX Decisions

## Patterns Reviewed

- Test persona controls must be visible enough for QA but not confused with production identity.
- Unauthorized capabilities should remain inspectable in local testing when that improves evidence.

## Decisions

- The matrix supports actor, receiver, read-only, and disabled states.
- Hidden behavior is represented as disabled/read-only in the demo so every row remains testable and
  evidence can explain why an action is unavailable.
- Masjid Nur public announcement is admin actor, member receiver.
- Member-created workflows such as care requests reverse that direction: member actor, admin receiver.

## Evidence

- Full matrix audit passes in `b17_persona_role_inventory_test.dart`.
