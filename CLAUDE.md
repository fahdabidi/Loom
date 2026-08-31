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

### The build and the cluster share one machine

The k3s cluster runs on the same 8-core VM that builds images and hosts dispatches. A Maven or
Docker build starves it: on 2026-08-30 an `app-access` image build stalled the node hard enough
that **every pod's probes failed at once** — app-access, fan-passport, keycloak and minio all
logged `context deadline exceeded` within the same minute, and kubelet gracefully restarted
`postgres-0`.

Two things make this worth knowing in advance:

- **A whole-node stall looks like a service bug.** The tell is that unrelated services fail
  together, and that Postgres shows `exitCode: 0, reason: Completed` — a *graceful* shutdown, not
  a crash. One service failing is a service problem; four failing at once is the node.
- **The blast radius outlives the build.** The build finishes, load returns to normal, and the
  cluster looks healthy — `kubectl get pods` shows everything `1/1 Running` with no restarts.
  Meanwhile any service holding a single long-lived DB connection is permanently broken. Check
  that services still *serve* after a heavy build, not just that they are `Running`.

Before starting a build or dispatch, check `cut -d' ' -f1-3 /proc/loadavg`. After one finishes,
re-run a real request against the stack rather than trusting pod status.

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

## Verification traps — checks that pass for the wrong reason

Every rule below cost real time on 2026-08-29/30, and they share one shape: **a signal that looked
healthy while measuring the wrong thing.** A loop whose `last_fired` advances because a dead process
consumed the tick. A validator that answers confidently from last week's grammar. A green suite over
a service whose deployed definitions predate the feature. When something looks fine, ask what the
check would show if it were broken — if the answer is "the same thing", it is not a check.

### Two dispatches in different repos still contend for one machine

The "one dispatch at a time" rule is usually explained by the shared working tree, so two dispatches
in **separate** repos look safe. They are safe for the tree and not for the box. On 2026-08-30 an
`app-access` Maven build in `~/loom-backend` and Flutter work in `~/Loom` together drove an 8-core VM
to **load 34.9**, 242 MB free, and 1.1 GB of swap in use.

The danger is not slowness. **A suite that times out under that load reads as a failure**, and an
agent may then "fix" something that was never broken, or weaken an assertion to make the timeout go
away — see the load-sensitivity note further down, which exists for the same reason.

Before starting a second dispatch, check `nproc` against `uptime`, and prefer to queue. If two are
already running, do not kill one mid-work: a killed dispatch leaves a dirty tree with no record of
what it had finished. Let them land, then verify **both** with extra care, specifically re-running
any suite the agent reported as slow or failing.

### Launch dispatches detached, and confirm they are alive

A dispatch backgrounded with plain `nohup ... &` inside an `ssh` command can die the moment the
ssh session closes -- the same command succeeded twice and died once, so treat it as a race, not a
setting. Launch with `setsid nohup ... < /dev/null &` and `disown`.

**Then check that it is actually running**, because the failure is silent and mimics a healthy
start: the wrapper prints its full banner (repo, prompt file, profile) and `codex exec` then writes
nothing at all. A dead dispatch and a slow-starting one look identical. `dispatch_health.sh` reports
`DEAD (no node process, and no exit line in the log)` -- believe it, and do not wait a further tick
hoping output appears.

    pgrep -fc "[c]odex exec"   # non-zero
    wc -c /tmp/impl_<name>.log # growing

Rule out resources before assuming a bad ticket: check `free -h` and `dmesg` for OOM kills. A
15 GB VM with 12 GB available and no OOM lines did not fail for lack of memory.

### The validator on :8787 answers happily while running last week's grammar

`call_skill_authoring_agent.sh` checks that *something* responds on :8787 and reuses it. It never
checks that it is running current code. On 2026-08-29 a Skill dispatch rejected the brand-new
`platformSource` key as `unknown_key`, three errors, and the grammar looked broken. The server had
been up since **2026-08-28 12:16**, predating the grammar entirely. Restarted, the same file
validated `pass` with zero errors.

