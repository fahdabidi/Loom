# Phase B9 - UX Decisions

Purpose: document the UX research, extracted patterns, decisions, implementation impacts, workflow
walkthrough, and open tradeoffs for arbitrary local-demo package ingestion in the Demo App loader.

## Reference Sources Reviewed

| Source | Surface reviewed | Why it applies | Patterns observed | Applicability / gaps | Review date |
| --- | --- | --- | --- | --- | --- |
| Phase B1a local loader UX decisions | Add Community, local path entry, validation errors, duplicate import | B9 extends the same local-demo loader from fixture-backed import to arbitrary package import. | Separate file selection from validation/install; display blocking errors inline; keep local-demo labels explicit. | B1a did not require parsed package metadata to drive installed content. | 2026-06-09 |
| A6 Demo App widget tests | Empty state, Add Community CTA, card render, open action | B9 must preserve the same first-run app flow while replacing hardcoded package data. | Empty state remains simple; install status is visible after import; card is the primary confirmation. | Widget tests are functional, not full visual QA. | 2026-06-09 |
| Skill local-demo package examples | Extension/init JSON examples and bundled branding fields | The owner wants arbitrary Skill output to be loadable by the app. | The package pair is easier to inspect/debug when metadata is explicit and file-backed. | True archive extraction and asset bytes are deferred. | 2026-06-09 |
| Build Tracker gate convention | Commit, manifest, phase gate, WSL-only tooling | B9 changes the execution promise after B8 and needs its own completion evidence. | Every new workflow gets a phase doc, API review, UX decision, manifest rows, tests, tracker status, and commit. | Tracker must be extended past B8. | 2026-06-09 |

## UX Patterns Extracted

| Pattern | What B9 applies |
| --- | --- |
| The selected file contents are the source of truth. | The installed card must display the arbitrary community from the selected package, not a sample fixture. |
| Validation errors stay local to the loader. | Missing files, bad suffixes, mismatched IDs, and parse failures should appear before the dialog closes. |
| The card confirms import success. | The imported community name, extension ID, and card identity prove the local fake backend has accepted the package. |
| Keep local-demo trust boundary visible. | The flow remains explicitly local and file-backed, not a hosted publish or marketplace install. |
| Preserve repeatability. | Tests create package files from known JSON so Skill debugging can reproduce the same package pair. |

## Key UX Decisions

| Decision | Rationale | Affected surface | Covering test |
| --- | --- | --- | --- |
| Do not auto-install default Book Club files. | Arbitrary Skill output is the target workflow; defaults can hide parser failures. | Add Community loader | `vt_demo-app_arbitrary-local-extension-loads-card` |
| Keep path fields for B9 instead of adding a platform file picker. | Widget tests can validate local/emulator paths deterministically; native picker automation can come later. | Loader dialog | `vt_demo-app_local-loader-opens` |
| Show backend parse errors as loader errors. | The user needs immediate correction when a selected file is invalid. | Loader dialog | `vt_demo-app_local-loader-invalid-extension-error` |
| Show imported arbitrary community card immediately after install. | The card is the owner-visible proof that parsed metadata was consumed. | Community list | `vt_demo-app_arbitrary-local-extension-loads-card` |
| Open the parsed extension ID through App Shell. | Validates the loader did not just render a card; it can open the selected arbitrary extension. | App Shell runtime | `wf_arbitrary-local-package-ingestion` |

## Key Implementation Decisions

| Decision | Impact | Owner | Covering test |
| --- | --- | --- | --- |
| Add file-backed parser APIs to Local In-App Backend. | Demo App no longer owns package metadata or fixture substitution. | local-in-app-backend | `vt_fake-backend_parse-arbitrary-local-package-pair` |
| Keep direct JSON reading behind locked package suffixes. | Proves arbitrary package semantics now while leaving true zip extraction as a later package-builder hardening task. | local-in-app-backend | `wf_arbitrary-local-package-ingestion` |
| Accept branding at top level or under `branding`. | Existing examples and future Skill output can both load. | initialization-package-schema | `vt_fake-backend_import-arbitrary-package-pair` |
| Update widget tests to enter temp package paths. | Prevents default paths from accidentally hiding local file ingest failures. | loom-communities-demo-app | `vt_demo-app_arbitrary-local-extension-loads-card` |

## Workflow Walkthrough

| Step | User goal / action | Screen or state | Owner | UX decision applied | Covering test |
| --- | --- | --- | --- | --- | --- |
| 1 | Start from a clean Demo App. | Empty state shows no installed communities. | loom-communities-demo-app | Preserve first-run clarity. | `vt_demo-app_empty-community-state` |
| 2 | Choose Add Community. | Loader dialog opens with extension/init path fields. | loom-communities-demo-app | Keep local-demo path selection explicit. | `vt_demo-app_local-loader-opens` |
| 3 | Enter arbitrary package paths. | Loader accepts paths ending in locked package suffixes. | local-in-app-backend | Selected files are source of truth. | `vt_fake-backend_local-package-pair-validation` |
| 4 | Validate and install. | Backend parses files, verifies matching extension IDs, imports seed references and branding. | local-in-app-backend | Parse errors block install. | `vt_fake-backend_parse-arbitrary-local-package-pair` |
| 5 | Confirm install. | Card appears with arbitrary community name and extension ID. | community-card | Card confirms parsed metadata. | `vt_demo-app_arbitrary-local-extension-loads-card` |
| 6 | Open the community. | App Shell opens `local:<extension-id>@latest`. | app-shell-runtime | Open parsed extension ID. | `wf_arbitrary-local-package-ingestion` |

## Open Questions / Tradeoffs

| Question | Options | Recommendation | Owner | Resolution phase |
| --- | --- | --- | --- | --- |
| When should true zip archive parsing replace direct JSON reads? | B9 now, B10, package-builder hardening phase. | Keep JSON test payloads for B9; add archive extraction when package builder emits binary zips. | extension-package-validator | B10+ |
| Should the Demo App add a native file picker? | Path fields only, native picker only, both. | Keep path fields for deterministic tests; add picker after emulator/device automation is ready. | loom-communities-demo-app | App polish phase |
| How strict should schema diagnostics be? | First missing-field error, all-field validation report, package validator report link. | Add richer validator diagnostics when package builder exists. | initialization-package-schema | B10+ |
