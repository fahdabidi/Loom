# B25 live walkthrough evidence — Cedar Commons HOA (local mode)

**Date:** 2026-09-04
**Community:** Cedar Commons HOA (`community_cedar_commons_hoa`)
**App:** `loom_communities_demo` debug APK, Loom `60f8f498`, `LOOM_ENV=local` + preload
**Device:** Windows emulator `emulator-5554` (AVD `loom_win`, 1080×2400)
**Persona:** "CedarResident" → auto-assigned role **Homeowner** ("2 roles")
**Mode:** local (persona-picker + `LocalWorkflowEngineApi`) — no Chrome, no ANR

> Companion to `garden-club-local-walkthrough-2026-09-04.md`. Together these two show the rig renders
> two **structurally distinct** community types correctly (different theme, tab set, and workflows),
> which is the meaningful breadth check that the same rig works for all 10 preloaded communities.

## Observed (live, on device)

| Aspect | Garden Club (green) | Cedar Commons HOA (blue) |
| --- | --- | --- |
| Tab set | Home / Calendar / **Marketplace** / **Care** | Home / Calendar / **Giving** / **Documents** |
| Role auto-assigned | Member | **Homeowner** |
| Home affordances | offer/request plant, export | HOA record/document surfaces |
| Documents | (n/a) | **Cedar Commons CC&Rs**, **Version 2025.3**, **Publication date 2025-11-18**, Provider chip |

Cedar member card: "Homeowner - Pays dues, reads governing documents, reserves facilities, and submits
property requests." The four HOA workflows (dues/Giving, facility reservation/Calendar, governing
Documents, property requests) are all present in the rendered tab set.

## Result
The rig correctly renders a second, structurally different community end to end with its own theme,
tabs, role, and workflow affordances. Local-mode B25 rig confirmed across community types.

## Remaining (unchanged from the Garden Club manifest)
Rigorous 79-row certification (primary + alternate affordance per row + UX-judge pass across all 10
communities) is the focused pass. **Blocker surfaced 2026-09-04:** the purpose-built agents
(`call_live_verification_agent.sh` / `call_ux_judge_agent.sh`) run `claude -p`, but the `claude` CLI
is not available where the emulator lives (Windows) and the emulator is not reachable from the VM — a
host split that blocks the efficient agent-driven grind until `claude` is installed on the Windows
host (or adb is networked VM→Windows). Manual driving works but is slow at 79-row scale.