**Restart it whenever the grammar, the validator or the engine models have changed since it started:**

    ps -o lstart= -p $(pgrep -f "[v]alidator_server" | head -1)   # older than your change? restart
    pkill -f "[v]alidator_server"
    cd ~/Loom/app && dart run packages/tooling/loom_ux_judges/bin/validator_server.dart

It takes ~60s to compile and serve, and a `setsid nohup ... &` that is not waited on can die with the
ssh session -- confirm `curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8787/health` is 200
before trusting any result.

This belongs to the same family as grep-gated commits and byte-identical doc mirrors: **a check that
passes for the wrong reason**. A stale validator does not error, it disagrees -- and its disagreement
reads exactly like a real finding against your work.

### Never `kill` by pattern — resolve the pid, then confirm what it is

A dispatch's command line contains **the entire ticket text**. So any `pgrep -f <phrase>` where the
phrase also appears in a ticket will match the running agent. On 2026-08-29 a cleanup of a duplicate
`kubectl port-forward -n loom svc/postgres 15432:5432` matched the codex process running a ticket
that quoted that exact command, and killed it. It survived only because the pid that matched was the
`npm exec` wrapper and the real agent was a child.

    pgrep -af "<pattern>"      # LOOK at the full command lines first
    ps -p <pid> -o pid,ppid,cmd   # confirm this pid is the thing you mean
    kill <pid>

Two habits that would each have prevented it: exclude the agent explicitly (`| grep -v codex`) when
searching for infrastructure processes, and never pipe a `pgrep` straight into `kill` — print the
matches, read them, then kill a specific pid.

This is the same family as the existing `pgrep` note below: **process searches match things you did
not mean, in both directions.**

### Your own command line is part of the haystack, and stale files answer for dead requests

Three checks lied on 2026-08-30, all by reporting something other than what was asked.

**`pgrep -f` matches your own echo text, not just the bracketed pattern.** The `[b]uild.sh` trick
protects the *pattern*, and does nothing about the rest of the command. This reported a live build
after both processes were confirmed dead:

    pgrep -fc "[b]uild.sh"   # returns 1
    echo "  build.sh alive: ..."   # <- THIS is what it matched

The label text contained the literal string. Same for `docker build`, `codex`, `java`. **Resolve the
pid and check it directly** — `kill -0 $PID`, `ps -p $PID -o stat=,cmd=` — and when a count disagrees
with `ps`, believe `ps`.

**A failed `curl` leaves the previous file in place.** `curl -o /tmp/out.json` writes nothing when the
connection fails, so `http=000` followed by reading `/tmp/out.json` returns *the last successful
response*, which reads exactly like a real answer. It served a workflow instance as the body of a
role deletion. **`rm -f` the output file first, or use a unique name per request**, and check the
status code before the body.

**Hung and slow look identical in one sample; they differ in a trend.** A `docker build` that had not
advanced its log in ten minutes was assumed stalled and killed. Its client CPU was climbing the whole
time — it was working, and the log was block-buffered, so a stale tail proved nothing. An earlier
build in the same session *was* genuinely stalled, and the difference was visible only as flat CPU
across two samples sixteen minutes apart. **Sample twice before concluding**, and prefer
`/proc/<pid>/stat` deltas to log mtime.

### Orphaned loop emitters steal ticks silently

`data/loop_emitter.sh` runs on **Windows**, one per Claude session, and **old ones survive the
session that started them**. On 2026-08-29 there were four: Aug 20, Aug 24, Aug 27, and the live one.

They all poll the same `data/loops/*.loop` registry. When an orphan fires it increments `fires`,
stamps `last_fired`, and writes `LOOP-FIRE` to the stdout of a **dead task nobody reads**. The live
emitter then sees a recent `last_fired`, correctly concludes the loop is not due, and stays quiet.
The tick is consumed by a corpse.

