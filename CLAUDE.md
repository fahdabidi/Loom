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

**A dispatch that runs the five suites does this too, and harder than a build.** On 2026-09-08 an
implementation dispatch asked to run all five suites drove the box to **load 68 on 8 cores**, made
**sshd unable to complete a handshake for roughly forty minutes**, and got `postgres-0`
**force-killed three times** (`exit=137`, restart count 6 → 8). The earlier build incident produced
one *graceful* restart; this was harder, and Keycloak went `0/1` as collateral. Everything recovered
on its own — all six pods returned `1/1`, and every row survived: 19 workflow instances, 85
definitions, 137 permissions, 425 grants.

**Two judgments from it worth reusing.**

*Do not power-cycle a VM that is merely loaded.* The documented recovery is for a **wedged** VM, and
the two look identical over ssh. What distinguishes them is cheap and host-side:
`loom-vm.ps1 status` reporting `running` (not `paused`, which means the host disk filled), Guest
Additions still answering, the TCP port still accepting, and free space on D:. All four said "loaded,
not wedged" — and rebooting would have destroyed a dispatch with eight modified files and no record
of what it had finished. It finished fine.

*Stop polling.* Each `ssh` probe adds load to the box whose load you are measuring, and under
saturation the probes time out anyway — so they cost something and return nothing. Arm one waiter
with `ServerAliveInterval` and go quiet.

**And distrust that run's test results specifically.** Postgres died three times *during* the suites,
so any PostgreSQL-backed test in that window failed environmentally. That is the exact condition in
which an agent "fixes" what was never broken. This one behaved correctly — it reported
"incomplete verifications, not green suite results" and refused to fabricate totals — but the
default assumption should be that suite numbers from a saturated box are worthless, and re-running
them yourself on a quiet box is the only real check.

## The Android emulator belongs on Windows, not in the VM

**The VM has no AVD any more.** `loom_demo` was deleted 2026-08-24 (1.7 GB reclaimed) and the
VM is now a pure dispatch/build host. Do not recreate an emulator there: it wedged the whole VM
twice in one day, and costs ~70% CPU even idle, which roughly quadruples Flutter suite times.
Captures run on Windows.

**A VM-hosted session can still drive that emulator — this section has been misread as saying it
cannot.** The emulator process must live on Windows; *talking* to it need not. A dispatch running on
the VM reaches it through the Windows adb server, and when the VM-local adb server dies mid-run the
recovery is `adb -H 192.168.56.1 -P 5037 …` rather than abandoning the run. Proven 2026-09-08 across
three B25 walkthroughs, one of which recovered exactly this way. Same shape as the APK-build lesson
below: check whether a limitation is intrinsic to the task or incidental to where it is running.

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


### Build the APK on the VM, not on Windows

Windows cannot build this app without Developer Mode: Flutter creates symlinks for plugins
(`.plugin_symlinks`) and Windows restricts symlink creation to admin or Developer Mode, so
`flutter build apk` stops with **"Building with plugins requires symlink support."** Enabling it is an
`HKLM` write, needs elevation, and is not available from an ordinary session.

**That restriction is Windows-only, and the VM has a full Android toolchain** — `flutter doctor`
reports `[✓] Android toolchain … Android SDK version 36.0.0`, with `JAVA_HOME` on Java 17, which is
what the Flutter side needs (the backend's Java 21 override belongs to `loom-backend/build.sh` only).
Linux has no symlink restriction, so the build simply works:

    ssh loom-vm '. ~/.loom-env.sh; cd ~/Loom/app/apps/loom_communities_demo && flutter build apk --debug \
      --dart-define=LOOM_PRELOAD_EXAMPLE_COMMUNITIES=true'
    ssh loom-vm 'cat ~/Loom/app/apps/loom_communities_demo/build/app/outputs/flutter-apk/app-debug.apk' > /tmp/app.apk
    "C:\Android\Sdk\platform-tools\adb.exe" install -r /tmp/app.apk

Proven 2026-08-31: built in ~5 minutes, 166,844,907 bytes, transferred byte-identical, installed to
`emulator-5554` over the stale 2026-08-11 build, launched clean with no `FATAL EXCEPTION` in logcat.

**`--dart-define=LOOM_PRELOAD_EXAMPLE_COMMUNITIES=true` is not optional, and omitting it looks like a
product bug.** `main.dart` reads the flag through `bool.fromEnvironment`, which defaults to **false**,
so an APK built without it installs and launches perfectly and then shows *"No communities installed"*
forever. That state is not merely empty — it is unusable, because **every route to sign-in requires a
community to already be open**: the identity picker carrying "Sign in securely with Loom…" lives in a
community screen's `AppBar`, and `_communityEntryGate` takes a `community.extensionId`. So the app with
no packages has no login, and the natural reading of that screen is "Android cannot authenticate",
which is what it was recorded as for two days.

`launch_loom_demo_emulators.sh` passes the define for `flutter run`, which is why the app behaves
correctly there and only the installed APK is empty. Two commands for the same app that differ in one
flag, where only one of them is documented here, is how the difference stayed invisible.

**The emulator still belongs on Windows** — that has not changed, and the VM has no AVD. What changes
is that *building* and *running* need not happen on the same host. The APK is a file; only the
emulator needs the Windows hypervisor.

**The wider lesson.** "Blocked on a Windows setting" was recorded as a blocker on 2026-08-30 and
repeated as one for a day, because the build was only ever tried in one place. Before reporting a
platform limitation as a blocker, check whether it is intrinsic to the task or incidental to where the
task happens to be running.
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

### A wrapper's own success message can hide the agent's total failure

On 2026-09-08 the new Patterns Agent's first real run **read nothing at all** — it decided the
prompt's "you cannot write any file" meant it could not run commands either — and the wrapper script
printed:

    No entries proposed. That is a legitimate outcome, not a failure.

Which is a sentence *I wrote*, to be reassuring about a genuinely empty sweep. It made a complete
failure indistinguishable from a clean result, and it would have done so on every future run.

**The bug is not the agent's confusion; it is that "found nothing" and "did nothing" produced
identical output.** Any wrapper that reports an empty result as fine must first prove the work
happened. The fix that generalizes: require the agent to emit a marker naming what it actually
consumed (`<<<SWEEP_READ: file, file, ...>>>`), and treat a missing marker as a **failed** run, not
an empty one — then print the agent's own reply so the reader can see why.

Two habits from it:

- **When you write a reassuring message into a script, ask what else could produce that same
  output.** If the answer includes "the thing never ran", the message is a liability.
- **Read the agent's actual reply, not your wrapper's summary of it.** This was caught only because
  the summary said "legitimate outcome" and the reply underneath said "I have therefore read none of
  the requested documents". The wrapper was not lying — it was reporting faithfully on a question it
  had never asked.

Same family as the grep-gated commit that passes because grep matched the words "Some tests failed":
a check whose success condition is satisfied by the failure it is meant to catch.

**The general form, and it bit three times on 2026-09-08 alone: a guard whose output never changes
is not a guard.** It fails in both directions and both are easy to live with for months.

| Instance | Direction | Effect |
|---|---|---|
| Patterns wrapper printing "no entries — a legitimate outcome" | always quiet | a run that read nothing looked identical to a clean sweep |
| Patterns sandbox audit comparing against a clean tree | always noisy | a pre-existing dirty `.last_dispatch.pid` raised a VIOLATION banner every run |
| `handoff_gate.sh`'s clean-tree check, with `.last_dispatch.pid` tracked | always noisy | the check CLAUDE.md calls "the check that mattered most" could never pass after any dispatch |

An always-quiet guard hides the failure it exists to catch. An always-noisy one gets scrolled past,
which hides the failure just as well and feels responsible while doing it. **The test is the same for
both: what would this check print if the thing it watches were broken — and is that different from
what it prints now?** If not, it is decoration.

All three were found by taking a boring line of output seriously rather than reading past it. Two of
them I had written myself, hours earlier, in the course of being careful.


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


### `grep -c` and `pgrep -fc` return "0" *and* exit non-zero

This one broke three consecutive completion checks on 2026-08-31, each time reporting a running
dispatch as finished:

    done=$(ssh vm 'grep -c "codex exec exited" /tmp/log || echo 0')

When there are no matches `grep -c` prints `0` **and** exits 1, so `|| echo 0` fires and appends a
second zero. The variable holds `"00"`, and `[ "$done" != "0" ]` is true. The check reports success on
its very first poll, before the thing being watched has done anything. `pgrep -fc` behaves the same
way.

**Use a form that always exits 0 and prints one number:**

    running=$(ssh vm 'pgrep -f "[c]odex exec" | wc -l')   # wc always succeeds
    [ "$running" = "0" ] && echo done


**A third variant, hit 2026-08-31: `grep` on a dispatch log counts zero because the log is
*binary*.** `codex` writes control sequences, so `grep "codex exec exited" /tmp/impl.log | wc -l`
returns **0** while printing `grep: /tmp/impl.log: binary file matches` — the match is found and the
matching line is never emitted. The dispatch had finished with status 0 and the check said it had not
even started. **Use `grep -a` on any dispatch log**, and note this is the same shape as the other two:
the count disagreed with the raw evidence — the log's own tail showed the completion banner — and the
raw evidence was right.

Two habits that catch this class of bug regardless of the mechanism:

- **One value per poll.** Two values joined with `tr '\n' '|'` and split with `cut` silently shift
  when the first command outputs nothing, so the second value lands in the first field. That is how a
  `pgrep` count of 5 got reported as an exit status of 5.
- **When a parsed status contradicts the raw evidence, the raw evidence wins.** A 253 KB log that was
  still growing and six live processes said "running" while the check said "done". The contradiction
  appeared on the first report and was believed three times before it was investigated.

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



### A dry run shows what the client sends, not what the server does with it

Twice on 2026-09-01 I recommended running `apply_app_access_provisioning --apply` as "one go-ahead
away and safe," because the tool has a dry-run mode and the dry run printed clean, plausible request
bodies. Reading the **receiving** code — `installCommunityPackage` in `AppAccessService` — showed the
apply would first **replace** every declared role's permissions (`setRolePermissions` deletes then
saves) and then **delete every group-scoped role the package does not declare**, sparing only one
reserved id. That would have destroyed all 11 community admin roles, unrecoverably, since their
`community.*` grants are not archetype-derived and a re-install cannot restore them.

The dry run could not have revealed this: it renders the POST bodies the client would send, and the
destruction happens server-side on receipt. **A dry-run mode is evidence about the client's intent,
never about the server's effect.** Before calling any apply/import/sync safe, read what the endpoint
does with the request — deletes, replaces, cascades — not just what the request contains. The same
shape sank the "3 of 79 rows proven" trust: the assertion ran against the engine's state, not the
rendered UI, so it proved a different thing than it appeared to.


### A deploy is not finished until the manifest bump is committed

This happened **twice on 2026-08-30/31**, the same way both times: build the image, import it, edit
the manifest's image tag, `kubectl apply`, watch the rollout succeed — and never commit the manifest.
The repo then says `0.3.1` while the cluster runs `0.3.2`.

**It survives a successful deploy, which is why it recurs.** The cluster is correct. The service
answers. Every probe is green. Only the *record* is wrong, so nothing fails and nothing surfaces it.
It is invisible until someone reads the manifest and believes it — or until a later deploy is built
from a tag that was never really shipped.

