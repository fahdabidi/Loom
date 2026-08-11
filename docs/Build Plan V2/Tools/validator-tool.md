# Community package validator — the JSON-grammar guard

## What it is

A **deterministic** (no LLM) structural validator for engine-native workflow JSON packages — the guard every
authored artifact must clear before it's treated as real. Two entry points over the same underlying logic:

- **CLI**: `app/packages/tooling/loom_ux_judges/bin/community_package_validator.dart`
- **HTTP server**: `app/packages/tooling/loom_ux_judges/bin/validator_server.dart`, backing
  `lib/src/validator/validator_http_server.dart` — the same validator exposed as an HTTP service, used as a
  live Custom GPT Action for the zero-tool-access authoring channel (see
  `community-authoring-skill-tool.md`).

Both wrap `CommunityPackageValidator` (`lib/src/validator/community_package_validator.dart`) and the deeper
per-workflow grammar checks in `lib/src/validator/workflow_validator.dart`. JSONC input (comments allowed) is
supported via a string-aware comment stripper (`lib/src/validator/jsonc.dart`) that preserves `//` inside
string literals — e.g. a `gs://` URL in a field value won't be mistaken for a comment.

## CLI usage

```bash
dart run loom_ux_judges:community_package_validator --package <file-or-dir> [--output <json>] [--warnings-as-errors]
```
- `--package` accepts either a single `.json`/`.jsonc` file or a directory (every `.json`/`.jsonc` file in it
  is validated).
- `--output <path>` additionally writes the full JSON report to a file (stdout always gets it too).
- `--warnings-as-errors` makes the process exit non-zero if *any* warning is present, not just errors — use
  this in a CI gate once your project's baseline is warning-clean; leave it off during normal authoring so
  warnings stay advisory.
- Exit code: `0` if the package passed (no errors, and no warnings if `--warnings-as-errors` was given); `1`
  otherwise, with every finding printed to stderr as `ERROR: <finding>` / `WARNING: <finding>`.

## HTTP server usage

```bash
dart run loom_ux_judges:validator_server [--port <port>]   # default 8787
```
Routes:
- `GET /health` — liveness check.
- `POST /validate` — body is the raw community package JSON/JSONC; returns the same `ValidationReport` JSON
  the CLI prints.
- `POST /package` — same input; returns a downloadable, installable `.loom-extension.zip`/`.loom-init.zip`
  pair built by `lib/src/validator/package_builder.dart` (plain JSON text under a `.zip` suffix, matching the
  real app installer's own fallback parsing — not a real compressed archive).
- `POST /package.json` — same input; returns the same validate+build pair as one JSON response instead of a
  binary download.

This is what backs the live Custom GPT Action for the external authoring channel — see
`community-authoring-skill-tool.md`. If you're standing this up behind a tunnel (Cloudflare Tunnel, ngrok,
etc.) for an external LLM provider to call, point its Action config at `/validate` (structural check) and
`/package`/`/package.json` (build-and-download) as two separate operations, matching this project's own
`chatgpt-upload/` Custom GPT Action wiring.

## What it checks — representative rule set

`workflow_validator.dart` runs dozens of named structural checks; every finding carries a `type` string
naming the exact rule, so a finding is always machine-attributable, not just prose. Representative examples
(not exhaustive — read the source for the full current list):

| Category | Example rule types |
|---|---|
| Dangling references | `dangling_related_aggregate_workflow_type`, `dangling_related_instance_field`, `dangling_response_table_workflow_type`, `dangling_linked_workflow_id`, `dangling_allowed_persona_id`, `dangling_instance_data_key`, `dangling_create_instance_target`, `dangling_transition_related_workflow_type` |
| Formula correctness | `circular_formula_dependency`, `invalid_formula_syntax`, `unknown_formula_field`, `unknown_formula_function` |
| State-machine health | `stuck_state`, `unreachable_state`, `no_render_binding_for_reachable_state` (a state reachable by a real transition path has no UI binding that would ever surface it) |
| Guard/role correctness | `dead_role_binding` (a role referenced in a binding that no transition/guard ever grants), `actor_equals_field_on_list_type` (a guard shape that's structurally meaningless against a list-typed field) |
| Recurrence | `missing_recurrence_anchor_field`, `dangling_recurrence_anchor_field`, `invalid_recurrence_anchor_field_type`, `missing_recurrence_rule` |
| Effect correctness | `unknown_effect_op`, `computed_field_written_by_effect` (an effect tries to write a field that's actually formula-derived, which would be silently overwritten on the next recompute) |

Findings are split `isWarning: true/false` — errors block a package from being considered valid (`exit 1`,
even without `--warnings-as-errors`); warnings are advisory (a real but non-blocking smell — e.g. a workflow
that's structurally valid but omits a recommended field). Check `report.passed` (errors-only) vs.
`report.warnings` (the advisory list) if you're consuming the JSON output programmatically rather than
via CLI exit code.

## Running against every existing package (the "did I regress anything else" check)

Any change to `workflow_validator.dart`'s rule set, or to a shared rendering/data-model file the validator's
own logic depends on, should be re-run against **every already-shipped package**, not just a new fixture —
this is the validator-specific instance of the general Regression Impact Judge discipline
(`regression-impact-judge-tool.md`):

```bash
dart run loom_ux_judges:community_package_validator --package docs/references/communities/
```
(pointing `--package` at a directory validates every `.jsonc` file in it in one pass). Confirm zero new
errors, and that any new warning appears only where the underlying condition genuinely changed — not as a
false positive against packages that were already correct.

## Extending the validator with a new rule

Add a new check function in `workflow_validator.dart` following the existing pattern (walk the parsed
package, push a `ValidationFinding(type: '<new_rule_name>', ..., isWarning: true/false)` for each violation
found), then re-run the full existing package set above to confirm no false positives before landing it.
Prefer shipping a new rule as `isWarning: true` first against a codebase with pre-existing packages that
might violate it — promote to a hard error only once the existing package set is confirmed clean against it,
mirroring the precedent already set in this project (several rules here — e.g. anything gating on a
not-yet-universally-adopted field — shipped warning-first, deliberately).
