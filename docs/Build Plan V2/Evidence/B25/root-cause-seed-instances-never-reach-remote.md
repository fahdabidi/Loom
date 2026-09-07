# Root cause: community seed data (`workflowInstances`) never reaches the remote backend

**Found:** 2026-09-07, while scoping the (now much smaller) Cedar document-content upload ticket.
Checking why Cedar's seeded `hoa-member-document` instances didn't exist in the live database led
to this — a structural gap, not a per-community data problem.

**Status: DECIDED 2026-09-07 — intentional, not a defect. No code changed. See the decision below.**

## The claim, and why it's airtight

Every community package (`docs/references/communities/*.jsonc`) declares a `workflowInstances`
array — seeded example content: Cedar's dues charges, documents, notifications; Garden's events;
every other community's example data. The B25 production-readiness bar and every walkthrough this
session has assumed this content exists and is interactable.

**It never reaches the remote, Postgres-backed engine.** The only call site that installs seed
data is `_initialize()` in
`app/packages/core/loom_communities_app_shell/lib/src/part25_engine_native_community_store.dart:290`:

```dart
Future<void> _initialize() async {
  final local = engine;
  if (local is! LocalWorkflowEngineApi) return;   // <-- exits immediately for remote
  ...
  await local.seedInstances(seeds);
}
```

Confirmed with two direct checks, not just reading this one function:
- `RemoteWorkflowEngineApi` has **no `seedInstances` method at all** — grepped the whole file,
  zero matches.
- `workflow_service.dart` (the deployed Dart backend) has **no seed or install endpoint** — grepped
  the whole file for `seed`/`/install`, zero matches.

So there is no path, client or server, that could install a community's declared seed content into
the remote backend. Every community opened against the real deployed cluster starts genuinely
empty, regardless of what its JSON declares.

## Direct confirmation on the live cluster

Queried `workflow_instances` for `community_cedar_commons_hoa` today: 4 rows total — 3
`hoa-facility-reservation` instances from 2026-08-26 (created live, by a real persona, not from the
package's seed data) and 1 `hoa-owner-notification` I created manually via the API a few hours ago.
**Zero rows of any type from the package's actual seed block** — no `hoa-dues-payment`, no
`hoa-member-document`, nothing.

## This resolves the open question from the earlier Postgres-outage investigation

The evidence doc `root-cause-postgres-outage-live-write-timestamps-2026-09-06.md` established that
16 live-verification walkthroughs from 2026-09-03/04/05 correspond to zero rows in the live
database, three with a timestamp landing inside a confirmed ~25-hour Postgres outage. That document
left open *why* those walkthroughs showed populated, working screens (e.g. the Cedar dues
walkthrough describing "two seeded `hoa-dues-payment` instances, both board-visible") without a
matching database write.

**This is why.** A walkthrough that sees seeded example content — by definition, per this finding
— is running the local engine, since that is the only engine seeding ever installs into. It is not
a symptom of the outage, a stale APK, or a flaky OAuth flow; it is what every walkthrough looks like
whether the deployed backend is healthy or not, because seed content only ever exists locally. The
outage's real, narrower significance is what it did to the three genuinely-remote-attempted writes,
not to the general "why did these look populated" question — that question has a simpler, structural
answer that predates and is independent of the outage.

## What this blocks

- **The Cedar document-content upload ticket** (already scoped this session) cannot proceed as
  originally framed — there is no seeded `hoa-member-document` instance to attach content to. It
  would need to *create* the instances first, which is a bigger, different question: should a
  fixture create them via the same manual-API-call pattern used for the notification test earlier,
  or does this gap need fixing at the source first?
- **Any B25 walkthrough or UX judge run against the real deployed backend** starts from an empty
  community with no example content, unless every workflow instance needed is created live during
  that same run. This likely also explains gaps noted elsewhere this session (e.g. "ten of eleven
  communities still have no members" was already known; this is the reason no community has seed
  *content* either, once opened for real).

## Decided, 2026-09-07 (user)

**Intentional — not a defect. Local-only seeding stays as-is.** Real communities against the remote
backend are meant to start empty and be populated by real member activity, not by package-declared
seed content. No server-side seed/install endpoint will be built. This closes the three open
questions above: (1) intentional, (2) N/A, (3) does not outrank other work — nothing to prioritize.

**Consequence for verification methodology, not for the product.** Every B25 walkthrough and UX
judge run against the real deployed backend must stop assuming seeded content will be present. To
exercise a workflow that depends on existing data (e.g. reviewing a pending request, reading a
published document), the verification pass must first perform the real role-based actions that
create that data — sign in as the relevant role and actually create/submit/publish it live — before
checking the downstream state, the same way this session's Cedar `hoa-owner-notification` and
`hoa-document-access-request` proofs were done by hand via the real authenticated API. A walkthrough
that opens a community and finds it empty is not evidence of a bug; it is the expected starting
state, and the walkthrough's own job is to populate it through the same actions a real user would
take.

This also finally and fully closes the "why did those 16 walkthroughs show populated seed content"
question from the Postgres-outage finding: those walkthroughs were exercising the local demo engine
(the only engine seeding ever reaches), not a defect and not a symptom of the outage — and per this
decision, that's simply not the mode any future remote-backend verification should run in.

## Scope note

No code was changed. No community `*.jsonc` was touched.