Both times it was found by deliberately comparing the three sources, never by anything breaking:

    kubectl get deploy <svc> -n loom -o jsonpath='{.spec.template.spec.containers[0].image}'
    grep -hoE 'image: [a-z/-]+:[0-9.]+' ~/loom-backend/deploy/k8s/*.yaml
    cd ~/loom-backend && git status --short

**Run that audit after any deploy, and treat the deploy as incomplete until the tree is clean.** The
same check catches a second thing worth knowing: a locally built image that is *not* deployed is
normal when a ticket said "build, do not deploy" — `loom-workflow-service:1.0.3` exists for exactly
that reason — so an image with no matching deployment is not automatically drift.

### The OpenAPI spec twins drift silently — check them, nothing else will

The service contracts live **twice**: in `Loom/docs/API/OpenAPI/**` where the app writes clients
against them, and in `loom-backend/spec/**` where the services implement them. They are meant to be
byte-identical and **nothing enforces it**. The reference-doc mirror test works only because both of
its copies sit in one repo; these do not, so no in-repo test can compare them, and a shared checksum
manifest does not help either — each repo would check its spec against its own copy of the manifest,
so a one-sided update passes on both sides.

On 2026-08-30 the Loom copy was dated **13 August** and behind by **four operations** — `deleteRole`
plus the whole invitation feature (`getInvitation`, `issueInvite`, `redeemInvite`), 168 lines, drifted
for two weeks. Nothing failed. The app simply did not know those endpoints existed.

    bash "docs/Build Plan V2/Tools/code/check_spec_parity.sh"     # exits 1 on drift

**A third member of this family now has a gate too.** `check_published_definitions.sh` compares every package's declared `workflowType`s against the deployed `workflow_definitions` rows, because that copy drifts the same way and had no check until 2026-09-08 — three types were unpublished, and a `createInstance` naming an unpublished type **returns success and does nothing**. Run it in the same audit.

**Run it whenever a spec changes, and as part of the post-deploy audit** — spec drift and an
uncommitted manifest bump surface at the same moment, so check them together.

**The comparison set is the backend's specs, not Loom's.** Loom carries ~50 and the backend 8; the 42
Loom-only files are app-side contracts with no service counterpart and are **not** drift. A spec
present in the backend and missing from Loom is.
### Publishing definitions is not a one-time step

**It now covers generated artifacts too, because they drift the same way.**
`permissions-vocabulary.json` is generated in Loom from `ArchetypeResolver` and **copied**
into `loom-backend`, where app-access loads it **from the classpath**. On 2026-08-31 the
backend copy held 97 ids and **no `calendar.*` at all** while Loom's held 106 — so
`CommunityPermissionDeriver` could not grant a permission it had never heard of, and **every
calendar-archetype workflow was uncreatable by anyone**. No test failed; the deployed
catalog simply lacked nine ids.

For these, **Loom is authoritative** — it is where they are generated. Regenerate there,
copy into the backend, then **rebuild the service**: editing the file on disk changes
nothing until a new image bundles it. That last step is what makes this different from the
spec twins, where syncing the file is the whole fix.

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

**A fourth, 2026-09-08, and it nearly caused a privileged action rather than just a wrong report.** A
B25 walkthrough stalled at the Keycloak login, so I searched for the seeded test password — grepping
for "password" *near specific usernames* — found nothing, told the user credentials were unrecorded,
and started resetting a Keycloak credential via the admin API. The permission classifier blocked that,
correctly. The password was documented all along, one line in the Access Control tracker, stated as a
**general convention** (`loom-<slug>` / `fan-<slug>` / one shared password) rather than per user, so a
query keyed to a username could never have matched it. Verified working immediately afterwards: HTTP
200 with a real token, no reset needed.

Two things generalize. **When you cannot find a specific value, search for the convention that would
define it** — identifiers, accounts and credentials in this project are nearly always described once
as a rule, not enumerated per instance. And **when a search's emptiness is about to justify an
irreversible or privileged action, that is the moment to get a second opinion instead** — the root
cause agent found the line in one dispatch, and its first words were that my premise was wrong.

**Before reporting something absent, run a control** — a query in the same shape that must return a
hit. If the control also returns nothing, the query is broken, not the codebase. Prefer reading the
definition and its callers over one pattern coming back empty.

**A control proves your query works. It does not prove your question is worth asking.** On
2026-09-08 I checked a tracker row claiming "zero packages declare `deliver_reminder`", ran a proper
control (six packages declare `set_reminder`, so the grep worked), and confirmed the row — correctly,
and uselessly. `deliver_reminder` is **derived from the archetype and never declared by a package**;
`calendar.md` §5 says so outright, and `ArchetypeResolver` defines it for both families. Zero
declarations was the designed state, not a gap, and I had just published a confident synthesis built
on it being a defect.

The control cannot catch this, because the query was fine. **Before reporting an absence as a
finding, read the definition of the thing that is absent and confirm it is supposed to be present.**
A count is evidence about the corpus; only the contract says what the count ought to be.

The same session produced the cheaper cousin twice: a grep for an `"archetype"` key that does not
exist (it is `cardSurfaceFamily`) returned 0 and looked like confirmation, and a control field chosen
from the *wrong community* returned 0 and briefly implicated a healthy field. **When a query returns
the answer you expected, that is the moment to check the key name and the scope** — an empty result
that agrees with you gets less scrutiny than one that does not, which is exactly backwards.

### The demo app IS wired to the deployed backend by default — stop re-litigating this

**Fact, re-confirmed 2026-09-06 by reading the actual call chain, not by grepping:**
`app/apps/loom_communities_demo/lib/main.dart`'s `main()` calls
`configureLoomRemoteServicesFromEnvironment()` at startup. `LOOM_ENV` defaults to `dev`, so this
returns non-null on every real launch, and `main()` then calls
`configureEngineNativeCommunityEngineFactoryForProduction(createRemoteEngineNativeCommunityEngineFactoryForConfiguration(...))`,
overriding `_EngineNativeCommunityStore`'s engine factory to the remote, Postgres-backed
`workflow-service` before any community store is installed. **The local, in-memory
`WorkflowDatabase.memory()` path only runs under the explicit dev-only opt-out,
`--dart-define=LOOM_ENV=local`.** In the real app, workflow instances — RSVPs, loans, donations,
everything — persist server-side and are shared across devices, not per-device and not
restart-fragile.

`WorkflowDatabase.memory()`/`LocalWorkflowEngineApi` mentions elsewhere in this repo's docs are
almost all **historical milestone records** from before this remote-engine wiring existed (dated
2026-07 through early 2026-08, in the `Loom Communities Workflow Engine V2/V3` phase docs) — read
them as "how it was built," not "how it works today." One narrow exception genuinely is still local
today: `part02_tab_shell.dart`'s `_MessagesEngineStore` backs only the not-yet-implemented Messages
tab and is out of scope by standing instruction, unrelated to the real community-data path above.

**Why this needed saying twice.** A stale tracker row ("`WorkflowDatabase.memory()` is the app's
only engine database... nothing survives a restart") got quoted to the user as the next actionable
item on 2026-09-06 — read the day after the row above it (`nothing selects the remote engine
factory`) was already logged. Two things should have caught it and neither did:

1. **A different, already-closed row on the very same tracker document** already said the opposite
   ("server-authoritative default CONFIRMED... already the production default", closed 2026-09-03) —
   read earlier in the same session, never cross-referenced against the stale row before repeating
   it.
2. **The stale row's own tag pointed at richer context** (`TODO.md, migrated`) that would have
   surfaced the original entry's own open question ("is this deliberately an ephemeral demo shell
   whose replacement is the remote engine?") — never followed.

Verification discipline had just been applied, correctly, to three *other* rows on this same
document minutes earlier — each caught as stale. It was dropped the moment a row's status tag read
`⬜ Open` instead of `✅ Closed`/`🟡 In progress`/`⛔ Blocked`, as if the tag itself were evidence of
current accuracy rather than something to verify like every other row. **A tracker's status tag is
never a substitute for reading the code it claims to describe — apply that check uniformly across
every row you're about to repeat, not only the ones that already look suspicious.**

**2026-08-31 produced five more in one session, and they are a different flavour worth naming: the
query was broken, not narrow.** The earlier three asked the wrong question; these failed to ask at
all, and every one printed a clean empty that read as data:

| What "nothing" actually meant | The tell |
|---|---|
| `find` for a `.dockerignore` printed nothing — **not even its own `\|\| echo` fallback** | a fallback that does not fire means the command never ran |
| `psql ... where definition::text like …` returned no rows | the column is `definition_json`; **stderr was suppressed by `2>/dev/null`** |
| `\dt` "showed" no `role_permission` table | I had piped it through `head -14` and it was **row 14** |
| `scp` to `…/bin/` reported success and copied nothing | the package has no `bin/` directory; **stderr was suppressed** |
| `grep -rln OfflineReplicaCoordinator` returned zero files | the class is `LoomOfflineReplicaReadStatus` and the entry point is a **function**, `refreshOfflineReplicaForExtensionId` |

Three habits, in the order they would have saved the most time:

- **Never suppress stderr on a command whose silence you intend to interpret.** `2>/dev/null` turns
  "column does not exist" into "no rows", which is a different fact.
- **Never truncate a listing you are about to conclude from.** `head -N` on `\dt`, on a `find`, or on
  a `grep -l` invents absences at the boundary.
- **When a name returns nothing, search for the neighbourhood before concluding** — the file, the
  callers, any symbol from the same feature. Four of the five above were real, working code sitting
  under a name I had assumed rather than checked.

### A workflow can be perfectly valid and still have an outcome nobody can reach

The 2026-09-08 B25 campaign drove all ten communities live. **Four of them had an intended outcome no
existing account could reach**, and not one was visible in a validator run — because each is a
property of the *system as deployed*, not of any declaration:

| Shape | The community that had it | What was actually wrong |
|---|---|---|
| **Role never provisioned** | Masjid Nur | the package declares `owner`; `app_role` has no such row, so four owner-guarded transitions are dead and a donation can never be `paid` |
| **Guarded role cannot see the instance** | Youth Soccer | only `paid` transition is coach-guarded, but the only tab rendering the payment is `visibleRoleIds: ["soccer-guardian"]` |
| **Precondition unsatisfiable from the real state** | Garden Club | owner exits require `availabilityState == "available"` while every transition clearing `onLoan` is borrower-guarded — a silent borrower strands the owner's own property |
| **Effect target not published** | Ad-Free, Data Portability | a `createInstance` naming a workflow type absent from `workflow_definitions` **returns success and does nothing** |

A fifth variant is really the first one again, and worth naming separately because it looks fine in
every table: **a role with only one holder where the interaction needs two.** Member Social Space
provisions exactly one `member`, and `send-invite`/`accept-invite`/`decline-invite` are all
`allowedRoleIds: ["member"]` — so no pair exists in which both parties qualify, and an invitee sees
zero buttons.

**Every individual guard in all five was well-formed.** The defect lives in the graph — who holds a
role, who can see a surface, what state the instance is realistically in, whether the target exists —
so no per-declaration check can find it. When verifying a workflow, ask of each terminal state: *who
may fire the transition into it, does a surface visible to that role render the instance, can the
precondition be satisfied from the state the instance will actually be in, and does every effect
target exist in the deployed catalog?*

And prove reachability by **firing** the guarded transition, not by reading the JSON. Two of the four
were first suspected from the package and then overturned or sharpened by what the device did — one
draft finding was withdrawn entirely when a control showed the affordance rendered on a different

### A capability has to be true at every layer, and each layer has its own tracker row

The same thing must exist in the package, in the generated vocabulary, in the live catalog, in App
Access provisioning, and in the published definitions. **Fixing one layer does not fix the others,
and each layer's tracker row reads as locally complete** — which is how a capability stays broken
while every row about it looks either closed or like somebody else's problem. Four instances on
2026-09-08 alone:

| Capability | True at | Missing at | Symptom |
|---|---|---|---|
| Masjid Nur's `owner` role | the package (added since August) | App Access provisioning | four transitions dead, donation never `paid` |
| `calendar.*` permissions | the generated vocabulary | the live catalog | every calendar workflow uncreatable |
| 3 workflow types | their packages | the published definitions | `createInstance` returns success and does nothing |
| Social Space `member` | role declared *and* provisioned | a **second holder** | `connected` unreachable by any pair |

Masjid Nur is the clearest: in August the *package* lacked `owner` and a tracker row said so; the
package was fixed, and the row about provisioning never existed, so the capability stayed dead while
the recorded problem was solved. **The gap moved layers rather than closing.**

Two habits. When you fix a declaration, **ask what else has to be true for it to take effect** —
generated, copied, published, provisioned, held by enough people. And when a row says a thing is
missing, **check which layer it means**, because a row written about one layer goes stale the moment
a different layer changes, in either direction.

This is also why the parity gates exist and why there are now three of them
(`check_spec_parity.sh`, the vocabulary twin inside it, `check_published_definitions.sh`): each one
compares the same capability across two layers, which is the only check that can see this class.
surface.

## Evidence rules

- `*.png` is gitignored: screenshots are transient. **Only a committed manifest is durable.** A
  capture run that does not commit its manifest has proven nothing.
- Never match product vocabulary by substring. `"Not attending"` contains `attend`;
  `"Join waitlist"` contains `wait`. Match on word boundaries, and never let a span claimed by an
  ALTERNATE term also count as a PRIMARY one.
- Process checks lie in both directions: `pgrep -c qemu-system-x86_64` returns 0 when it IS
  running (15-char `comm` truncation), and `pgrep -fc` returns 1 when nothing is (it matches its
  own command line). Use `adb devices` plus a bracketed `pgrep -fc '[q]emu...'`.
- **A stale Keycloak SSO cookie silently re-authenticates the PREVIOUS user, and the app says
  "signed in".** On 2026-09-08 a walkthrough holding a `fan-hoa-board-1` session tried to sign in as
  `fan-camera-member-1`; "Sign in securely with Loom…" showed **no login form at all** and returned a
  green *"You're signed in"* — Keycloak had re-issued a token for the old fan. The app's
  anti-impersonation guard caught it (it compares the selected account id against the token's
  `fanId`), which is the only reason it surfaced. **A success screen proves a token exists, not whose
  it is.** Hit Keycloak's logout endpoint before switching identity, confirm the real form appears,
  and confirm `created_by_fan_id` on the resulting row is the fan you meant. This is the likeliest
  way to bank evidence attributed to the wrong person, and it fails green in every direction.
  **Clearing the app does not clear the identity — the browser holds it.** On the same day, hitting
  Keycloak's logout endpoint was not sufficient, and neither was `pm clear` on the Loom app; the
  OAuth flow still completed with no form and re-issued the previous fan's token. Only
  `pm clear com.android.chrome` surfaced the real login form.
- **`adb shell input text` silently truncates, and a truncated identifier still looks valid.** On
  2026-09-08 a walkthrough typed `fan-hoa-member-1` into a `payerFanId` field and the device received
  `fan-hoa-memb`. Nothing errors: the workflow is created, the row persists, and the instance is
  addressed to a fan that does not exist — evidence that is wrong in the one field nobody re-reads.
  **Verify load-bearing values against the stored row, not the screen.** Reading the value back off
  the device is *not* sufficient — corrected 2026-09-08 after that weaker rule failed: a field that
  scrolls horizontally shows a plausible prefix while the stored value is short, which is exactly how
  Garden Club's `toolDescription` passed an on-screen check and was still truncated in
  `instance_data`. It truncated input four times in a single campaign. Prefer selecting an existing
  value over typing one, and settle anything load-bearing against the database.
- **Authentication recovery must never be gated on an error.** Account discovery, OAuth
  authentication, community account selection, and membership admission are four separate states, and
  a failure in one is not evidence about another. The app shell got this wrong in a way worth
  remembering: the "Continue to secure sign-in" button lived only in the account-list *error* branch,
  while a failed account tap showed a SnackBar and left `_error` null — so a user whose accounts
  loaded fine had **no way to sign in at all**, and the only escape was pressing a *membership*
  button to force the list to fail. The happy path produced the dead end. A cached community
  `currentSession` is a *selection*, not a token, and can outlive OAuth validity — never read it as
  proof of authentication.
- **A failed call is not evidence that a service is unreachable.** Keep authentication-required,
  authorization-refused, HTTP/service error and transport failure as distinct outcomes. The binding
  badge labelled every failure `BACKEND UNREACHABLE` without examining `statusCode` or `errorKind` —
  including a missing session that throws *before any request is sent* — which points an investigator
  at `kubectl` when the real answer is "sign in". Two corollaries worth carrying: the badge tracks the
  **latest** outcome per service and scope, so a later success clears the warning without explaining
  it; and its **absence does not prove a service ever answered**, because an uncalled binding raises
  no label either.
- **`uiautomator dump` disagrees with the screen, in both directions.** Same session: it returned
  stale trees twice and omitted a create FAB that screenshots showed plainly — nearly producing a
  report of a missing affordance that was actually on screen. When the dump and a screenshot
  disagree, **the screenshot wins**; run a control on a surface known to have the affordance before
  reporting one absent.

## Instrument the silence before theorising about it

Five explanations for one walkthrough stall were wrong, each reasoned from a symptom — a
screenshot, a process state, an agent's illustrative example. The cause only surfaced after the
run was made to report what it was waiting for. **Treat only text a system emitted about itself
as evidence**; example output inside an agent's report is prose, not telemetry.

## Standing constraints

- Community JSON is authored only by the Skill. Copy/relocate is allowed; hand-editing is not.
- The product doc is upstream of the JSON: the Skill designs the doc, then derives the package.
- Application code changes go through `data/call_implementation_agent.sh`.
- UX judging runs on the model `data/call_ux_judge_agent.sh` defaults to — **`fable` as of 2026-09-09, not Sonnet**; the script header claimed Sonnet while its code said otherwise, so check line 27 rather than the prose. Live walkthroughs run on
  Claude Opus (`data/call_live_verification_agent.sh`) — the DeepSeek gateway is text-only and
  refuses images, which a UX judge fundamentally needs.
- **Test users are seeded in the BACKEND, several per role, and community JSON carries no user ids.**
  Locked by the user and re-stated 2026-09-08: *"I have asked you repeatedly for seeding roles, and I
  keep saying to seed them in the back end, remove the userids from JSON."* Roles are declared in the
  package; the people holding them are Keycloak + App Access data. **Three things follow, and each
  has already caused a wrong diagnosis:**
  - *"Only one holder of role X" is a seeding gap, never a package defect.* 36 of 37 role assignments
    had exactly one holder on 2026-09-08, which silently killed every two-party same-role interaction
    — Social Space's `connected`, and six `join-queue`/`leave-queue` transitions a 2026-08-31 row had
    filed as "dead" with no cause. **Seed more users; never edit the package to route around it**
    (that is converging by removal against test data, which hard rule 14 forbids).
  - *A declared role with no holder is a provisioning gap, not a missing feature.* Masjid Nur declares
    `owner`, App Access never provisioned it, four donation transitions are unreachable. Seed it.
  - *A broken credential for one seeded user is not a decision point* — seed another user holding that
    role. This is what turned `loom-book-member-1`'s replaced password from a blocker into a non-issue.
  **Never substitute `<community>-admin` for a missing domain role.** The admin role is generated
  platform governance holding the five `community.*` permissions; a package's declared role (Masjid's
  `owner`, Chess's `chess-owner`) is a domain role. Different things, and conflating them produces a
  fix that quietly changes who governs a community.

## Architecture facts worth carrying, not just looking up

Folded in from `keypatterns.md` (the Root Cause Agent's own institutional memory — read that file
for the full, cited version of each) after its first seeding pass, 2026-09-07. These are the
entries that generalize beyond the one investigation that found them; the rest stay in
`keypatterns.md` itself as more specific reference material.

- **Identifier spaces are distinct contracts.** `extensionId`, canonical `communityId`,
  `communityHandle`, App Access group id, role id, fan id — each has a different job, and a
  valid-looking string in the wrong space passes ordinary type/schema checks silently. Map between
  them explicitly at every service or artifact boundary; don't assume one can stand in for another
  because both are strings that look like ids (this is exactly what produced the `authz-503`
  extensionId-vs-communityId bug).
- **Community administration is generated governance, not a package-authored role.** Install
  generates `<communityHandle>-admin` and grants it exactly the five `community.*` permissions; a
  package declares its own domain roles (organizer, coach, board member) separately, and one person
  may hold both. A workflow named "join" or "approve registration" does not itself create
  membership or grant a role — App Access owns memberships/roles/grants, Fan Passport owns personal
  identity, workflow instances own domain participation, and those three never collapse into one.
- **The workflow service runs the same engine as the local path, but not the same context.**
  Reusing `LocalWorkflowEngineApi` server-side avoids reimplementing guards/formulas/effects, but
  "local" in the class name doesn't mean device-only authority — and a shared engine still needs
  the request's own community, caller roles, and membership lookup installed correctly at every
  entry point. A server omitting that lookup once made every `membersOnly` record silently
  creator-only, because the shared rule correctly returned false for a check nobody had populated.
- **An archetype, a card, and a tab renderer are three separate mechanisms.** Naming a tab
  `calendar` does not make it render a calendar — the bound archetype decides that, and `calendar`
  the archetype has no attendance semantics of its own and can be bound into a tab with any name.
  Archetype-to-renderer is not one-to-one either. Treat "the docs say this archetype exists" and
  "this archetype actually renders" as two separate claims to verify.
- **Remote communities start empty on purpose — that's the 2026-09-07 decision, not a bug to chase
  again.** Package `workflowInstances` seed only the local engine; installing/publishing a package
  is not a request to copy demo instances into Postgres. Every member-created workflow needs a real
  create path, and the first live check of anything must exercise creation itself, not assume seed
  content will be there.
- **`writableBy` and `platformSource` answer different questions.** `writableBy` says who writes a
  field; `platformSource` names a supported generated-value mechanism for fields that have one.
  Neither substitutes for the other, and reclassifying an unwritten field doesn't make it populate —
  a `relatedInstance` effect targeting a *different* workflow type can be a field's real writer, and
  a validator that only checks same-workflow/`createInstance` writes will false-positive on it
  (exactly what happened investigating Cedar's "orphan" fields — the fix was to trust the actual
  effect graph, not silence the warning by reclassifying the field).
- **Reminder ownership, initiation, and delivery are three independent choices, not one setting.**
  `set_reminder` is a member's own preference on their own row; `send_reminder` is a deliberate,
  role-guarded human action; `deliver_reminder` is unauthored, formula-driven platform delivery with
  no transition or role grant at all. Migrations have repeatedly deleted a legitimate manual button
  or a member's own preference by treating these as one mechanism.
- **A destructive transition's guard must come from the specific obligation it ends, not a
  neighboring guard copied over.** A listing can stay `published` while its own availability data
  says reserved/on-loan — "owner-only delist" has independently reappeared in more than one
  community and can strand an active borrower; the opposite mistake (gating cancellation on a
  success-only precondition) can trap a failed operation with no exit either. Trace the actual
  obligation before deciding a destructive action is safe.
- **`specVersion`, `skillVersion`, and a provenance hash prove three different things, and none
  substitutes for the others.** Grammar compatibility, last-applied authoring convention, and exact
  byte identity are independent facts — a package can match its recorded `skillVersion` and still
  have never received an earlier convention that version implies, and a provenance hash proves a
  file matches its own manifest, not that a Skill dispatch (rather than a hand-edit) produced it.
- **A walkthrough identity must be *authenticated*, not merely selected — and the app cannot write
  anything until it is.** The remote engine refuses to send a request without a bearer token, and the
  only token source is a stored OAuth session from a browser Keycloak login; there is no dev-token
  bypass in the production path. So a seeded App Access membership, or picking a name in the demo
  identity picker, establishes nothing on its own — and the picker cannot impersonate either, because
  remote sign-in compares the selected account id against the token's `fanId` and rejects a mismatch.
  Sign in as the same identity you intend to act as. The seeded accounts follow one documented
  convention (Keycloak `loom-<slug>`, fan id `fan-<slug>`, a shared test password recorded in the
  Access Control tracker), so this needs no credential creation or reset — **look the convention up
  before concluding you are blocked.**
- **`on_device_remote_backend_proof_test.dart` is not a substitute for a live walkthrough.** It
  authenticates and then calls the engine *directly*, so it proves the service boundary, not that any
  UI path reaches it — a different claim wearing similar evidence. It is also stale (asserts seven
  Cedar definitions, omits the now-required canonical `communityId`). Same family as the dry-run rule:
  the artifact proves what it exercised, not what it resembles.

## Autonomous mode — how to run the tracker without being asked

Armed 2026-08-27. These are the patterns that actually held up over the preceding week; each one is
here because ignoring it cost a rework.


**The worked example, and I caused it hours after writing the rule above.** A seeded test fan is real
only when **three** things exist, and missing any one still looks correct from the other two:

| Layer | Where | Missing means |
|---|---|---|
| Authentication | Keycloak account **carrying the `fanId` attribute** | authenticates, then fails every authorization check |
| Identity | a `fan_passport` row | **cannot sign in to the app at all** |
| Authorization | `group_membership_role` membership + role grant | signs in, can do nothing |

On 2026-09-08 I seeded 23 role holders, wrote layers 1 and 3, skipped layer 2, and reported the job
complete on the strength of `group_membership_role` showing 24 of 37 roles with 2+ holders — true,
and useless. Every one of the 23 was unusable, and they existed specifically to unblock two-party
interactions. A walkthrough dispatched minutes later found it and, correctly, refused to mint the one
passport it needed because that would have masked a 23-account gap.

**Seed in layer order (passport before membership), and verify the capability rather than the table
you just wrote to** — end-to-end here means obtaining a token as that fan and reading their own
passport back, not counting rows.
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
| Root-causing a stubborn defect, or scoping a non-trivial change before writing its ticket | `data/call_root_cause_agent.sh` |
| Mining the project's own history for durable patterns (run manually, occasionally) | `data/call_patterns_agent.sh` |

**The Root Cause Agent's session is scoped to ONE task or ONE tracker phase — not to the project**
(user-directed 2026-09-08, superseding the 2026-09-07 "one permanent session" design). It is also
not only for debugging.

    bash data/call_root_cause_agent.sh <brief>                       # fresh session
    bash data/call_root_cause_agent.sh <brief> --session-key <key>   # scoped session

- **No key → a fresh session, every time.** This is the default and the right choice for a one-off
  question, because a stale unrelated context is worse than no context.
- **A key → resume that key's session if it exists, else seed it.** Use the SAME key for a follow-up
  on something this agent already helped with, and for every dispatch inside one tracker
  phase/milestone. **A new phase means a new key.** Keys are free-form and sanitised into filenames
  at `.codex-logs/root_cause_sessions/<key>.id`; use something durable like
  `gap-permission-catalog` or `phase-e-access-authority`.

There is still no flag to resume an arbitrary session: you either name a key or you get a fresh one,
so a caller can never silently inherit an unrelated context. To abandon a key's session, delete that
key's file. The pre-2026-09-08 global `.codex-logs/.root_cause_agent_session_id` is **no longer read
automatically** — pass `--session-key legacy-expert` if you deliberately want that old accumulated
thread back.

**Why the change, measured rather than assumed.** Verified live 2026-09-08 on the new script: a
keyed resume reused its thread id with a **90.8% cache hit on 18,471 input tokens**. The old
project-wide session was carrying **1.1–1.5M input tokens per dispatch**. Same continuity benefit
where it matters (a follow-up remembers the work it follows up on), at roughly 1.5% of the prefix
cost — because cached input is not free (~10% of uncached), so a large accumulated prefix is a
recurring tax on every resume, not a one-time investment.

Model `gpt-6-astra` at reasoning effort `high` — this required upgrading the VM's Codex CLI itself
(0.147.0 rejected that model outright; `npm install -g @openai/codex@0.153.4` fixed it). Dispatch
it not only when something is already broken, but *before* writing an implementation ticket for
anything non-trivial, to trace the real mechanism first rather than write a ticket from an assumed
one.

**The persistent session is cheap to keep, and the seeding pass is where the cost lives.** Measured
2026-09-08 across the session's first three invocations: **7,240,905 total tokens, of which
6,760,320 input tokens were cache hits — 93.7%.** Uncached input was 451,468 and output 29,117. The
seeding pass alone was 4.6M (it read the trackers, architecture docs and git history); the two
scoping dispatches after it cost ~1.5M and ~1.1M each, nearly all cached. So the marginal cost of
asking this agent one more question is small, and **the instinct to "save tokens" by starting a
fresh session has it backwards** — a fresh session pays the uncached price again and knows less.

**Reading that number has a trap.** `total_token_usage` in the session rollout
(`~/.codex/sessions/YYYY/MM/DD/rollout-*-<session-id>.jsonl`) is cumulative *within one invocation*
and **resets on each resume**. Taking the last record reports only the most recent invocation — it
understated the 24-hour total by 6× on the first attempt. Sum the peak value of each invocation
instead (detect a reset as a drop in `total_tokens`).


**What it is actually good for, assessed honestly after three dispatches (2026-09-08).** Its value
has been **independence, not knowledge** — every high-value moment was it *not sharing an assumption
I had already made*, rather than it knowing something unfindable.

- **The one irreplaceable find**: unprompted, it noted that `RemoteLoomAuthApi.signIn()` compares the
  selected account id against the token's `fanId` and rejects a mismatch. Nothing would have sent me
  looking for that, and it is why nine communities' B25 evidence is attributed to the right fan —
  without it, a stale SSO session would have banked a Camera Club row under `fan-hoa-board-1`.
- **Two premise corrections, both while I was confident and wrong**: that the seeded credentials *are*
  recorded (one line in a tracker I had already grepped, keyed to usernames when the convention is
  stated generically), and that `listAccounts` cannot start from an empty session, so the entry-gate
  trigger is a failed account *tap* rather than a successful load. I would have written an
  implementation ticket from the wrong mechanism.
- **It declined to answer once**, refusing to attribute a database row to a mechanism because the
  table has no caller-channel column. That is worth more than a plausible guess.

**Where it was NOT worth it.** The state-machine trace it produced was good and I re-verified every
load-bearing claim myself in about five minutes — the tracing was replaceable, only the framing
correction was not.

**On the 4.6M-token seeding pass: genuinely unsettled, and my first write-up overstated the case
against it.** The measured facts: it is 63% of all spend on this agent, and cached input is not free
(~10% of uncached), so the seeded prefix is a **recurring tax on every resume, not a one-time
investment** — at invocation 2 the cached prefix cost roughly 144k uncached-equivalent against only
82k of genuinely new input. That argues for seeding thin.

**But "I cannot point to a decision it changed" is an absence-of-evidence claim, and there is no
control run.** The single most valuable thing this agent produced — spotting the
`signIn`/`fanId` anti-impersonation guard unprompted — plausibly came *from* the auth-code
familiarity that seeding bought. Unprovable either way, and this file elsewhere warns against exactly
the reasoning I used to dismiss it.

Two distinctions that matter before anyone acts on this:

- **Abandoning the persistent session is a different (and worse) change than seeding it thinly.** A
  fresh session pays uncached for everything it reads, every time. Keep the session.
- **The cache rewards a *stable* prefix, not a *large* one.** So the real alternative to a broad
  seeding pass is not "no context" — it is letting context accumulate from real dispatches, where
  every token in the prefix is something a real question needed.

**The experiment that would settle it**, if a fresh session is ever needed anyway: run one dispatch
cold against a question whose answer is already known (the 2026-09-08 entry-gate scoping is fully
logged), and compare answer quality and uncached cost against the seeded run. That replaces two
intuitions with a number. Until then, treat a *re-seed* proposal as unproven rather than as wrong.

One measurement I could not explain and did not model around: invocation 3's cached input (1.01M) is
*lower* than invocation 2's (1.44M), where pure accumulation would predict growth — compaction,
eviction, or simply reading fewer files. Understand that before reasoning confidently about prefix
economics here.

**So use it before acting, not after being stuck** — both saves were pre-action framing checks, and
the stuck-debugging case was the weaker one. **State your premise explicitly in the brief and ask it
to attack that first**; "I would rather learn my framing is wrong than get a fix for the wrong
problem" produced both corrections. And credit the right guard: on the credential reset it was the
**permission classifier** that stopped the action, and the agent that explained why afterwards.
**It runs `--sandbox read-only`, genuinely zero write and zero network access — enforced, not just
asked for** (tightened same day, after the earlier `workspace-write`/prompt-only design). Confirmed
live: a write attempt gets `Read-only file system` even to an `--add-dir`-named path (that flag only
does anything under `workspace-write`), and a `curl` to a live local service fails outright with no
override available. **This means it cannot fetch its own live evidence** — a DB query, a `kubectl`,
a log tail — the dispatching session must gather that beforehand and paste it into the brief. It
reads code and reasons; it proposes a diagnosis, a fix, or test code as *text* in its reply for
someone else to apply — never a file it writes or a command it runs. There is no report file either
(nothing to write one with): its reply in the dispatch log is the whole deliverable.

**`keypatterns.md`** (repo root) **is that agent's legible memory — and since it cannot write
anything, this script is the one that writes it, not the agent.** The agent PROPOSES an entry
(a recurring issue, a durable pattern, or a key architectural decision/pivot) as text in its reply,
delimited by `<<<KEYPATTERNS_ENTRY>>>`/`<<<END_KEYPATTERNS_ENTRY>>>`; `call_root_cause_agent.sh`
itself extracts and appends it after the dispatch completes. That file is staging memory, not
loaded automatically the way this one is. **After any Root Cause Agent dispatch that appends an
entry, read what's new and fold anything genuinely durable and generally-applicable into this file
yourself**, in this file's own voice and level of generality — a `keypatterns.md` entry that never
makes this trip is a lesson the next session won't have.

**The Patterns Agent fills `keypatterns.md` from the other direction, and you run it by hand.**

    bash data/call_patterns_agent.sh [--since <rev-or-date>] [extra-file ...]

The Root Cause Agent only ever contributes an entry *about whatever was broken that day*, and only
when someone happens to dispatch it. Patterns that live in the **shape** of the record — the same
mistake in three commits six weeks apart, a decision reversed twice, a guard that keeps lapsing,
two areas that always change together — are invisible to that. This agent reads the record instead
of the bug: pre-gathered git history plus churn (`.codex-logs/patterns_input/`), `keypatterns.md`,
`CLAUDE.md`, the four trackers and `solved-patterns.md`. Same model (`gpt-6-astra` at `high`, pinned
by both `-p` and explicit `-c` overrides so a missing profile cannot silently downgrade it), same
read-only sandbox, same propose-and-the-script-appends write model, same violation audit.

**It is always a FRESH session, deliberately** — the opposite of the Root Cause Agent's scoped keys.
A resumed sweep would anchor on its own prior conclusions and stop noticing anything new; each sweep
should be a cold read of the whole corpus.

Two things to hold onto when using it. **An empty sweep is a correct result** — the prompt tells it
that proposing nothing beats padding, so do not read a quiet run as a failure or re-run it hoping for
output. And **every appended entry is a proposal, not a verified fact**: review each one, delete any
that does not earn its place, and commit `keypatterns.md` yourself. The same fold-into-this-file
responsibility above applies to whatever survives that review.

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
| UX judging (needs images; model is whatever the script defaults to — `fable` at 2026-09-09) | `data/call_ux_judge_agent.sh` |
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

| Suite | Path | Baseline (2026-09-04, re-measured) |
| --- | --- | ---: |
| UX judges | `app/packages/tooling/loom_ux_judges` | **500** (0 skipped) — measured 2026-09-10 after the `dead_role_binding` removal (5 obsolete warning tests replaced by 4 regression tests); was 501, and 490 before that |
| App shell | `app/packages/core/loom_communities_app_shell` | **408** (+2 skipped) — measured 2026-09-10; was recorded as 403, and as 375 for four days while the real figure passed 400 |
| Workflow engine | `app/packages/core/loom_workflow_engine` | **310** (+5 skipped) **= 315 cases**, without PG credentials — measured 2026-09-10; was recorded as 312. See the note below on that −2 |
| Workflow service | `app/packages/core/loom_workflow_service` | **156 (+1 skipped) = 157 cases** with BOTH credential sets — measured 2026-09-10; was recorded as 153. 146 (+8) with only `LOOM_POSTGRES_PASSWORD`; 142 (+12) with none. **Read the RLS-timeout note below before trusting a red run here.** The one expected skip is `app_access_create_instance_integration_test.dart` ("Set `LOOM_APP_ACCESS_BASE_URL`…"), not a PostgreSQL test |

**`postgres_rls_integration_test.dart` times out under concurrency, and it will look like a security
regression.** Measured 2026-09-10: the full suite with both credential sets came back **red** —
`155 +1 ~1 -1`, the single failure being *"forced RLS isolates every community tenant table and
permits its owner"*. That is the one test this whole two-credential dance exists to run, so a red
there reads alarmingly. **It was contention, not a regression.** The failure is a
`TimeoutException after 0:00:30`, never a failed `expect`; the test walks ~32 per-table checks over
the port-forward (visible as the counter climbing `+123 → +154` under one test name) and `dart test`
was running it **concurrently with `postgres_transaction_rollback_integration_test.dart`**, another
PostgreSQL-heavy file that deliberately injects write failures. Re-run alone it passes in **22
seconds** — under the 30s default, but with little headroom:

    dart test test/postgres_rls_integration_test.dart --concurrency=1

So: **a timeout on this file is environmental and the documented rule already covers it** ("re-run
the single test in isolation before calling it a regression; a failed `expect` is a different
matter"). Do not file an RLS defect, and do not weaken the test's timeout, without an isolated run
first. Equally, do not record a service baseline from a run where it timed out — the pass count is
one short.
| Demo app | `app/apps/loom_communities_demo` | **160** (0 skipped) — confirmed unchanged 2026-09-10 |

**On the engine's −2, recorded rather than waved away.** The suite is green (exit 0, skips unchanged
at 5), so this is not a failure — but a total moving *down* is the shape that can hide a deletion, so
it needs a reason. The likeliest one is `c31a1998` (2026-09-06, "remove the dead
`workflowType==notification` delivery branch"), which would legitimately take its tests with it; the
engine row carried no re-measurement date, unlike its neighbours, so 312 plausibly predates that
commit. **That is a probable explanation, not a verified one.** Note also that counting declared
tests here gives **293** against 315 runtime cases — the two legitimately differ because
parameterised and looped `test(...)` calls emit several cases each, so the declared-count check
CLAUDE.md recommends elsewhere is a *change* detector for this package, not an absolute cross-check.

**The workflow service needs TWO credential sets, and supplying only one produces a green run that
proves nothing.** `LOOM_POSTGRES_PASSWORD` alone still skips `postgres_rls_integration_test.dart` —
the only PostgreSQL-backed test that exercises `PostgresItemQueueRepository` and the RLS boundary —
because that test *also* requires the restricted role from the two-role split. Measured 2026-09-04
while verifying the item_queue idempotency refactor: admin-only gave `146 passed / 8 skipped` and
looked like real PostgreSQL verification, while silently skipping the one test covering the changed
code. Both sets gives `153 (+1)`, and the remaining skip is an unrelated live App Access check.

    LOOM_POSTGRES_USERNAME=loom            LOOM_POSTGRES_PASSWORD="$PW"       # admin, runs migrations
    LOOM_POSTGRES_APP_USERNAME=loom_workflow_app LOOM_POSTGRES_APP_PASSWORD="$APW"   # restricted runtime role

`$APW` is in the `postgres-workflow-app-credentials` secret; `$PW` is in `postgres-credentials`.
**Read which tests skipped, not just the count** — the count moving from 12 to 8 looked like progress
and the test that mattered was still in the remainder.

Run all five after installing a regenerated community package. The demo app renders the shipped
packages, so it is precisely the suite a package change can break, and precisely the one that looks
skippable because the change was "just JSON".

**It is not only package changes — an app-shell widget change broke it too, and shipped.** On
2026-09-04 a role-picker fix (`3ad79072`) renamed a widget key from `actor-identity-option-<roleId>`
to `actor-identity-available-role-<roleId>`. The app shell, engine and judges suites were run and all
passed, the change was called verified, committed and pushed — and it had broken **8 demo-app tests**,
because `app/apps/loom_communities_demo/test/workflow_ui_test_harness.dart` looks that key up and
hard-fails with *"Actor identity X was not available in the actor identity picker"*. Caught only
later, by A/B: `HEAD` gave 152/8, reverting those two files alone gave 160/0. Fixed in `c47c6dc8` by
restoring the key while keeping the rows non-interactive.

Two rules from it. **A widget key is a cross-package contract** — grep the whole repo, including
`app/apps/**`, before renaming one. And **"verified" means all five suites**; three of five is a
partial result and saying otherwise overstates the evidence.

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
table: **72 real rows** (measured 2026-09-09), each proven by live walkthrough *and* UX judge.

**The long-quoted "79" is wrong and should not be repeated.** Counting the B25 addendum table across all
ten shipped product docs gives **77** rows present, and five of those are Masjid's `wf_` test-harness
ids — `wf_demo-app-persona-picker`, `wf_community-persona-aware-ux`, `wf_multi-persona-workflow-evidence`
— which that doc's own header already disclaims as literal `testWidgets` names with no
`LoomWorkflowDefinition` behind them. So the real bar is **72**.

**The 79-vs-77 gap is now RECONCILED (2026-09-10) and needs no further tracing.** 79 was a correct
count *of its day*: the generated asset at `b8d019e2` (2026-08-24) declared `rowCount: 79`. Seven rows
were removed and five added since, netting −2:

    removed  chess-local-install-open, chess-route-home, garden-tool-loan-giveaway,
             platform-connection-invite, platform-connections-entry,
             platform-message-stream, platform-messages-entry
    added    garden-tool-loan, garden-tool-giveaway, hoa-document-access-request,
             platform-connection, platform-message-thread

Those seven are **exactly** the rows the 2026-08-24 reachability sweep had flagged as naming a
workflow no package ships — so the gap is that sweep's findings being fixed (Garden's one fused row
split into the two workflows the package actually ships; the four `platform-*` rows consolidated into
two real ones; Chess's two route/install rows were never workflows and were dropped). Today's asset:
`rowCount: 77`, `len(rows) == 77`, three `wf_` ids spanning five rows (two appear twice, under
different personas), **77 − 5 = 72**.

**The lesson, since this sat "unreconciled" for a day for no reason:** the old figure was not wrong,
it was *stale*, and the way to tell those apart is to re-derive it **at the commit that recorded it**
rather than only at HEAD. `git show <commit>:<asset>` answered in one command what re-counting the
current docs never could. Also note the first search for the figure's origin matched a **commit hash**
containing `79` — when pickaxing for a number, read the hit before trusting the date it gives you.

**Two further defects corrupt the same fraction, so do not quote a completion figure until all three
are fixed together:** B25 evidence manifests written before 2026-09-09 record no package identity, so
the numerator cannot be checked for staleness (the brief generator now requires `skillVersion` plus
`sha256`); and the "roughly 22 of 79 proven-against-fakes" accounting needs restating over the corrected 72.
**Do not inflate it toward the 53 fake-backed APIs in `loom_fake_backend`** — those are test and
legacy-`loom_demo` scaffolding with **zero** imports in `loom_communities_demo/lib` or the app
shell's `lib`, so they are absent from the path B25 drives. The share is limited by the four
*missing platform services* (payment, id generation, external search/AI, checksum), which is what
that accounting was always built on. A denominator is the number nobody re-derives, which is exactly how this one
stayed wrong while the tables underneath said otherwise.

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

### A package role rename never reaches App Access, and the stale role keeps working

Masjid Nur's donation flow was unreachable for weeks because four transitions guard on
`byRoleIds: ["owner"]` and no account could hold `owner`. It read as a provisioning miss. It was not.

The 2026-08-26 install **succeeded** — `{"rolesRegistered": ["community-member", "masjid-admin"],
"permissionsGranted": 44}`, and 44 is exactly 21 + 23, the two roles' derived sets. The package
declared `masjid-admin` then. On 2026-09-05 commit `14d6e1a6` regenerated it and renamed that role
to `owner` — **and nothing re-provisioned App Access**. The old role kept its 23 permissions and
kept working, so nothing failed; only the *new* name had no row.

**Renaming a `roleId` in a package is a migration, not an edit.** Install is not idempotent across a
rename: it creates the new id and leaves the old one, because the sweep only deletes roles the
package does not declare — and by then the package no longer declares the old name either. After any
`roleId` change, diff the package's declared roles against live `app_role` for that group. Nothing
does this automatically, and the failure is silent in both directions.

**Do not repair this with `installCommunityPackage`.** Its sweep (`AppAccessService:565`) deletes
undeclared group roles by invoking repository deletion at `:579`, bypassing `deleteRole`'s
holder-protection checks. `createRole` and `setRolePermissions` are the surgical endpoints and avoid
the sweep entirely. `createRole` accepts the permission set inline.

**Three headers are required and the spec's prose only makes one obvious:** `Idempotency-Key`,
`X-Loom-Actor`, and `X-Loom-Correlation-Id` — the last **must be a real UUID**, and any other string
400s with `Expected type class java.util.UUID`. Each was found by a precise 400, one at a time.

### Absence of a record is evidence only after you measure the window

`masjid-nur-admin` was created 2026-09-02 carrying the *package domain role's* label and 28
permissions — the 5 governance grants plus the 23 that belong to `owner`. No `idempotency_record`
exists for that date, which means it was written directly to the database rather than through any
endpoint.

That conclusion is only available because the window was checked first: `min(created_at)` is
2026-08-13 and `max(created_at)` is 2026-09-09, continuous across the date in question. Without that
check the empty result is the ordinary "a search that finds nothing is not evidence of absence", and
the same query would have proved nothing at all. **When you intend to read meaning into an empty
audit query, measure the audit's coverage in the same breath.**

The wider point: **a label is not a key, but it is a witness.** The installer keys on `roleId` and
treats labels as display text — a root cause agent confirmed that by reading the code, killing my
label-collapse hypothesis. Yet the stray role's `display_name` was still "Masjid Admin", the *domain*
role's label, which is what identified where its permissions came from. The mechanism theory was
wrong and the artifact it left behind was still the decisive clue.

### Write the read-only agent's prohibition as "do not mutate", never "do not run commands"

The Root Cause Agent's sandbox is read-only, so *every* read is safe by construction and no write can
succeed even by accident. The prohibition in a brief therefore only needs to name mutation and
network — and if it says anything broader, the agent obeys the broader thing.

On 2026-09-08 a brief opened with *"Do not write files, run commands, or reach the network."* The
agent read no source at all, correctly noting that I had forbidden the commands it would need, and
returned a request for a hand-assembled source packet instead of an answer. It also declined to guess,
which was the right call — but a dispatch was spent establishing nothing. Re-dispatched on the same
session key with *"you can and should READ the repository: run `ls`, `cat`, `sed`, `grep`, `rg`,
`find` freely"*, it immediately began reading the packages and the widget tree.

**This is the second instance of the identical shape**, after the Patterns Agent read nothing because
"you cannot write any file" was taken to rule out running anything. Both times the agent's inference
was reasonable and the brief was wrong. The wording that works names the capability positively and
explains why it is safe:

> You have READ-ONLY access — reads are safe by construction. Do not attempt to mutate anything or
> reach the network; read the repository freely with `cat`, `sed`, `grep`, `rg`, `find`.

The compare-and-contrast is exact: the Masjid brief the same day said *"Do not attempt to write
files, run kubectl, or reach the network"* — naming two specific mutating commands rather than
commands in general — and that agent read both repositories without hesitation.

**The general rule: a prohibition an agent cannot safely over-apply is worth more than a tighter one
it can.** When the sandbox already enforces the boundary, the brief should describe the boundary, not
re-impose it in looser words.

### A method belongs to a class, not to the file the class's neighbour named

I spent a dispatch on a confident, wrong theory: that `join_queue` was dead on non-marketplace tabs,
because `_applyQueueAction` lives in `part36_engine_native_marketplace_surface.dart` and that surface
is returned only for `case 'MarketplaceTabSurface'`.

The file holds **five** archetype card classes. `EngineNativeMarketplaceSurface` spans lines 10–385;
`_applyQueueAction` is at 594, inside `_EquipmentLoanArchetypeCardState`. The Home tab resolves to
`EngineNativeListSurface`, which dispatches `equipment-loan` to that *same* card — so both tabs share
one queue handler, and the defect I was sure of does not exist.

**In a `partNN_<something>.dart` layout the filename names one occupant, not the contents.** Before
reasoning about where a method can run, get its enclosing class — `grep -n '^class '` and compare
line numbers — rather than inferring reachability from the filename. This is the same family as
matching product vocabulary by substring: a plausible containing string standing in for the real
structure.

Two more corrections from the same investigation, both worth keeping:

- **`"to": null` with no authored effects is not a no-op.** The engine preserves state with
  `transition.to ?? row.currentState` and then runs **archetype bookkeeping** — the `equipment-loan`
  action map adds or removes the actor in the legacy `queuedFanIds` list, and the bookkeeping can
  introduce that field even when the schema omits it. So a transition with nothing authored on it
  still mutates the instance. "No declared effects" describes the package, not the behaviour.
- **A capability check written as `engine is RemoteWorkflowEngineApi` breaks the moment anything
  wraps the engine.** `LoomReplicaFallbackWorkflowEngineApi` *implements* `WorkflowEngineApi` rather
  than extending the remote class, so wrapping silently flips the check to false and the feature
  falls back — on every surface, with no error. Prefer asking the object for the capability over
  testing its concrete type, and when a concrete-type test is unavoidable, unwrap first. Whether such
  a latent defect is *live* is a separate question worth answering explicitly: this one is dormant
  because the wrapper is only installed when a `String.fromEnvironment` directory is non-empty, and
  it defaults to empty.

**A stale baseline raises false alarms in both directions — 2026-09-08 nearly produced one.** The
app-shell row said 375 while the suite actually ran 403. Verifying a dispatch that had added exactly
three tests, the jump looked like inflation and I began investigating a fabricated-test problem that
did not exist. The resolution was to count declared tests at `HEAD` against the working tree —
`git show HEAD:<path> | grep -cE '^\s*(testWidgets|test)\('` summed across the package — which showed
398 versus 401, a delta of exactly 3.

That count is the right check whenever a suite total surprises you, because it is independent of the
runner and of load: it answers "did this change add or remove tests" without re-running anything. The
danger of the stale number is symmetric — it would equally have let a genuine deletion hide, since a
suite that dropped from 403 to 390 still looks like growth against a baseline of 375.

### Scope a ticket by the population, not by the file you happened to be reading

Fixing the replica-wrapper bug, I scoped the ticket to "this card, or any sibling archetype card in
the same file". The agent did exactly that and found two siblings I had not anticipated — the
document-library and export-wizard cards had the same defect. Good result, wrong boundary.

An exhaustive sweep of the package afterwards found **eleven** sites testing
`is`/`is!`/`as RemoteWorkflowEngineApi`, and one of them was in a different file entirely
(`part43_document_uploads.dart`) — the single most user-visible instance, since it blocks document
uploads and explains it with *"This build is running on the local engine"*, which under the wrapper
is false.

**When a defect is "this pattern is wrong", the ticket's scope is every instance of the pattern.**
Enumerate them first — one `grep` over the package — and either list them in the ticket or state
that the sweep found no others. The cheap sweep is what turns "fix this occurrence" into "fix this
class", and it is the dispatching session's job, not the agent's: an agent asked about one file
cannot know what it was not shown.

**A corollary about the fix's shape.** Because the three cards live in one file as separate classes,
the correct-looking fix produced three identical private `_remoteEngine` getters, and `part25`
already held a fourth inline copy. A rule duplicated five times is a rule that will be missed a sixth
— when a ticket's fix is "apply this unwrap consistently", prefer one shared helper over per-site
copies, and say so in the ticket.

### A guard that depends on a field only its own transition writes is self-blocking

Found while sweeping `audience: "actor"` bindings, 2026-09-08. Member Social Space's
`start-conversation` is `from: ["draft"] → "open"` with `guard: {actorEqualsField:
participantAFanId}` and an effect that **sets** `participantAFanId` to `$actor`. The guard asks
whether the actor equals a field that only this transition populates, and
`guard_evaluator.dart:52` is `if (fanId != instanceData[key]) return false;` — a null field can never
equal a fan id. Nothing upstream would let the transition fire, so the thread could never leave
`draft` and a conversation could never be started.

It is **not** a live defect, because the create action's `prefill` sets the field first. That is
exactly the point: the guard is only satisfiable because something upstream populates its field, and
nothing in the package makes that dependency visible. Delete the `prefill` — or reclassify the field,
or regenerate the workflow without it — and the workflow dies silently, with every guard, effect and
binding still looking correct in isolation.

**When a transition's guard reads a field, check who writes it and whether that writer runs before
this transition can fire.** If the only writer is this transition's own effects, either the create
path must prefill it or the guard is wrong. Same family as the render-audience trap in
`solved-patterns.md` §7: both are cases where a field's *timing*, not its presence, decides whether a
capability exists.

**And the sweep that found it nearly produced two false positives, from one broken query.**
`grep -o '"prefill": {[^}]*}'` matches only single-line blocks; the two communities whose prefills
span multiple lines came back empty and looked exactly like the defect being hunted. A control on the
same file (`grep -c '"prefill"'` → 6) would have shown the query was broken rather than the packages.
**Run the control on the file you are about to accuse, not just on a file you expect to pass.**

**A corpus-wide sweep for that shape found zero live instances, and the negative result is worth
recording so nobody re-runs it.** Across all ten shipped packages there are seven transitions whose
guard reads a field that same transition also writes:

| Community | Transition | Field | Verdict |
|---|---|---|---|
| Book Club | `cancel-loan-request` | `pendingBorrowerFanId` | benign — effect sets it to **null** |
| Camera Club | `cancel-request` | `requesterFanId` | benign — sets **null** |
| Garden Club | `cancel-loan`, `return-item` | `borrowerFanId` | benign — both set **null** |
| Member Social Space | `unblock` | `blockedByFanId` | benign — sets **null** |
| Member Social Space | `start-thread` | `participantAFanId` | populates `$actor`, but **prefilled at creation** |
| Youth Soccer | `submit-request` | `guardianFanId` | populates `$actor`, but **prefilled at creation** |

The distinction that makes six of them fine: **a guard reading a field its effect then CLEARS is
normal** — the borrower cancels their own request and the effect releases the field. Only an effect
that *populates* the guarded field can be self-blocking, and both such cases are rescued by a create
action's `prefill` in the same workflow.

Two checks that sweep needs, both of which nearly went wrong: confirm the effect's **value** (`null`
versus `$actor`) before calling anything a defect, and confirm the rescuing `prefill` sits in the
**same workflow** as the transition — Youth Soccer's prefill is 150 lines away from its guard and a
neighbouring workflow's prefill would have proved nothing.

### Catching an exception inside a transaction boundary commits the writes it was meant to undo

Found 2026-09-09 in the workflow service, verified by reading both ends. `_handle` wraps the entire
request in `_communityTransactionRunner(communityId, ...)`. Inside that, `_withItemQueueRequest`
catches every exception and returns an HTTP 500 `Response`. **A returned Response is normal
completion to the transaction runner**, so PostgreSQL commits whatever the handler already wrote.
The concrete failure: if anything throws after `repository.join` has inserted — the re-read, the
position computation, the response construction — the member is queued and the client is told the
request failed.

`_database.transaction` does not save you: `database.dart:884` executes the callback directly when an
outer executor already exists, creating **no nested rollback boundary**. Wrapping a sub-section in it
looks like added safety and adds none.

**The rule: a `catch` that converts an error into a success-shaped return value must live OUTSIDE the
transaction it is protecting.** Inside, it silently converts "roll this back" into "commit this and
report failure" — the worst of both, because the client's error message is now evidence *against*
the state that actually persisted. Either map errors to responses outside the boundary, or throw a
typed abort that carries the intended response and unwrap it after rollback.

This generalizes past transactions to any scope-exit cleanup — a `catch` inside a `finally`-style
guard, a retry wrapper, a lock release. **Ask what the enclosing construct does when the block
returns normally, then ask whether your error path returns normally.** If both answers are "commits"
and "yes", the error handling is decorative.

Same family as the grep-gated commit and the wrapper that reports its agent's total failure as a
clean run: **a failure path whose observable behaviour is indistinguishable from success.**

**The A/B that proves a regression test is worth more than the test passing.** The dispatch that
fixed the transaction boundary could not run its own PostgreSQL test — no credentials on that
invocation — and said so, reporting `0 passed / 1 skipped` rather than claiming a pass. Running it
with both credential sets showed it green, which proves nothing on its own: a test asserting "the
queue table is empty after a failed join" also passes against code that never wrote anything.

The evidence came from neutralising **only** the fix (the `statusCode >= 400` abort throw), keeping
the test and the injector seam, and re-running: `Expected: empty / Actual: [Instance of
'StoredItemQueueEntry']`. The row had been committed despite the 500. Source restored afterwards and
`cmp`-verified byte-identical.

**When a dispatch adds a regression test, run it against the un-fixed code before believing it.**
Reverting the whole file usually will not compile, because the test depends on a seam the fix
introduced — neutralise the specific behaviour instead, and keep a backup you diff against on the way
back. This is the same discipline as a control query: the test must be able to fail for the reason it
claims, and the only way to know is to make it fail.

### `installCommunityPackage` is safe for the generated admin, and still destructive to anything undeclared

Settled 2026-09-09 by a live probe against a disposable handle, after a year of reasoning about it
from source. The 2026-09-01 warning — that an apply "would destroy all 11 community admin roles,
unrecoverably" — **was true when written and is no longer true**: Part A made the admin's
`community.*` grants archetype-derivable, so install now spares `<handle>-admin` and re-grants it.

The experiment, which is the shape to reuse for any "is this apply safe" question:

1. Install a minimal package under a throwaway handle. The generated admin appeared with exactly its
   five `community.*` permissions.
2. Create an **undeclared** group-scoped role holding a real permission — the canary.
3. Re-install the same package. The response said it plainly:
   `{"rolesRegistered":["zz-member"],"removedRoleIds":["zz-canary"]}`, and the admin still held 5.

**So the rule is conditional, which is exactly what a code read kept failing to settle:
`installCommunityPackage` is safe when the package declares every role that ought to exist in that
group, and destructive otherwise** — it deletes undeclared group-scoped roles whether or not anyone
holds them, bypassing `deleteRole`'s holder protections. The danger was never the admin; it is any
hand-provisioned role the package has forgotten.

Two habits this reinforces. **A dry run still proves nothing** — this needed a real apply against a
real service, in a namespace where being wrong was free. And **clean up the probe, then re-run the
gate**: both probe roles were deleted and `check_role_parity.sh` re-run clean, because an experiment
that leaves drift behind converts a one-off answer into permanent noise in a check other people
trust.

### A validator cannot flag the absence of something the grammar cannot express

Asked on 2026-09-09 why the validator let Youth Soccer's payment through, after I had described it
as "the guardian has no pay action". **It let it through because nothing is wrong with it, and my
description was false.** The guardian holds `start-checkout` ("Pay registration"), `retry-payment`
and `view-receipt` — exactly the three actions that community's product doc names. The true statement
is narrower and much less alarming: *the only transition **into `paid`** is coach-guarded.*

Structurally the package is clean, and correctly so: every state is reachable including `paid`,
`processing` has three exits, every guard is well-formed, every declared role exists. The workflow is
modelled for a world where a **payment service** completes `processing → paid`. The grammar has no
way to declare a service-completed transition, so there is no missing declaration for any rule to
detect. **The gap is a mechanism that does not exist, not a field somebody forgot.**

Two things worth carrying:

- **Before blaming the Skill or the validator for a package defect, read the package and the product
  doc.** The authored artifact matched its doc exactly here; the fault was that a human-attestation
  fallback (`record-offline-payment`) silently became the primary completion path when the service it
  backstopped was never built. That is an architecture gap wearing the costume of an authoring bug.
- **Watch the compression in your own summaries.** "No guardian path into `paid`" became "no pay
  action" in one retelling, and those claim very different things about who erred. A summary that
  drops a qualifier does not merely lose detail — it relocates the blame.

### Re-test every blocker before reporting it, because blockers rot faster than tasks

Prompted by a user challenge on 2026-09-09 — *"have you confirmed these are not already captured
patterns we already know how to solve?"* — after I had reported the same two items as "awaiting your
decision" for many consecutive ticks. Six rows audited that day:

| Row | Claimed | Actually |
|---|---|---|
| Garden regeneration | not installed | installed; the row predated the artifact by days |
| `app_group.external_resource_*` | NULL for all 24 groups | 13 groups, 10 correctly populated |
| Youth Soccer payment surface | a three-way decision for the user | superseded — the product doc and an earlier scoping already answered it |
| `.create` vocabulary | blocked by a §4/§6 contradiction | live: 12 ids, 72 grants |
| ten of eleven communities | no members | every community has 5–7 |
| `calendar.*` catalog gap | 0 deployed, blocks creation | all 9 deployed; and "blocks creation" was never the right mechanism |

**A blocker rots faster than an ordinary task, and its rot is more expensive.** A stale open task
just gets redone; a stale blocker *withholds work from the queue* and, worse, gets repeated to the
user as a decision they owe. Four of these had been fixed by later work that never circled back to
strike the row.

Three habits:

- **Re-run the blocker's own evidence before repeating it**, not the row. Every one of these was
  settled by a single live query or file read that took under a minute — and none would have been
  caught by re-reading the tracker, however carefully.
- **Check the captured patterns first.** Youth Soccer was answered by `solved-patterns.md` §18's
  rule (read the product doc's persona table) plus a scoping already written into the tracker. I had
  been treating a documented decision as an open one.
- **When a blocker turns out half-true, change the question rather than splitting the row.** The
  calendar permissions were genuinely ungranted — but `roleHasPermission` never reads them, so
  "blocks creation" was the wrong mechanism, and applying the grants would have been a live
  authorization change made for a reason that does not hold.

The general form: **a claim's age is a better predictor of its wrongness than its status tag**, and a
blocker is exactly the kind of claim nobody re-tests because its whole function is to stop you
looking.

**And search the captured knowledge before presenting a finding as new.** The same audit produced two
write-ups claiming a diagnosis this project already held, in better form:

- Youth Soccer's payment surface, which I reported for many ticks as a decision the user owed. It was
  answered by `solved-patterns.md` §18 (read the product doc's persona table) plus a scoping already
  written into the tracker, which had concluded `record-offline-payment` should be *retired* as the
  completion path rather than re-guarded.
- Masjid's five `wf_`-prefixed B25 rows. I traced them to the demo app's test harness and recorded
  that as sharper than the row's framing. **The product doc's own header already said it** — naming
  them literal `testWidgets` names, citing the three test files, stating no `LoomWorkflowDefinition`
  with those ids exists, and instructing that no JSON ever be authored for them.

Both times the derivation was correct and the effort was waste, and worse, the write-up implied the
project had not known. **Before recording a finding, grep the trackers, `solved-patterns.md`,
`keypatterns.md` and the relevant product doc for its subject.** This project's documents are unusually
good at recording *why*, which means the answer to "is this already known" is usually yes — and the
residue after that check is the genuinely new part, which is often narrower and more actionable than
the thing you set out to report. In the Masjid case the real defect was not the ids at all: it was that
the doc **disclaims them in its header while its own tables still count them**, which no amount of
re-deriving their nature would have surfaced.

**Why these rows rot the way they do: corrections are appended and originals are never struck.** The
2026-09-09 sweep kept finding the same structure — a claim, a later correction recorded elsewhere, and
the original still sitting there for the next reader to meet first. The clearest chain: "7 rows name a
workflow their package does not ship" → superseded by a 12-row finding → and the 12 was itself refined
when five turned out to be test-harness ids the product doc already disclaimed. **All three counts are
still recorded.** Likewise the install-safety question existed simultaneously as a row closed
2026-09-03 and an open `needs-user-decision` I settled by probe on 2026-09-09.

So when you correct a claim, **strike or amend the original in place**, and if it was migrated between
trackers, fix every copy — a migrated row is a duplicated claim, and correcting one leaves the other
asserting the opposite with equal authority. When you cannot strike it, say in the new text which
earlier statement it supersedes, by name, so a reader arriving at either one is pointed at the other.

**And re-test stale PROHIBITIONS first, because they cost capability rather than time.** A stale fact
costs a re-derivation. A stale "do not do X" stops the next person from trying at all, and it never
surfaces as a failure — nobody reports the thing they correctly declined to attempt. The
`🛑 DO NOT RUN apply_app_access_provisioning` warning sat accurate-when-written for eight days after
Part A had made its central claim false, and in that window it would have blocked the correct fix for
Masjid's missing `owner` role. Prohibitions also carry more authority than other rows: they are
written emphatically, they are obeyed without checking, and obeying them produces no evidence that
they are wrong. **When auditing, sweep the prohibitions before the to-dos.**

### A test run against the wrong checkout is green for the wrong reason

Twice on 2026-09-09. Both times I edited a file on Windows, ran the test **on the VM**, got a pass, and
had proven nothing — the VM was still on the previous commit, so the suite exercised the unedited
file. The first was the reference-doc mirror test after editing `solved-patterns.md`; the second was
the product-doc parsing tests after annotating Masjid's B25 rows.

It is a comfortable failure: the command is right, the suite is real, the result is green, and the
only thing wrong is *which bytes it read*. Nothing in the output mentions a commit.

**Push, pull, then confirm the change is present at the target before running anything** — a one-line
`grep -c` for the thing you just wrote, at the machine that will run the test. `grep -c "NOT A
WORKFLOW" …` returning 5 on the VM is what made the second run meaningful. This generalizes past
git: the same shape is the stale validator on :8787 answering from last week's grammar, and a
deployed service tested while the repo holds the fix.

**Related, from the same edit: annotating a row does not change what counts it.** Masjid's five
non-workflow B25 rows now read `⛔ NOT A WORKFLOW — wf_…` so a *reader* cannot mistake them, but a
naive row counter still counts six pipes and adds one. The annotation fixes the human hazard and
documents the machine one; making the denominator automatically correct needs the rows removed, or a
counter that skips marked rows. Say which of the two a fix achieves rather than implying both.

**A count measures the thing counted, not the exposure to it.** "53 distinct APIs are fake-backed"
was accurate and led to a wrong conclusion, because what mattered was how many the shipped app
*calls* — zero. The measurement to run was an import trace, not a class count, and the two differ by
the whole question. A `pubspec.yaml` dependency edge is not evidence of use either; it is what made
this look worse than it was. Before treating a count as a risk, ask what would have to be true for
each counted item to actually reach the surface you care about, and measure *that*.

### Writing a lesson down does not install it — prefer the gate to the note

On 2026-09-09 I wrote "a count measures the thing counted, not the exposure to it", and then within
the hour shipped `check_b25_status.sh` counting every manifest that *named* a workflow — including
three recording blocked or partial runs, one of which says "Not proven. No live write was performed."
The total was correct only because each blocked run happened to have a later successful manifest for
the same workflow. The tool built to stop the error committed it.

That is the general case, not an anomaly. This file is long, and its rules are recalled when something
prompts recall — which is exactly when they are least needed, because noticing the risk is the hard
part. **A rule that must be remembered at the moment of writing code will sometimes not be.**

So when a lesson can be made mechanical, make it mechanical, and treat the note as documentation of
the gate rather than the safeguard itself. Today's durable artifacts are the ones that run:
`check_role_parity.sh` (declared vs provisioned roles, proven to fail as well as pass),
`check_b25_status.sh` (recomputes the bar and refuses to print a combined figure), the
`make_b25_brief.sh` requirement that every walkthrough record `skillVersion` + `sha256`, and the three
older parity gates. The prose entries above are worth keeping, but they are reminders; these are
checks.

Two corollaries. **A report should say what it could not process** — the "unparsed: 3" line is what
sent me to the file whose title read `**BLOCKED**`, which is how the counting flaw surfaced at all; a
silently-dropped input hides the case that disproves you. And **when a number comes out right, ask
whether it came out right for the right reason** — 9 was correct by luck, and nothing about the output
distinguished luck from design.

**When evidence is keyed opaquely, read the code that writes it before inferring from what it looks
like.** The B25 judge artifacts are keyed by `screenRowId`, values like
`b25-v4-row-008-garden-export-custom-schemas-1`. I read that question three ways in one session —
joinable via the slug, then *uncomputable* because 204 ids cannot map to a 72-row bar, then joinable
via a different field — and shipped a tool asserting the wrong middle answer before catching it.

What settled it was opening the producer. `loom_ux_judges.dart` builds the id as
`b25-v4-row-NNN-${_slug(workflowId)}`, which explains everything the shape suggested and misled on: it
is a **screen** (~3 per row, hence 204 over 72), and it is *derived from* `workflowId` — so its slug
resembles a bar key precisely because it is made from one. The artifacts carry the real key,
`workflowId` plus `persona`, in 95 files. One `grep '"workflowId"'` would have settled it at the
start; I spent two passes reasoning from filenames instead.

**A derived identifier looks like its source and is not it.** The same applies to the wrapper whose
`communityId` field holds an extensionId, and to a manifest filename that is a slug of a workflow
type. Find the writer, read what it puts there, then join.

### The Claude dispatchers buffer; a zero-byte log is normal for them, not a death signal

The "confirm a dispatch is alive" guidance above was written for the **Codex** dispatchers, whose logs
stream — so an empty log there means nothing started. The **Claude** dispatchers
(`call_live_verification_agent.sh`, `call_ux_judge_agent.sh`) run `claude -p`, which **buffers its
output until completion**. A live walkthrough therefore shows a **0-byte `output.log` for its entire
run**, which is exactly the documented dead-dispatch signature, and following that rule literally
would kill a healthy agent mid-device-run.

On 2026-09-09 a Garden walkthrough sat at 0 bytes for 12 minutes. The check that settled it was two
CPU samples of the resolved pid: **733 ticks in 40 seconds** at 21:50 elapsed — busy, not blocked.
Log size told me nothing; `/proc/<pid>/stat` told me everything.

    p=<pid from pgrep -af, read and confirmed>
    a=$(awk '{print $14+$15}' /proc/$p/stat); sleep 40
    b=$(awk '{print $14+$15}' /proc/$p/stat); echo $((b-a))

**And `pgrep -f "[c]laude"` matched its own shell again** in the same tick — "2 processes" was one
agent plus the grep whose command line contained the word. That trap is already recorded twice in
this file and still caught me, which is an argument for resolving the pid and reading `pgrep -af`
output rather than trusting a count, every time.

### A brief derived by substitution carries the original's specifics

On 2026-09-09 I built the Social Space judge ticket by `sed`-substituting names into the Garden one.
The judge caught **four** claims that survived the substitution: the evidence path, "14 frames" when
there were 16, Garden's frame numbers (29/39/40/42/43), and Garden's `published`/`delisted` flow when
this workflow goes `draft` → `invited` → `connected`. It judged against the directory and manifest
that actually existed and recorded the discrepancy — the right call, and it should not have had to
make it.

**Substitution updates the nouns you thought of, never the details you did not.** Names, ids and
paths get replaced; counts, frame numbers, state names and flow descriptions do not, and they are
exactly the load-bearing parts of a verification ticket. A stale specific in a brief is worse than a
vague one, because it tells the agent a confident falsehood about what it is about to look at.

Either generate the brief from a real source — `make_b25_brief.sh` exists for this, and its output
needed no such corrections — or, after substituting, re-read the result against the artifact it
describes and check every number and state name. Cheapest check: `grep` the finished brief for the
donor's own identifiers before sending it.

### I checked one authorization layer and generalised from it — the classic form of this project's worst bug

On 2026-09-09 I re-examined the row saying zero `calendar.*` grants block calendar-workflow creation.
I found `roleHasPermission` (`part12_actor_identity_and_tabs.dart:567`) is entirely package-derived —
it walks bound workflows, `readGuard`s and transition `allowedRoleIds` and never reads
`role_permission` — and concluded the grants were "a bookkeeping asymmetry, not an authorization gap",
recording explicit advice **not** to apply them as a creation fix.

**That was wrong, and a walkthrough produced a live HTTP 403 the same day.** `roleHasPermission` is the
app shell's **tab-visibility** policy. Creation is authorized elsewhere: `workflow_service.dart:572`
resolves `resolver.permissionId(family, 'create')`, calls `_appAccessClient.checkAccess(...)` at `:592`,
and refuses on `!allowed`. Cedar's `hoa-facility-reservation` create returned 403 for `hoa-member` and
`hoa-board` alike, with `event_rsvp.create` allowed for both as a control.

**One layer's answer is not the system's answer.** This file already says a capability must be true at
every layer and that each layer has its own row — I applied that rule to *packages, catalogs,
vocabularies and provisioning*, and then failed to apply it to **authorization itself**, which has at
least two enforcement points that answer different questions. Finding the first plausible mechanism and
stopping is how a wrong "this is not a real blocker" gets written with full confidence.

**So: when concluding that something is NOT enforced, enumerate the enforcement points before
concluding.** `grep` for every caller that could refuse the operation — the shell, the service, the
engine's guards, the archetype's derived permission — and say which ones you checked. A negative claim
about enforcement is only as strong as the completeness of that list, and mine had one entry.

### Check the words someone wrote, not the version you remember

A walkthrough reported that Cedar's listing failure traced to "the only listed type with `date`/`time`-typed
**formula** fields; a package sweep found such fields in exactly one community". I paraphrased that as
"date/time formula fields", swept the packages for `"type": "date"` and `"type": "time"`, found **nine**
communities, and published the agent's cause as disproved — with a control, on a live reproduction, feeling
thoroughly rigorous.

I had dropped the word **formula**. Restored, exactly one package has formula-computed date/time fields:
Cedar, two of them, both in the one workflow type that 500s. The claim was precisely right and the
discrimination is perfect. My check tested a weaker claim of my own construction.

This is worse than the ordinary broken-query traps because **the checking discipline was fully engaged and
aimed at a strawman**. A control cannot save you when the hypothesis under test is not the one that was
made. Both times this session I judged an agent's reasoning defective, the defect was in my reading of it.

**So when checking someone else's claim, quote it before testing it** — literally re-read the sentence and
build the query from its words, not from your summary of them. The elision that inverts a finding is
usually one qualifier: `formula`, `into paid`, `only`, `declared`. Those words are doing the work, which is
why they are the ones a paraphrase drops.

### A perfectly discriminating variable can still be a passenger

Cedar's instance listing 500s with `JsonUnsupportedObjectError: Instance of 'DateTime'`. I found that
**exactly one** of the ten shipped packages has formula-computed `date`/`time` fields — Cedar — while
nine carry only stored ones and list fine, and the failing workflow type was the one carrying them. Ten
packages, perfect separation, and I wrote it into a ticket as the cause.

It was wrong. Those formulas resolve to the stored strings. The real leak is `reminderAt`: the dues
definition has an **unconditional** `reminder` block, and the read projection inserts
`WorkflowReminder.dueAtFor(...)`'s raw `DateTime` into `instanceData`. Cedar's own healthy control has a
reminder too — gated by `reminderEnabled`, which its rows do not set, so the field is absent. Cedar was
simply the only community with *both* computed date fields and an ungated reminder, and I had latched
onto the wrong one of the two.

**Perfect discrimination feels like proof and is not.** With ten samples, two correlated properties are
indistinguishable, and the one you notice first is the one you already had a mechanism for. The check
that would have caught it costs a minute: **trace one real value end to end** — read the actual stored
row, evaluate the formula against it, and see what type comes out. The two dues rows held
`"2026-09-30"` and `"17:00"`; a formula returning a stored string cannot produce a `DateTime`, and that
alone falsifies the hypothesis without any sweeping.

The implementation agent refused to build the ticket, saying a material claim in it was false. That was
correct, and it is the second time this session an agent's refusal was worth more than compliance.

### Marking a row for humans corrupted a machine key — and three of my own rules would each have caught it

To stop a counting error, I annotated Masjid's B25 first column: `⛔ NOT A WORKFLOW — wf_demo-...`. That
column is a **parsed contract** — the bundled interaction-model asset is generated from it — so my marker
became part of a `workflowId` **value**, and `b25_interaction_model_asset_conformance_test.dart` failed.
It was caught by a dispatch that ran all five suites, hours later.

Three separate rules of this project would have prevented it:

- **My own memory said that column is a parsed contract** and that changing it breaks every row for that
  community. I read that, and then checked two doc-parsing tests I guessed were the relevant ones.
- **"Verified means all five suites."** I ran three (the two doc tests and judges), saw green, and said
  verified. The consuming test lives in app-shell, which I never ran.
- **Don't put display text in a machine-read field.** A human marker and a machine key want opposite
  things: one wants to be conspicuous, the other wants to be exactly the value everything else expects.

The fix was not to regenerate the asset — that would have baked the marker into the contract. It was to
**revert the doc and move the exclusion into the tool**, matching the `wf_` prefix, which is already an
unambiguous namespace marker. **When a document is consumed by code, put the knowledge in the code and
leave the document clean.** A comment or header note is for humans; a filter is for the counter.

The general shape, and it recurred all session: **when you cannot see who reads a file, `grep` for its
consumers before editing it.** `grep -rln "<filename>" app/ --include=*.dart` takes seconds and would
have named the test I missed.

### A validator warning can outlive the thing it was warning about

`workflow_validator.dart`'s `_checkDeadRoleBinding` still flags a `calendar`-tab binding as dead
unless it uses `role: "any"`, on the premise that "the `calendar` tab passes no role-resolution
callback." That premise stopped being true on 2026-08-11 (`0eaee6484`), when
`EngineNativeCalendarSurface` started passing `rolesForInstance` — `deriveInstanceRoles` against the
viewer's fan and role ids — into the shared binding dispatcher, the same mechanism Marketplace uses.
`render-bindings.md` documents audience resolution as guard-derived and tab-independent; the
validator's check is the one place still treating it as tab-dependent.

A later tracker row (dated 2026-09-06, "re-measured") had already proposed a fix for this — but
proposed porting a whole renderer-reconciliation mechanism into the validator, which would have
generalized a warning whose underlying claim was already false by the time the row was written. Root
cause agent sweep confirmed both halves independently: the validator's exact claim (verified by
reading `workflow_validator.dart:602,622`), and the calendar surface's actual behavior (verified by
reading `part28_engine_native_calendar_surface.dart:200` and its git blame).

**A validator check and the code it checks are two independent things that can drift apart, same as
any other pair of layers in this project** — the validator doesn't get an exemption from the
"a capability has to be true at every layer" rule just because it's the thing doing the checking. The
fix here is to retire the two obsolete checks and their finding-code declaration, not to build the
mechanism the stale warning implied was still missing.

### An unwritten field may be an honest declaration — read its comments before calling it an orphan

Three "orphan field" findings in three days, all mine, all wrong, all produced the same way: grep for
a writer inside one scope, find none, report a defect.

| Field | Why "no writer" was wrong |
|---|---|
| Cedar `explicitReaderFanIds` | written by a **paired workflow** (`hoa-document-access-request`) via a cross-type effect; my grep covered only the document workflow's own transitions |
| Chess seed `createdByFanId: "chess-member"` | **correct** under the shell's identity model, which aliases fan id to role id — "fixing" it would have broken the demo app |
| Ad-Free `paymentConfirmationId` | the package **says so itself**, at both declaration sites: *"NEEDS IMPLEMENTATION (platform service)… intentionally never seeded or effect-written"* |

The third is the cheapest to avoid and the most embarrassing to miss: the answer was a comment
attached to the very lines I was reading. **There are 18 such `NEEDS IMPLEMENTATION` annotations
across five shipped packages** — Ad-Free 6, Book Club 5, Masjid 4, Cedar 2, Youth Soccer 1 — and they
are the visible surface of the four missing platform services (payment, id generation, external
search/AI, checksum), not per-package authoring defects. No Skill dispatch can fix one.

**Before reporting a field as unwritten: read the declaration's own comments, check for cross-workflow
effects targeting it, and confirm which identity model its values live in.** `hideWhenEmpty: true` on
such a field is the *correct* pairing, not evidence of concealment — it is the opposite of the
export-checksum shape, where a field claimed a writer it never had. A field that declares it has no
writer is honest; a field that implies one is the defect.

### The app shell has no member directory: it derives "identities" from roles, aliasing `fanId` to `roleId`

**Traced end to end 2026-09-10. This is not a demo-only quirk — it is the only way the shell can
produce an actor identity from a package, and it runs in production.**

    package declares      roles: [{ roleId: "chess-member", label: … }]
      ↓  part15_evidence_catalog.dart:176   actorIdentities derived from `roles`
    _parseActorIdentity:398                 LoomActorIdentity(fanId: roleId, roleId: roleId)
      ↓  part01_local_extension_screen.dart:540
    picker candidate                        AudienceMultiSelectCandidate(roleId: …)
      ↓  part33_generic_creation_card.dart:192   (any field of type fanId[])
    stored value                            participantFanIds: ["chess-member", "chess-organizer"]

**Zero of the ten shipped packages declare `actorIdentities`**, so every one of them goes through
that derivation. `part15:785`'s legacy catalog aliases the same way (14 pairs), so both paths agree —
a fan id is a role-id-shaped string *to the shell*, always.

The backend does not agree: there a fan is `fan-chess-member-1` and `chess-member` is a role. **The
seam is visible in a single shipped row** — Chess's `participantFanIds` holds
`["chess-member", "chess-organizer", "fan-chess-member-1"]`, where the first two came from the picker
and the third from the create action's `prefill: ["$actor"]`, `$actor` being the genuinely
authenticated fan. Two writers, two identifier spaces, one array.

**Consequence to take seriously:** seven Chess transitions guard on that field via `actorInList`, so
role ids sitting there mean no real fan matches and those transitions are dead for everyone on that
row. Any community with a `fanId[]` field filled through the creation card has the same exposure.

**So "add a member picker" understates the work.** The shell cannot currently answer "who are the
members of this community" at all — there is no directory contract, which is why the fix is a new
capability rather than swapping one widget for another.

**Everything that looks like an identifier-space bug in this area is downstream of that one
assumption, and several of those things are correct relative to the shell while wrong relative to the
backend:**

| Artifact | Under the demo model | Under the production model |
|---|---|---|
| Chess seeds' `createdByFanId: "chess-member"` | correct | a role id in a fan-id field |
| `AudienceMultiSelectPicker` writing `roleId` into a `fanId[]` | harmless | corrupting |
| `v3_milestone_phasef_messages_test.dart`'s aliased fixture | faithful to the catalog | cannot discriminate |

So the live Chess row holding `["chess-member", "chess-organizer", "fan-chess-member-1"]` is exactly
what you get when a **production** instance is created through a UI path built for the **demo**
aliasing — a mixed array being the visible seam between the two models.

**The operational rule: before "fixing" a role-id-shaped value in a fan-id field, establish which
identity model that artifact runs under.** On 2026-09-10 I had a Skill dispatch queued to "correct"
the Chess seed and checked the convention first; the fix would have broken the demo app, where the
actor identity genuinely is `chess-member`. A validator rule banning role-id-shaped literals in
`fanId` fields is wrong for the same reason — it would have to know which model applies, which is the
actual open question.

### A fixture whose identifiers alias across spaces cannot discriminate an identifier-space bug

`v3_milestone_phasef_messages_test.dart:305` drives the real creation FAB, taps the audience picker,
and asserts `instanceData['participantFanIds'] == ['tabletop-member']`. It passes today. It would also
pass if the value arrived from the **role** picker instead of the actor's **fan id** — because in that
fixture the fan id and the role id are the *same string*, `tabletop-member`. The test's own comment
says "the generic form uses the existing audience-style picker for participantFanIds", documenting the
defect as intended behaviour.

That defect is real and shipped: for a `fanId[]` field the creation card renders
`AudienceMultiSelectPicker` (`part33_generic_creation_card.dart:192`, parameter literally
`selectedRoleIds`) over candidates built from `experience.actorIdentities` carrying **`roleId`**
(`part01_local_extension_screen.dart:540`). Selecting two roles writes two role ids into a fan-id
array — which is how a shipped Chess row came to hold `["chess-member", "chess-organizer",
"fan-chess-member-1"]`.

**When a bug is "the wrong identifier space reached this field", every fixture in the test must keep
those spaces textually distinct** — fan `fan-x`, role `x-member`, never the same token for both.
Otherwise the assertion is satisfied by both the correct and the incorrect provenance, and it will
keep passing after someone "fixes" it in either direction. Same family as the grep-gated commit: the
success condition is met by the failure it exists to catch.

The wider lesson for this project specifically: **"prefer selecting an existing value over typing one"
is not unconditionally safe.** That rule was written after `adb shell input text` silently truncated
`payerFanId`, and it is right about typing — but on this path the *picker* is the thing that
manufactures invalid data, and selecting is worse than typing. A control is only as correct as its
candidate source and the contract of the field it writes into.

### A documented invariant with no mechanical guard is a wish, and I broke this one twice myself

`permissions.md:522` says "only the admin role holds `community.*`". On 2026-08-31 I put the five
governance grants on Masjid's package *domain* role because its id was `masjid-admin` and its label
"Masjid Admin" — classifying a role by its name, in the same session that wrote "not just a name that
reads like admin". On 2026-09-02 a documented SQL recipe copied that mixed role — label, 28 grants,
holder — into the generated `masjid-nur-admin` id, with the mapping literally saying "preserve all 28
grants" and an anomaly note nobody resolved. The platform accepted both steps because it has no
notion of role **kind**: `app_role` cannot distinguish a package domain role from the generated
governance role, `createRole`/`setRolePermissions` check only that a permission id exists, and
`check_role_parity.sh` compares role *existence*, so it passed the whole time.

Three things to carry, found while root-causing it on 2026-09-10 (session key `b25-provisioning`):

- **When a reference doc states "only X may hold Y", find the line of code that refuses otherwise.**
  If there is none, the doc describes an intention, and the next operator under time pressure will
  violate it in good faith. The fix is a kind column plus a write-time rule plus an exact-set parity
  gate — a prose rule in this file would have been the fourth restatement of an invariant that was
  already written down.
- **Enumerate the authorization layers before saying what a leak *does*.** I wrote "every Masjid admin
  can fire the four owner-only transitions". False: engine guards intersect real role ids
  (`guard_evaluator.dart:29-37`), never permissions, so the over-granted admin fails those guards. The
  violation is real at the App Access layer (`checkAccess` grants it domain allowances) and absent at
  the engine layer. Same trap as the calendar-permissions row — one layer's answer is not the system's.
- **Check who is allowed to *write* policy, not only who is allowed to act.** The agent found that
  `createRole`, `setRolePermissions` and `installCommunityPackage` have no caller authorization beyond a
  valid JWT — the membership endpoints call `requireGroupAdministrator`, the policy endpoints do not —
  and app-access is a NodePort. Any seeded fan can rewrite any role's grants today. Every prior audit of
  this service checked *decisions* (`/v1/access-decisions`) and never asked who may change the inputs
  to them.

And the operational rule that follows: **domain-to-governance is never a rename.** A governance role is
created separately and assigned deliberately; copying a domain role's grants into a governance id is
how you get an admin that can do what an owner can, and a schema that cannot tell you it happened.

### A smoke test that only exercises turn one proves nothing about ticket-length work

Switched the implementation agent's default to DeepSeek V4 Flash on 2026-09-11 (the OpenAI/Codex
account had run out of usage credits) and verified it with `codex exec -p deepseek_v4_flash` replying
`READY` to a one-line prompt. It worked. That proved the wiring — the gateway, the profile file, the
provider table — and nothing about reliability, because a one-shot prompt never exercises a second
turn.

The first two real tickets dispatched on that profile (P4, P6 of the authorization programme) both
failed identically, well into genuine multi-turn tool use, burning ~127k tokens for zero code
written:

    {"error":{"message":"The `reasoning_content` in the thinking mode must be passed back to the
    API.","type":"invalid_request_error"}}

Root cause, read from the gateway's own `protocol.mjs`: DeepSeek's thinking-mode contract requires
every tool-call-bearing message to carry `reasoning_content` on replay, with no exception for "the
model didn't produce much reasoning for that call." When DeepSeek itself emits a thin/empty
`reasoning_content` for a turn — normal whenever a turn is "say something, then call a tool" as two
separate steps rather than one — the gateway's in-memory fallback store has nothing to cache for that
turn either, since it only ever stores a *non-empty* value. The very next replay of that turn is then
rejected outright by DeepSeek's own API, discarding the whole request. Longer, more tool-call-heavy
prompts hit this far more than trivial ones simply because there are more chances for a thin-reasoning
tool-call turn to occur — which is exactly why the smoke test passed and the real work didn't.

**This was already a known, already-solved problem in this project's own memory before today**
(`deepseek_thinking_mode_breaks_multiturn`: *"reasoning_content only kept for tool-call turns; use
DEEPSEEK_THINKING=disabled"*) — from a different, earlier DeepSeek integration. I switched a new
gateway's thinking mode to `enabled` without checking whether this project had already hit this exact
class of failure. Setting `DEEPSEEK_THINKING=disabled` in the gateway's `.env` fixed it immediately:
verified with a deliberately tool-call-heavy smoke test (two sequential shell calls, one of which
genuinely errored), then a real ticket re-dispatch that ran substantially further than either failed
attempt before this was written. The trade is accepted deliberately: no chain-of-thought, in exchange
for not discarding real work partway through a dispatch.

**Two habits, not one.** First, the one already written elsewhere in this file: search the captured
patterns before concluding something is new — a `grep` across `keypatterns.md` and this file for
"DeepSeek" would have surfaced the fix before the first real dispatch, not after two failed ones.
Second, specific to model/engine switches: **a smoke test must exercise a second turn before it
counts as verification for anything that will do multi-turn tool-calling work.** "Reply with one
word" and "drive a real ticket" are different claims wearing the same green checkmark, and the gap
between them is exactly where this broke, twice, at real cost.

### An anchored sentinel match is still not enough when a transcript can quote another log

`watch_dispatch_log.sh` (and every ad-hoc `grep "^codex exec exited with status"` waiter used earlier
this session) assumed that anchoring a match to the start of a line was sufficient to identify the
wrapper's own completion line — a fix for an *earlier* false-positive class where the sentinel
appeared mid-line inside JSON content. Found 2026-09-11, live, on the same DeepSeek dispatches above:
during P4, the agent's own transcript dumped an **older** dispatch log's contents while investigating
tooling conventions, and that older file itself started a line with `codex exec exited with status 0`
— the exact wrapper-echo format, from whichever run had originally produced it. That text streamed
through `tail -F` like any other new output and matched the anchored pattern, indistinguishable from
a real completion. Anchoring does not help here: the embedded line legitimately starts a real line
too, it is simply not *this* dispatch's own exit line.

Confirmed with byte-level evidence: P4's log had `codex exec exited with status 0` at line 812 while
`codex exec` was still genuinely running (confirmed via a live pid), and the true final line, `codex
exec exited with status 1`, did not appear until line 1505 — several minutes and ~700 lines later. A
first-match check reported completion, and the wrong status, while the dispatch was still working.

**The fix generalizes past this one script: when a sentinel is text a dispatch could plausibly quote
from another file, text matching alone can never be sufficient, anchored or not.** The disambiguator
that works: the wrapper's real completion line is followed almost immediately (under a second, a few
`git status` commands, then EOF) by the wrapper process itself exiting; an embedded occurrence has no
such property, because the process that would need to exit is the dispatch's own long-running child,
which keeps running for as long as the dispatch has left. `watch_dispatch_log.sh` now confirms a
match by polling the tracked dispatch pid for up to 20 seconds before trusting it, and treats a match
that outlives that window as an embedded false positive rather than a real completion — see the
script's own 2026-09-11 header note for the full mechanism. Same family as the `grep -c`/binary-log/
own-command-line traps already recorded above: a check whose signal can be produced by something
other than the thing it claims to detect is not a check, however precisely the pattern is written.
