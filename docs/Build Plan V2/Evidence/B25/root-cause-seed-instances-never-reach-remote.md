# Root cause: community seed data (`workflowInstances`) never reaches the remote backend

**Found:** 2026-09-07, while scoping the (now much smaller) Cedar document-content upload ticket.
Checking why Cedar's seeded `hoa-member-document` instances didn't exist in the live database led
to this — a structural gap, not a per-community data problem.

**Status: reported, not fixed. No code changed. This document is evidence only.**

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

## Open questions for the user, not decided here

1. Is this a real gap that needs a fix — a server-side seed/install path invoked once when a
   community is first opened against the remote engine — or is local-only seeding intentional
   (seed data is a dev/demo convenience, and real communities are expected to start empty and be
   populated by real member activity)?
2. If it needs fixing: does seeding belong in the app (call `createInstance` once per seed on first
   remote open, mirroring what the local path already does) or in workflow-service itself (a
   community-install-time seed endpoint, closer to how `installCommunityPackage` already handles
   role/permission derivation in App Access)?
3. Given the scope — every community, not just Cedar — should this be prioritized above the smaller
   document-upload ticket it was discovered under, since fixing seeding would make that ticket
   (and probably several other "why is this empty" observations from this session) resolve
   naturally?

## Scope note

No code was changed. No community `*.jsonc` was touched. No tracker row was closed or reopened.
