# Loom — working rules

## Infrastructure is recoverable; recover it and keep going

**Never stop work because the Loom VM is unreachable.** Symptoms: ssh times out during banner
exchange, `VBoxManage guestcontrol` refuses a session ("current status is: starting"), console
screenshot blank. The VM can still report `running` while sshd cannot complete a handshake —
that is resource exhaustion, not a decision point.

Recover it:

    docs/Build Plan V2/Tools/code/loom-vm.ps1 stop        # ACPI; may time out
    docs/Build Plan V2/Tools/code/loom-vm.ps1 poweroff    # if stop times out
    docs/Build Plan V2/Tools/code/loom-vm.ps1 start

Then wait for ssh, re-arm the loop (`enabled=1`, push `expires_at` forward in
`data/loops/v4final.loop`), and continue. Always go through `loom-vm.ps1` — it is hard-locked
to `ubuntu-24.04.4-loom`, which prevents targeting the unrelated `Ubuntu-24.04.4` VM.

Rebooting a dev VM whose emulator is wedged is routine maintenance. Do not wait for a human.

## The Android emulator belongs on Windows, not in the VM

**The VM has no AVD any more.** `loom_demo` was deleted 2026-08-24 (1.7 GB reclaimed) and the
VM is now a pure dispatch/build host. Do not recreate an emulator there: it wedged the whole VM
twice in one day, and costs ~70% CPU even idle, which roughly quadruples Flutter suite times.
Captures run on Windows.

After a VM reboot `/tmp` is cleared and the **validator service on :8787 does not restart
itself**. Bring it back with
`cd ~/Loom/app && dart run packages/tooling/loom_ux_judges/bin/validator_server.dart`.

**`k3s` is `disabled`, so the whole backend stack is down after any VM restart.** All five
services — app-access, fan-passport, keycloak, postgres, workflow-service — are deployed in the
`loom` namespace and come straight back, but nothing starts them. `sudo systemctl start k3s`, then
wait for `kubectl get pods -n loom` to reach `1/1`; readiness probes take a couple of minutes after
a cold start. This is why the backend looked unbuilt: it was deployed and simply not running.

Tests that need Postgres want `127.0.0.1:15432`, so they also need
`kubectl port-forward -n loom svc/postgres 15432:5432`, and credentials from the
`postgres-credentials` secret. Those tests **skip silently** without them, which is worse than
failing — a green suite that skipped its only real integration test proves nothing.