The signature is a **count mismatch**: `backend.loop` read `fires=117` while the live Monitor's
output held only 47 `LOOP-FIRE` lines. Roughly 70 ticks had been eaten. `last_fired` looks healthy
throughout, so every check of "is the loop armed" passes while nothing arrives.

    ps -ef | grep "[l]oop_emitter"        # expect exactly ONE (see the parent-pid warning below)
    kill <each orphan pid>

Check this **first** when ticks stop but the registry looks fine. Orphans also burn the `max_fires`
budget, so a loop can auto-disable having delivered a fraction of its ticks.

**Do NOT test this by the parent pid — that check is wrong on Windows.** On 2026-08-31 I diagnosed a
live emitter as orphaned because its parent process was dead, and that reasoning was invalid: Git
Bash's launcher exits immediately after exec'ing, so the innermost `loop_emitter.sh` **always** has a
dead parent. A freshly started emitter shows the same three-process shape, with the last one already
reparented seconds after a clean start:

    42908  parent=18448  claude.exe (alive)
    27196  parent=42908  bash.exe (alive)
    23396  parent=20716  DEAD          <- normal, not evidence of anything

**The two checks that do work:**

- **The count mismatch above** — registry `fires` against `LOOP-FIRE` lines in the live Monitor's
  output file. That is what found the four orphans, and it is still the first thing to run.
- **Does it survive `TaskStop` on the Monitor?** A legitimate emitter dies with its Monitor. One
  still running afterwards belongs to an earlier Monitor and is the thing to kill. This is the only
  cheap way to tell one emitter from another when they look identical in `ps`.

A gap that stays constant is old damage, not a live leak: the 2026-08-29 incident left `fires` 70
ahead of delivered ticks, and two days later it was **still exactly 70**, which is how you know
nothing further was eaten.

Note the registry lives in the **Windows** repo, not the VM's. Checking `~/Loom/data/loops` on the
VM shows a different, stale set and will tell you the loop is dead when it is not.

### Publishing definitions is not a one-time step

The backend stores a **copy** of every workflow definition, written by
`bin/publish_workflow_definitions.dart`. Change a community package and the deployed copy is stale
until you publish again. **Nothing tells you.** No test fails, no route errors, no probe goes red:
the service serves the old definition and every surface built on it looks fine.

On 2026-08-29 the 82 definitions were published, then five packages were regenerated onto the
`platformSource` grammar. The stored copies still had **zero** `platformSource` declarations, so
opaque-id minting -- built, deployed in `0.8.0`, and correct -- could never have fired. Re-publishing
took the count from 0 to 8 affected definitions, and the total stayed 82 because the publisher is an
upsert.

**Publish after any package change, before believing anything downstream of it works:**

    kubectl port-forward -n loom svc/postgres 15432:5432 &
    cd app/packages/core/loom_workflow_service
    env LOOM_POSTGRES_HOST=127.0.0.1 LOOM_POSTGRES_PORT=15432         LOOM_POSTGRES_DATABASE=loom_workflow_service LOOM_POSTGRES_USERNAME=loom         LOOM_POSTGRES_PASSWORD="$PW" dart run bin/publish_workflow_definitions.dart          # dry run
                                                                                            # then --write

Confirm the change actually landed by querying the stored JSON for the thing you added, **with a
control** — a query for something that must already be present, so a zero means absent rather than
broken.

### A search that finds nothing is not evidence of absence

Three false "it does not exist" claims in one day, each from a query that was narrower than the
question:

| Claim | Why it was wrong |
|---|---|
| "no package declares a payment id" | inventoried by **comment wording**, not field name; `receiptId` comments read differently |
| "nothing selects the remote engine factory" | `grep` was **case-sensitive**; the call is `configureEngineNativeCommunityEngineFactoryForProduction` |
| "minio has no liveness probe" | jsonpath asked for `livenessProbe.exec.command`; minio's is an **httpGet** probe |

