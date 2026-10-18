# HARNESS — a narrowed precheck writes (and destroys) manifests for phases it never ran

**Status:** written 2026-10-10, **NOT dispatched**. Auth on the VM is expired, so no dispatcher is
reachable; this ticket is ready to go the moment it is back.
**Route:** `data/call_implementation_agent.sh --fresh`. Confirm the `Mode: fresh session` line.
**Mechanism established by me, by reading the code** — this ticket is NOT scoped from a hypothesis.
CLAUDE.md recorded the effect as measured and the mechanism as **unread** (*"The plausible reading
is that the tool emits a manifest for its whole phase set regardless of `--phases`. Nobody has read
that path, so it stays a hypothesis"*). It is now read, and the hypothesis was right in substance
and **wrong in attribution**: the writer is the on-device driver, not
`b25_capture_workflow_screenshots.dart`, and the cause is one element of a set union rather than a
loop bound.

## The measured effect (2026-10-02, already recorded)

`--mode targeted-precheck --phases B12,B13` left **19 tracked files under
`docs/Build Plan V2/Evidence/` modified**, including phases never named on the command line:
`B14/workflow-ui-evidence.json` went **3097 lines → 70**, all 35 workflow rows replaced by
`"phaseOutcome": "no_workflows_recorded"`. Recovered with `git checkout --` scoped to that
directory. **Control run today: zero files under `Evidence/` currently carry that marker**, which is
consistent with that revert and means the tree is clean to start from.

## The mechanism — three sites, in order

| # | Site | What it does |
|---|---|---|
| 1 | `test_driver/workflow_ui_evidence_writer.dart:109-115` | builds `phases` as a **set union** of `requestedPhases`, the phases present in this run's own `entries`, **and every phase in `b25CommunityTraversals`** — that third element is added **unconditionally**, so a narrowed run still ends up with the full canonical phase list |
| 2 | same file, `:131-133` then `:251` and `:444` | `grouped` seeds an **empty list for every phase in that set**, the write loop iterates the whole set, and each iteration writes `${evidenceRoot}/$phase/workflow-ui-evidence.json`. An unrequested phase therefore gets a manifest with **zero workflows**, overwriting whatever was on disk |
| 3 | `b25_capture_workflow_screenshots.dart:837-850` | the capture tool then reads that fresh manifest, sees `workflows` empty, and stamps `status=fail`, `phaseOutcome=no_workflows_recorded`, `completionGateEligible=false` |

**Site 3 is correct behaviour and must not be touched.** Given an empty manifest it is right to mark
the phase failed. It is also why the staleness guard immediately above it (`:822-829`, "phase
manifest is stale") does **not** save us: the driver has already rewritten the file, so it is not
stale by the time that check runs. The defect is entirely at site 1.

## The change

Add the traversal phases **only when nothing was requested**:

    final phases = <String>{
      ...requestedPhases,
      for (final entry in entries)
        if (entry['phase'] case final String phase) phase,
    -  for (final traversal in b25CommunityTraversals)
    -    if (traversal['phase'] case final String phase) phase,
    +  if (requestedPhases.isEmpty)
    +    for (final traversal in b25CommunityTraversals)
    +      if (traversal['phase'] case final String phase) phase,
    }.toList()..sort();

**Why this cannot change `full-b25`, verified rather than assumed:** `--phases` defaults to
`_fullB25Phases.join(',')` (`b25_capture_workflow_screenshots.dart:44`) and the mode *requires*
`_samePhases(phases, _fullB25Phases)` (`:76`), so in canonical mode all nine phases are requested
and the union's third element contributes nothing already. The `isEmpty` guard also means that if
`requestedPhases` is ever empty for some other reason, behaviour falls back to exactly what ships
today — safe by construction rather than by argument.

**Keep element 2.** A phase that genuinely produced entries must still be written even if it was not
named, or a real result would be dropped. Only the unconditional canonical union goes.


## CONSEQUENCE STILL REACHES THE SURFACE — checked 2026-10-10, and the guard ASYMMETRY is the sharper finding

Applied the same check that rescoped the sibling one-row-stall ticket: a cited mechanism being intact
does not prove its consequence still lands. Here it does, and nothing mitigates it.

**The tool is meticulous about one direction and silent about the other.** It carries **three**
separate refusals to stop canonical evidence being weakened — `--phases` narrower than B12-B20
(`:79`), `--communities` filtering (`:87`), and `--shards`/`--only-shard` (`:96`) — each with error
text telling the caller to use `targeted-precheck` for *"remediation diagnostics that must not be
committed as canonical B25 evidence"*. And it labels precheck aggregates `commitEligible: false`
(`:509`, `:531`).

**Yet nothing keeps precheck output out of the canonical directory.** A search for any
mode-dependent defaulting or forcing of `evidenceRoot` returns nothing: precheck writes wherever
`--evidence-root` points, and that defaults to the canonical location. **So the tool disclaims its
output in words while writing it to the committable place** — the author plainly cared about this
exact class of mistake, and the one protection that would have prevented the 2026-10-02 data loss is
the one that is missing.

**An alternative fix shape, offered as an observation rather than a change of scope.** Defaulting
`evidenceRoot` to a scratch path whenever `mode == 'targeted-precheck'` would close the whole class,
not just the unrequested-phase instance this ticket fixes, and it would compose with the `isEmpty`
guard rather than replace it. **But it changes an existing default**, so any caller currently relying
on precheck writing to the canonical root would silently start writing elsewhere — which is its own
indistinguishable-from-success hazard. **Do not fold it into this ticket.** If it is wanted, it is a
deliberate decision with that trade stated, and the operational rule (point `--evidence-root` at a
scratch path yourself, then `git status` the Evidence directory) stays either way.

## Honesty test — it must fail against today's code

- **A writer test with `requestedPhases: ['B16']` and entries only for B16 must assert that
  `workflow-ui-evidence.json` is written for B16 and for NO other phase.** There are already writer
  tests using exactly that shape (`test/workflow_ui_evidence_writer_test.dart:46,105`), so extend
  that file rather than inventing a new harness.
- **Run it against the unfixed writer first and record the verbatim failure.** It must fail by
  finding manifests for unrequested phases. A test that passes both before and after proves nothing.
- **Add the converse, so the fix cannot become "write nothing":** with `requestedPhases` **empty**,
  every canonical phase must still be written — that is the `full-b25` path and it must stay intact.
- **A/B it:** neutralise only the `isEmpty` guard, confirm the first test fails, restore, and
  `cmp`-verify byte-identical.
- **`b12_workflow_ui_evidence_harness_test.dart:829-870` does NOT assert the behaviour this ticket
  removes — I checked, and it confirms the distinction the fix rests on.** It drives
  `requestedPhases: ['B12','B15']` with entries only for B12, and asserts that **B15** gets a
  manifest marked `no_workflows_recorded` with reason *"No workflow evidence rows were recorded for
  phase B15 (expected workflow count: 2)"*. B15 is a **requested** phase, so the union's first
  element keeps it and it is still written and still marked. **That is the designed behaviour and it
  must stay green.** Note its reason string quotes an *expected workflow count*, which comes from
  `expectedWorkflowCountByPhase` — populated per requested phase — so an unrequested phase does not
  even have one. The distinction between "requested and empty" (mark it failed) and "never
  requested" (do not touch it) is already baked into the data; this fix only makes the phase set
  agree with it. **Do not weaken this test**, and if it goes red, stop and report rather than
  editing it.

## Scope limit

Only the phase-set construction in the writer, plus its tests. Do **not** touch the capture tool's
zero-workflow marking (site 3), the staleness guard, the `targeted-precheck` argument validation, or
anything about `--evidence-root`. **And do not weaken the standing operational rule** — point
`--evidence-root` at a scratch path for diagnostics and run
`git status -- "docs/Build Plan V2/Evidence"` after every precheck. That rule stays after this fix,
because it protects against the whole class and not just this instance.

## Verification

- All five suites, **sequentially**, skip counts before pass counts: demo **319** (0 failed,
  0 skipped), app shell **448** (+2), judges **525**, engine **345** (+1, BOTH Postgres credential
  sets), service **168** (+1, the one skip being App Access and **not** PostgreSQL).
  `b25_capture_prebuilt_binary_test.dart` is flaky about 1 run in 3 with a **rotating** test name —
  confirm a `TimeoutException` and an isolated pass before believing it, and note its assertions are
  about a **spawned subprocess's exit code**, so a starved child yields a failed `expect` rather
  than a timeout.
- `flutter analyze` on the demo app: **3** pre-existing issues, taken from the tool's own
  `N issues found` line, with the working directory stated alongside the number.
- **Emit `<<<SUITES_RUN: ...>>>`.** The dispatcher refuses a reply without it and exits 2;
  `NOT_RUN(reason)` is a correct and expected entry for anything you genuinely could not run.