Windows has **WHPX** hardware acceleration (`emulator -accel-check` reports "WHPX is installed
and usable"), because the host hypervisor is enabled. That same hypervisor is why the VM cannot
have KVM. Measured 2026-08-24: **72 seconds to boot on Windows** versus 10–20 minutes in the VM,
which also failed four times in one day.

Windows SDK lives at `C:\Android\Sdk`, AVD `loom_win`, configured 1080x2400 to match the VM's
retired `loom_demo`.

**`JAVA_HOME` is `C:\Android\jdk\jdk-17.0.20.1+1`, not `C:\Android\jdk`.** The version directory
is nested one level down, and pointing at the parent fails the Gradle build with "JAVA_HOME is set
to an invalid directory" — which reads like a missing JDK rather than a wrong path. A full APK
build needs all three: `PATH` with `C:\Android\flutter\bin`, that `JAVA_HOME`, and
`ANDROID_SDK_ROOT=C:\Android\Sdk`.

An idle KVM-less emulator costs ~70% CPU on the VM and roughly quadruples Flutter suite times —
a suite TIMEOUT under that load is environmental. Re-run the single test in isolation before
calling it a regression. A failed `expect` is a different matter.

## Evidence rules

- `*.png` is gitignored: screenshots are transient. **Only a committed manifest is durable.** A
  capture run that does not commit its manifest has proven nothing.
- Never match product vocabulary by substring. `"Not attending"` contains `attend`;
  `"Join waitlist"` contains `wait`. Match on word boundaries, and never let a span claimed by an
  ALTERNATE term also count as a PRIMARY one.
- Process checks lie in both directions: `pgrep -c qemu-system-x86_64` returns 0 when it IS
  running (15-char `comm` truncation), and `pgrep -fc` returns 1 when nothing is (it matches its
  own command line). Use `adb devices` plus a bracketed `pgrep -fc '[q]emu...'`.

## Instrument the silence before theorising about it

Five explanations for one walkthrough stall were wrong, each reasoned from a symptom — a
screenshot, a process state, an agent's illustrative example. The cause only surfaced after the
run was made to report what it was waiting for. **Treat only text a system emitted about itself
as evidence**; example output inside an agent's report is prose, not telemetry.

## Standing constraints

- Community JSON is authored only by the Skill. Copy/relocate is allowed; hand-editing is not.
- The product doc is upstream of the JSON: the Skill designs the doc, then derives the package.
- Application code changes go through `data/call_implementation_agent.sh`.
- UX judging runs on Claude Sonnet (`data/call_ux_judge_agent.sh`) and live walkthroughs on
  Claude Opus (`data/call_live_verification_agent.sh`) — the DeepSeek gateway is text-only and
  refuses images, which a UX judge fundamentally needs.

## Autonomous mode — how to run the tracker without being asked

Armed 2026-08-27. These are the patterns that actually held up over the preceding week; each one is
here because ignoring it cost a rework.

### Build the real thing, or declare honestly that it is missing

**No placeholder values, ever.** A fabricated checksum, a stubbed receipt id, an effect that `set`s
`"pending"` — each looks real and is therefore worse than an empty field. The whole export-checksum
gap stayed invisible for weeks because a field claimed a writer it never had.

**No incomplete workflows.** A capability the product doc promises must reach a live end: a real
writer, a real consumer, a reachable terminal state. If it cannot, say so in the gaps section and
leave the field visibly unwritten rather than papering it.

**Prefer building the service to widening the grammar.** A thing the platform can compute belongs to
the platform, exposed as an API — not to an expression in a package. That is why formulas lost the
reminder case and `reminder` gained a declarative block.

### Whose hands touch what

| Change | Who does it |
| --- | --- |
| Application/Dart/backend code | `data/call_implementation_agent.sh` — **never** hand-edit |
| Community `*.jsonc` | the Skill only, via `data/call_skill_authoring_agent.sh`; copy its output byte-identically. Files are `chmod 444`; lift, copy, restore |
| Product docs, reference docs, Skill instructions | me, directly |
| Root-causing a stubborn defect | `data/call_root_cause_agent.sh` |

**Pass `--fresh` unless you mean to continue the same work.** `call_implementation_agent.sh`
defaults to `resume --last` — it hardcodes that, and nothing checks whether resuming is appropriate:
no session-age test, no staleness check, no cache inspection. The choice is entirely the caller's, so
not passing the flag IS a choice, and it silently carries the previous ticket's context into an
unrelated one.

- **`--fresh`** for a new ticket. This is the normal case.
- **resume** (omit the flag) only when the dispatch genuinely continues the previous one — a retry
  after a crash, or a follow-up that should remember what the last attempt already did. Say so in the
  ticket when you rely on it.

Measured 2026-08-27: seven consecutive dispatches ran `resume --last` because the flag was omitted,
and unrelated fan-profile context surfaced in a checksum ticket. Nothing broke, but the logs reached
3–5 MB each and the agent was reasoning with a context it had no reason to hold.
| UX judging (Sonnet, needs images) | `data/call_ux_judge_agent.sh` |
| Live walkthrough (Opus) | `data/call_live_verification_agent.sh` |

**JSON specification edits are allowed only for correctness, and only minor ones.** A grammar change
needs a reason a worked example can carry. Anything larger stops and asks.

### When the Skill produces wrong JSON, fix the Skill — with an example, not just a rule

Prose in `INSTRUCTIONS.md` is the weaker half. Add the shape to
`docs/references/reference/solved-patterns.md` in its house style — requirement shape, the
plausible-but-wrong JSON, the verified-correct JSON, the community and date it was found in — and
cite a live community that already does it right. The Skill learns by matching shapes. A rule with no
shape to match leaves it inferring, and it can infer a destructive reading: "the sweep ignores this
formula" became "delete the field and the member's chosen offset with it".

Never write a community-specific instruction into a dispatch prompt. If one community needs telling,
every future one does too, and that belongs in the reference materials.

### Verify with your own oracle, never the agent's report

Re-derive expected values from the spec and the shipped package; do not hand a dispatch the answer
and do not accept its summary. For a regenerated package that means, from your own shell: `POST
/validate`, plus a field-by-field diff against what shipped confirming identifiers, roles, tabs,
workflows, reminder blocks and seeds all survived.

**Deletion is invisible in a validator run.** A package that quietly lost a feature and one that
correctly gained a wire produce identical reports — the validator counts what is declared, and only
the product doc says what is owed. Diff against the previous package, always.

Grep every dispatch diff for weakened assertions — changed `hasLength(N)`, `expect(…, N)`,
`findsNWidgets(N)` — and confirm each new number is right because the package genuinely differs.

### The five suites, and their baselines

There are **five**, and the demo app is the one that gets forgotten — it was omitted from a previous
migration too, and a Chess regeneration broke it for a full day in 2026-08 because I was running the
other four and calling that "the suites".

| Suite | Path | Baseline (2026-08-28) |
| --- | --- | ---: |
| UX judges | `app/packages/tooling/loom_ux_judges` | 444 |
| App shell | `app/packages/core/loom_communities_app_shell` | 318 (+2 skipped) |
| Workflow engine | `app/packages/core/loom_workflow_engine` | 312 (+4 skipped) |
| Workflow service | `app/packages/core/loom_workflow_service` | 84 (+5 skipped) |
| Demo app | `app/apps/loom_communities_demo` | 160 |

Run all five after installing a regenerated community package. The demo app renders the shipped
packages, so it is precisely the suite a package change can break, and precisely the one that looks
skippable because the change was "just JSON".

Update these numbers when a suite legitimately grows; a baseline nobody maintains stops being
evidence.

### Ordering rules that have bitten

- **A new validator finding code is a documentation change first.** `05-validation.md` is hard-locked
  and a conformance test requires every emitted code to be listed there, so register the code (and
  its bundle mirror) before dispatching the rule, or the agent is blocked through no fault of its own.
- **The validator server on `:8787` is not the test-suite validator.** A green suite does not mean the
  long-running server has your rule; it does not restart itself.
- **Push before any reset**, and re-run the suites yourself after installing package output.
- **Commit a verified package immediately.** An uncommitted correct package is one stray command from
  gone: `git checkout -- .` while cleaning up after a mis-invoked dispatch silently reverted a Cedar
  install in 2026-08, and the next agent then reported the file as missing its guard — correctly, and
  confusingly, because I had destroyed it myself.
- **Read the `Mode:` line the implementation script prints.** It says `fresh session` or
  `resume --last`, and it is the only confirmation `--fresh` was honoured — the flag is `$2`, and the
  script takes no label argument, unlike the Skill dispatcher.

### The end of the line, not the middle

The UX judge and the live walkthrough are the **final polish**, run once all backend services are
wired and integrated — not as progress checks along the way. The production bar is the B25 addendum
table: 79 rows, each proven by live walkthrough *and* UX judge.