Each produced a confident report of missing work that already existed, and two reached the user.

**Before reporting something absent, run a control** — a query in the same shape that must return a
hit. If the control also returns nothing, the query is broken, not the codebase. Prefer reading the
definition and its callers over one pattern coming back empty.

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

| Suite | Path | Baseline (2026-08-30, measured) |
| --- | --- | ---: |
| UX judges | `app/packages/tooling/loom_ux_judges` | 464 |
| App shell | `app/packages/core/loom_communities_app_shell` | 354 (+2 skipped) |
| Workflow engine | `app/packages/core/loom_workflow_engine` | 312 (+5 skipped) |
| Workflow service | `app/packages/core/loom_workflow_service` | 148 (+1 skipped, with PG credentials; 139 (+10) without) |
| Demo app | `app/apps/loom_communities_demo` | 160 |

Run all five after installing a regenerated community package. The demo app renders the shipped
packages, so it is precisely the suite a package change can break, and precisely the one that looks
skippable because the change was "just JSON".

**The skipped counts are the load-bearing part.** Both the workflow service and the engine carry
PostgreSQL integration tests that **skip silently** without `LOOM_POSTGRES_PASSWORD` and a
port-forward. On 2026-08-30 a dispatch reported the workflow service green at `139 passed, 10
skipped` — and the ten skipped included all four tests written to prove the fix that dispatch had
just built. With credentials it is `148 passed, 1 skipped`.

So read the skip count before the pass count. A suite whose skips went *up* is the shape of a green
run that proved less than the one before it. To run them for real:

    kubectl port-forward -n loom svc/postgres 15432:5432 &
    env LOOM_POSTGRES_HOST=127.0.0.1 LOOM_POSTGRES_PORT=15432 \
        LOOM_POSTGRES_DATABASE=loom_workflow_service LOOM_POSTGRES_USERNAME=loom \
        LOOM_POSTGRES_PASSWORD="$PW" dart test

The engine's four `postgres_database_integration_test.dart` cases need the same, and they are the
ones that exercise row locking and overlapping transitions.

Update these numbers when a suite legitimately grows; a baseline nobody maintains stops being
evidence.

### When writing a spec: never specify an effect without its mechanism

Twice in one session I wrote a contract that required something the contract itself made impossible
to compute, and both times an implementation agent refused rather than inventing a way.

- `platformDefault` was typed as `CommunityNotificationPreference`, which requires a `communityId`. A
  platform-wide default has no community, so satisfying the required field produced a `platform_default`
  pseudo-key. **A schema that demands an identifier for something with no identity gets a fabricated
  identifier.**
- The change feed required `resyncRequired`, which needs to know the caller's roles when the cursor was
  issued — and the request carried no such field while the response was closed with
  `additionalProperties: false`. **The effect was specified and the mechanism was not.**

Both refusals were correct and both were cheap. The failure mode when an agent *doesn't* refuse is
much worse: an endpoint that looks implemented, returns plausible values, and is wrong in a way no
test written from the same spec would catch.

So before finishing any spec, take each field that asserts something about state and ask what it is
computed *from*, and whether the contract actually carries that. If it does not, either add the input
or delete the field — a field nobody can compute is worse than an absent one, because it will be
filled in with something.

The same check applies to a field whose value must come from another service. `listNotificationPreferences`
promised an entry "for every community they belong to", and fan-passport holds no membership data at
all — `app-access` owns it. Nothing in the contract was wrong on its face; it was simply unkeepable,
and only reading the other service's schema showed that.

### Ordering rules that have bitten

- **A new validator finding code is a documentation change first.** `05-validation.md` is hard-locked
  and a conformance test requires every emitted code to be listed there, so register the code (and
  its bundle mirror) before dispatching the rule, or the agent is blocked through no fault of its own.
