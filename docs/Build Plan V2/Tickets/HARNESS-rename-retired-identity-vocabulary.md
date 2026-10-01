# HARNESS — rename the retired identity vocabulary ticket B introduced (ticket B follow-up)

**Status:** written 2026-10-01, **NOT dispatched**.
**Route:** `data/call_implementation_agent.sh --fresh`. **Renames only. No behaviour change.**
**Follows** [HARNESS-production-wiring-and-direct-grant-auth.md](HARNESS-production-wiring-and-direct-grant-auth.md), whose work is otherwise correct and must not be reverted.

## What happened, and whose fault it is

`retired_vocabulary_gate_test.dart` fails: *"Dart sources contain no retired identity vocabulary"*.
Demo app measured at **261 passed, 1 failed** — this is the only failure; the other four suites are
green (app shell 448 +2, judges 525, engine 345 +1, service 168 +1).

**The cause is the ticket's wording, not the agent's judgement.** Ticket B carried a heading reading
"Authenticate per <retired>, in-process" and used that word throughout -- the exact token is the one
`retired_vocabulary_gate_test.dart` assembles from fragments so the gate file does not trip itself; read it
there rather than having it restated here. The implementing agent named
its identifiers after the ticket, which is the correct instinct, and that word is **retired identity
vocabulary** in this codebase. The ticket has since been corrected so it stops propagating the term.

The four flagged sites:

    workflow_ui_test_harness.dart:1985  seededEvidence<retired>SlugOverridesByRoleId
    workflow_ui_test_harness.dart:1995  seededEvidence<retired>Password
    workflow_ui_evidence_test.dart:2093 a comment quoting the ticket's heading
    workflow_ui_evidence_test.dart:2098 authenticateEvidence<retired>ForRemote

## What to build

Rename each per the gate's own instruction: *"Rename every retired token according to whether it names
a fan, a role, or an actor identity."*

**These name a FAN** — a seeded test fan who holds a role. So the replacement component is `Fan`:

    seededEvidenceFanSlugOverridesByRoleId
    seededEvidenceFanPassword
    authenticateEvidenceFanForRemote

Update the comment at `workflow_ui_evidence_test.dart:2093` to match, and **check the doc comments on
those declarations** — several use the retired word in prose, which the gate also catches when it
appears as an identifier component. Read the gate before assuming which prose is safe: it
deliberately does **not** flag ordinary English words that merely contain the token as a substring,
because this project's standing rule is never to match product vocabulary by substring.

**Sweep rather than fix the four.** `grep` the whole repo for the token as an identifier component
before declaring done — ticket B may have introduced it somewhere the gate does not scan, and the
point is the class, not these four lines.

## Do not

- **Do not add an exemption** for these identifiers to the gate's locked-identifier list. The gate is
  right and the names are wrong.
- **Do not change any behaviour.** This is a pure rename: the auth sequence, the slug overrides, the
  credential fallback across numbered holders, and the engine-recording field all stay exactly as
  ticket B built them. The live-verified slug mapping in particular is measured data — do not touch
  its values.
- **Do not weaken or skip the gate test.** It is correct and it caught a real convention breach.

## Verification

- Demo app returns to **262 passed, 0 failed**.
- The other four suites stay green: app shell 448 (+2), judges 525, engine 345 (+1), service 168 (+1).
- `grep` for the retired token as an identifier component returns nothing outside the gate test
  itself, which assembles it from fragments on purpose.
- `flutter analyze` clean on the demo app (2 pre-existing issues there; a third is yours).
