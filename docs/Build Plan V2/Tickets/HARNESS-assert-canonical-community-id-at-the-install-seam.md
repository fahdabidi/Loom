# HARNESS — stop rewriting the package's canonical community id, and migrate the six stale catalog ids

**Status:** written 2026-10-05, **NOT dispatched**.
**Route:** `data/call_implementation_agent.sh --fresh`. Confirm the `Mode: fresh session` line.
**Scoped by** `data/call_root_cause_agent.sh` (session key `b25-canonical-community-id`), whose
diagnosis I then verified line by line myself — every claim below is checked, not quoted.

## Evidence this comes from

A device capture at HEAD `e2c63f0d` (instrumented APK, live backend, `LOOM_BINDING … mode=remote
… status=200`): `exit=0`, `screenshotStatus=complete`, `workflows=17`, `b25Proven=0/16`,
`screenshots=5/5` at 143–312 KB with zero zero-byte, zero refused frames, canonical `Evidence/`
untouched. **8 of the 11 `row_execution_failed` rows carried one identical reason:**

    Remote Loom auth is configured for canonical community "community_book_club" but neither
    listFanCommunities nor LOOM_COMMUNITY_GROUP_IDS provides an App Access group id for it.

## The mechanism — verified, not inferred

The harness **overwrites the shipped package's correct canonical id with a stale catalog value**
while building the sideload fixture, and everything downstream then runs under the stale id:

| Step | Site | What happens |
|---|---|---|
| 1 | `test/workflow_ui_test_harness.dart:2966` | `..['communityId'] = target.communityId` stamps the catalog's `community_book_club` over the package's `community_neighborhood_book_club` |
| 2 | `loom_demo_local_backend.dart:222` | the importer reads that value into `LocalInstalledCommunity.communityId` |
| 3 | `part01_local_extension_screen.dart:~530` then `part25_engine_native_community_store.dart:298` | it is carried into the remote engine factory verbatim — there is no translation layer |
| 4 | `part39_remote_auth_api.dart:76-78` | `fallbackGroupIdForCommunity(communityId)` misses, because the `part40` map is keyed on the **backend's** ids, and `_fallbackGroupId` throws the error above |

**The catalog is half-migrated:** its `extensionId` values were updated to shipped values while its
`communityId` values kept legacy demo ones. Six of ten disagree with the deployed backend, which I
read from `workflow_instances`:

| catalog (stale) | backend (correct) | catalog line |
|---|---|---|
| `community_ad_off` | `community_ad_free_community` | `part15:521` |
| `community_book_club` | `community_neighborhood_book_club` | `part15:442` |
| `community_export_migration` | `community_data_portability` | `part15:530` |
| `community_hoa` | `community_cedar_commons_hoa` | `part15:464` |
| `community_platform_social` | `community_member_social_space` | `part15:512` |
| `community_youth_soccer` | `community_riverside_youth_soccer` | `part15:451` |

The four that work — garden (`:429`), mosque (`:477`), chess (`:490`), camera (`:499`) — match by
**naming coincidence**, not because anything was wired correctly. Treat a coincidental match as
unverified, never as a control.

**`LoomExperienceDefinition.communityId` documents itself as the "Canonical server-side
identifier"** (`part11_shell_models.dart:1470-1474`), so the stale values violate their own
field's own contract. The corruption was invisible locally because the local engine namespaces on
`extensionId` (`part25:160`); the value only became load-bearing when the remote path began
consuming it.

## PRODUCTION IS NOT AFFECTED — do not treat this as a live incident

Verified independently: `preloadBundledExampleCommunities` (`part15:596-665`) installs the
byte-identical bundled JSONC and reads all identity from it, using `target.extensionId` only for
registry lookup. The bundled Book Club asset declares `community_neighborhood_book_club`. The
corruption is confined to the **test-harness install seam** — capture and the in-process suites.

## The change

**Three artifacts must move in ONE commit.** `_assertB25AssetCoversTargets`
(`integration_test/workflow_ui_evidence_test.dart:1798-1814`) requires every evidence target's
`communityId` to appear in the bundled asset's rows, so fixing the catalog alone fails all six
row lookups before any walkthrough starts:

1. The six stale literals in `part15_evidence_catalog.dart` (lines **442, 451, 464, 512, 521,
   530**) become the backend's ids.
2. The six matching literals in `loom_ux_judges/lib/b25_product_doc_interaction_models.dart`
   (`b25ProductCommunitySources`, lines **60, 74, 88, 109, 116, 123**).
3. Regenerate the asset with `bin/generate_b25_interaction_model_asset.dart`.

**Then convert the corruption site into a gate.** Replace the overwrite at `harness:2966` with an
assertion that the shipped package's `communityId` **equals** `target.communityId`, failing loudly
and naming both values on mismatch. **Delete the comment above it** — its premise ("the shipped
soccer corpus uses a different communityId") died with the legacy fixtures, and leaving it invites
the next reader to restore the overwrite.

**There is a SECOND site, and my own first grep missed it:** `harness:3138-3139`
(`_writeMetadataEvidencePackagePair`) fabricates a package using `target.communityId` as a map
literal, so a search for `['communityId']` does not find it. Fix both.

A silent "normalization" is how this stayed invisible. **When two artifacts must share an id,
assert parity at the seam rather than copying one over the other.**

## Tests that assert the stale values — update them, do not weaken them

In `loom_ux_judges`: `b25_product_doc_interaction_models_test.dart` (expected-count maps keyed by
the stale ids), `b25_evidence_accumulation_test.dart:39`,
`b25_capture_package_provenance_test.dart`. Each new expected value must be right because the
backend genuinely uses that id — not because it makes a suite green.

## DELIBERATELY OUT OF SCOPE — do not rename these

`loom_seed_data` (`community_registry_seed_data.dart:28`,
`community_foundation_seed_data.dart:14`), `loom_app_shell/test/a6_app_shell_components_test.dart`,
`loom_demo_local_backend/test/a6_local_backend_test.dart`, `b1a_local_workflow_test.dart`, the five
`tool/generate_*_package.dart` scripts, and the workflow-service README. These are self-contained
legacy-demo fixtures with **no backend join**, and the generator ids are *correct relative to
their own purpose* (hydrating the legacy demo shell). Renaming them is churn that risks breaking a
working path.

## One consequence to record, not to fix

Committed B25 evidence manifests record `communityId` from the traversal record
(`workflow_ui_evidence_test.dart:601`), so pre-fix and post-fix manifests disagree on that field
for six communities. `check_b25_status.sh` keys on live-write manifests and workflow ids, not this
field, so **the bar is unaffected** — but say in the commit message that the value changed meaning
on this date, so nobody later joins old manifests on it.

## Scope limit

Do **not** attempt the three Garden `row_execution_failed` rows (`garden-event-rsvp`,
`garden-volunteer-shift`, `plant-exchange-submission`, all reason `No element`), the remaining
`actor-identity-picker-button` stall, or the three `blocked_by_arrangement` rows. Those are
separate causes and are not this ticket. If one of them fails while you work, record it and
continue — do not let it take down the rows this ticket is about.

## Verification

- All five suites, **sequentially**, skip counts read before pass counts: demo **299** (0 failed,
  0 skipped), app shell **448** (+2), judges **525**, engine **345** (+1, BOTH Postgres credential
  sets), service **168** (+1, the one skip being App Access and **not** PostgreSQL).
  `b25_capture_prebuilt_binary_test.dart` is flaky about 1 run in 3 with a rotating test name —
  confirm a `TimeoutException` and that the file passes isolated before believing it, and note that
  its assertions are about a **spawned subprocess exit code**, so a starved child can produce a
  failed `expect` rather than a timeout.
- `flutter analyze` on the demo app: **3** pre-existing issues, taken from the tool's own
  `N issues found` line, with the working directory stated alongside the number.
- **A/B the new parity assertion before believing it**: neutralise only the assertion and confirm a
  mismatching package makes it fail, then restore and `cmp`-verify byte identity. A test that passes
  against both the fixed and unfixed code proves nothing.
- **Emit `<<<SUITES_RUN: ...>>>`.** The dispatcher refuses a reply without it and exits 2;
  `NOT_RUN(reason)` is a correct and expected entry for anything you genuinely could not run.