- **The validator server on `:8787` is not the test-suite validator.** A green suite does not mean the
  long-running server has your rule; it does not restart itself.
- **A test command piped into `grep` gates on grep, not on the tests.**
  `flutter test | grep -E "All tests|Some tests" && git commit` commits a red suite, because grep
  succeeds when it finds the words "Some tests failed". This looked like verification every time it
  was used. Redirect and check the status instead:
  `flutter test > /tmp/run.txt 2>&1; echo "exit=$?"; grep … /tmp/run.txt`
- **The finding-code conformance test runs both ways.** Every code the validator emits must be
  documented, *and* every documented code must exist. So registering a code before building its rule
  is only correct when the rule lands in the same change; register-then-commit turns the suite red.
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

## Disk hygiene — check it before it stops the VM

**A full host disk pauses the VM, and it does not look like a disk problem.** VirtualBox pauses a
guest whose backing store cannot grow. `ssh` times out exactly as it does for a wedged VM, so the
recovery instructions above appear to apply and do not work: resume succeeds, the guest writes, it
pauses again within seconds. `loom-vm.ps1 status` reporting `paused` rather than `running` is the
only thing that distinguishes the two. Check free space before power-cycling anything.

The VM's disk lives at `D:\VirtualBox\ubuntu-24.04.4-loom\ubuntu-24.04.4-loom.vdi`. **D: is not a
data drive** — it holds an old Windows installation plus that VDI, and it hit 0 bytes free on
2026-08-28.

**Check monthly, or after any long autonomous run:**

```powershell
Get-PSDrive D | Select-Object @{n='FreeGB';e={[math]::Round($_.Free/1GB,2)}}
```

Below ~20 GB, act. The VDI grows and never shrinks, so this only goes one way on its own.

### Safe to delete on the host

- Archive files anywhere on D: — `*.zip *.rar *.7z *.tar *.gz *.xz`. Freed 70 GB in one pass.
- `D:\Users\fahd_\Downloads` — everything.
- `D:\Users\fahd_\OneDrive` — an **orphaned copy** from the old install. OneDrive syncs
  `C:\Users\fahd_\OneDrive` only; verify with
  `Get-ChildItem HKCU:\SOFTWARE\Microsoft\OneDrive\Accounts | ForEach-Object { (Get-ItemProperty $_.PSPath).UserFolder }`
  before deleting, because if that ever changes, deleting there propagates to the cloud and every
  synced machine.
- The D: recycle bin: `Clear-RecycleBin -DriveLetter D -Force`.

### Needs an elevated shell, which this session does not have

`D:\Windows` (71.6 GB), `D:\Program Files` (9.7 GB) and `D:\$WINDOWS.~BT` (5.9 GB) are TrustedInstaller-owned
leftovers from an April-2024 install. `takeown` and `icacls` both fail from a normal session, and the
agent harness independently blocks `Remove-Item` on those paths. **~87 GB, and the only durable fix
short of moving the VDI.** E: has 344 GB free and G: has 3.3 TB — relocating the VDI solves this
permanently rather than repeatedly.

### Safe to delete on the VM

Do **not** touch a `/tmp/tmp.*` staging directory while an image build is running — `build.sh` copies
`~/.pub-cache` and `~/Loom/app` into one.

```bash
ls -t ~/Loom/.codex-logs/*.log | tail -n +11 | xargs -r rm -f   # keep the 10 newest
rm -rf ~/Loom/app/apps/loom_communities_demo/build              # rebuildable
docker rmi loom-workflow-service:<superseded-tags>              # keep the deployed one
docker image prune -f
```

That freed 59 GB on 2026-08-28: 94 dispatch logs, a 2.5 GB build directory, four old images.

**Cleaning the VM does not reclaim host space.** The VDI is grown, not shrunk, by guest activity —
freeing space inside the guest prevents further growth and returns nothing to D:. Only deleting on the
host, or compacting the VDI offline, moves that number.
