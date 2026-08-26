# Bespoke create vocabulary status — BLOCKED

## Outcome

No vocabulary, generated artifact, community package, or live catalog entry was
changed. The only repository change in this dispatch is this status report.

The requested source change cannot be made while preserving the required test
suite and the standing rule that `docs/references/**/*.md` is locked. The
blocking reference-document discrepancy must be resolved by the owner of that
document (or this dispatch must receive an explicit exception) before the
source-only change can proceed.

## Blocking finding

`ArchetypeResolver.bespokeVocabularies` and the locked
`docs/references/reference/permissions.md` currently agree that the following
four families do **not** contain `create`:

| Family | Locked table starts at | Current resolver contains `create` |
| --- | ---: | --- |
| `equipment-loan` | `permissions.md:181` | no |
| `documentLibrary` | `permissions.md:200` | no |
| `exportWizard` | `permissions.md:224` | no |
| `searchAiAnswer` | `permissions.md:283` | no |

This is not merely an informational-document difference. The judges test
`test/archetype_resolver_spec_sync_test.dart` parses each §4 table and asserts
set equality with `ArchetypeResolver.bespokeVocabularies` for every family.
Adding the four source entries specified by the ticket would therefore create
four source-vs-document failures. Making that suite green would require adding
the same rows to the locked document, which the standing rules expressly
prohibit and instruct the dispatch to report rather than correct.

## Vocabulary baseline

The checked-in generated vocabulary is current for the unchanged resolver:

```text
$ cd app/packages/tooling/loom_ux_judges
$ dart run bin/generate_permissions_vocabulary.dart --check
permissions-vocabulary.json is up to date.
```

The generated artifact has **97/97** permission ids. The four required ids are
absent:

```text
total=97
equipment_loan.create=false
document_library.create=false
export_wizard.create=false
search_ai_answer.create=false
```

The requested after-state would be 101 ids, but it was not generated: doing so
would require the blocked source change, and regenerating the artifact without
that source change would be a misleading no-op.

## Resolution capture

I captured the full `ArchetypeResolver.resolveAll` map using the existing
`ParsedCommunityPackage` parser, sorting workflow types before JSON encoding.
The capture covers all **11/11** shipped community packages and **95/95**
workflows:

| Package | Workflows |
| --- | ---: |
| AdFreeCommunity | 6 |
| CameraClub | 6 |
| CedarCommonsHOA | 7 |
| ChessClub | 8 |
| DataPortabilityCommunity | 9 |
| GardenClub | 8 |
| MasjidNur | 10 |
| MemberSocialSpace | 6 |
| NeighborhoodBookClub | 12 |
| Phase1_TabletopClub | 13 |
| RiversideYouthSoccer | 10 |

Because no source change was permitted, the only available second capture is a
no-change control. It is **not** evidence for the ticket's requested
before/after-change acceptance criterion; no honest after-change map or diff
exists. It does verify that the capture covers the same complete corpus on both
runs.

```text
$ sha256sum /tmp/loom-resolution-before.json /tmp/loom-resolution-after-no-change.json
af9082459227d3fa3596210515e4d020b093ee6f248cbcf0068b84483222ba41  /tmp/loom-resolution-before.json
af9082459227d3fa3596210515e4d020b093ee6f248cbcf0068b84483222ba41  /tmp/loom-resolution-after-no-change.json

$ diff -u /tmp/loom-resolution-before.json /tmp/loom-resolution-after-no-change.json
```

The final `diff` command emitted no lines (verbatim empty diff). A real
before/after diff across all 11 packages remains unperformed because the
candidate source revision does not exist.

## Verification run

| Suite | Command | Result |
| --- | --- | --- |
| UX judges | `cd app/packages/tooling/loom_ux_judges && flutter test` | **432/432 passed**, 0 skipped, 0 failed |

The judges suite was executed three times during the investigation; every run
exited successfully. The authoritative JSON-reporter count above is 432 total,
matching the expected suite total.

The app-shell, workflow-engine, workflow-service, provisioning, and demo suites
were not run. They cannot validate a source change that the locked-document
gate prevents; reporting them as post-change verification would be false
evidence.

## Not done

- The four `create` source entries were not added.
- `permissions-vocabulary.json` was not regenerated; it was only checked.
- The provisioning plan's four vocabulary absences were not changed or
  re-verified against a regenerated artifact.
- No hand-added live App Access catalog entries were touched, as required by
  the ticket's follow-up-only boundary.

## Required next decision

Correct the four §4 action tables in the locked permissions reference through
the documentation-owner workflow, or explicitly authorize a narrowly scoped
exception. Once the human-facing source of truth and its sync test can contain
the same four `create` actions, this ticket can make the resolver-only data
change, regenerate the generated artifact to 101 ids, capture the real
before/after resolution diff, and verify the provisioning plan against it.
