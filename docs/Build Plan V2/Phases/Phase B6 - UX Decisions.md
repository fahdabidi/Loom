# Phase B6 - UX Decisions

Status: Completed

Purpose: document UX research, extracted patterns, decisions, implementation impacts, workflow
walkthrough, and tradeoffs for required Messages and Connections navigation, direct/group messaging,
connection invite/block, stream rendering, in-stream ad disclosure, top banner ad behavior, and no-fill
states.

## Reference Sources Reviewed

| Reference | Surface / Flow Reviewed | Why It Applies | Patterns Observed | Applicability / Gaps | Date Reviewed |
| --- | --- | --- | --- | --- | --- |
| [Material 3 navigation drawer](https://m3.material.io/components/navigation-drawer/overview) | Persistent access to top-level app destinations | Loom must keep Messages and Connections available even inside extensions. | Navigation drawers provide access to app-level destinations and preserve orientation across views. | Loom may use drawer/rail/bottom-nav variants later; B6 validates contract, not final layout. | 2026-06-09 |
| [Material 3 badges](https://m3.material.io/components/badges) | Notification/count affordance on navigation items | Messages and Connections will eventually need unread/request counts. | Badges communicate counts/status without replacing destination labels. | B6 validates reachability only; unread counts are later UI detail. | 2026-06-09 |
| [Messenger message request settings](https://www.facebook.com/help/messenger-app/2258699540867663) | Message delivery/privacy controls | Connections and message requests need privacy controls. | Unknown contacts route through request/privacy settings rather than direct conversation access. | Loom B6 models invite/block behavior, not full request inbox UX. | 2026-06-09 |
| [Messenger message request block/delete](https://www.facebook.com/help/messenger-app/984163458313035) | Accept/delete/block message requests | Block behavior must prevent further invite/message initiation. | Requests can be opened, deleted, or blocked from the request surface. | Loom models connection block at component level; reporting/moderation is later trust work. | 2026-06-09 |
| [Google AdMob native ads playbook](https://admob.google.com/home/resources/native-ads-playbook/) | Native/in-stream ad placement and styling | Loom stream ads must fit the stream without hiding disclosure. | Native ads can match surrounding content but need thoughtful placement and visual clarity. | B6 uses a minimal stream item model; final ad creative rules are in ad-delivery architecture. | 2026-06-09 |
| [FTC native advertising guide](https://www.ftc.gov/business-guidance/resources/native-advertising-guide-businesses) | Sponsored-content disclosure | Loom must avoid ads disguised as member content. | Required disclosures must be clear and prominent when needed to avoid deception. | Legal/policy review will refine copy; B6 locks `Sponsored` disclosure. | 2026-06-09 |
| [Google AdMob native ad load docs](https://developers.google.com/admob/android/native) | Native ad loading and render responsibility | Top banner and in-stream ads need fill/no-fill states. | Apps receive ad assets and are responsible for displaying them in native UI. | B6 validates decisions and no-fill reasons, not SDK integration. | 2026-06-09 |

## UX Patterns Extracted

| Pattern | Source References | User Problem Solved | Loom Application | Risk / Constraint |
| --- | --- | --- | --- | --- |
| Required platform destinations remain visible independent of extension UI | Material navigation drawer, badges | Users need reliable access to messages/connections across communities. | App Shell contract exposes Messages and Connections and B6 proves extensions cannot suppress them. | Exact layout may vary by device; contract must be stable. |
| Blocked connection targets are disabled before invite is sent | Messenger request/block references | Prevents unwanted contact and avoids confusing post-send errors. | Connections Graph and Connections Shell both reject blocked targets. | More nuanced request states come later. |
| In-stream ads match the stream but keep clear disclosure | AdMob playbook, FTC native advertising guide | Ads should not feel jarring or deceptive. | Stream renderer uses `kind=ad` and `disclosure=Sponsored`. | Sponsored copy may require jurisdiction-specific policy later. |
| No-fill is a valid required ad-slot state | AdMob native ad load docs | Empty ad inventory should not collapse required shell structure. | App Shell top ad slot remains required even when status is no-fill; ad decision records reasons. | Designers must avoid placeholder clutter. |
| Sensitive contexts produce no-fill | Ad platform safety/policy references, Loom T7/T8 | Private care/protected-data contexts should not monetize sensitive disclosures. | Ad Decision returns `noFill` with `sensitive-context`. | Sensitive classification must become richer than a boolean later. |

## Key UX Decisions

| Decision | Rationale | Applies To | Acceptance Signal / Test |
| --- | --- | --- | --- |
| Messages and Connections are shell-owned required destinations. | Members need cross-community access even when inside custom extensions. | App Shell, Navigation Panel. | `wf_messaging-ads-connections`, `vt_app-shell_required-nav`, `vt_navigation-panel_messages-connections`. |
| The required top banner ad slot remains present during no-fill. | Platform ad surfaces cannot be suppressed by extensions; no-fill is state, not absence. | App Shell, Ad Slots. | `wf_messaging-ads-connections`, `vt_app-shell_ad-slots`. |
| In-stream ads are rendered as stream items with explicit `Sponsored` disclosure. | Native ads can blend into content only when the paid nature is clear. | Stream Renderer, Ad Decision. | `wf_messaging-ads-connections`, `ct_ad-decision__stream-renderer_in-stream-ad`. |
| Block state is enforced in both data and shell affordance layers. | Users should not be invited when the graph blocks the target, and the UI should prevent the action. | Connections Graph, Connections Shell. | `wf_messaging-ads-connections`, `vt_connections-shell_invite-blocked`. |
| Sensitive context ad decisions must no-fill. | Ads in private/protected contexts are a trust risk. | Ad Decision, Protected Vault policy. | `wf_messaging-ads-connections`, `vt_ad-decision_sensitive-no-fill`. |

## Key Implementation Decisions

| Implementation Decision | UX Impact | Owning Component | Tests / Gates |
| --- | --- | --- | --- |
| Compose the workflow from existing App Shell props rather than adding new UI widgets. | Validates invariant contracts without locking final visual layout prematurely. | app-shell-runtime, navigation-panel, stream-renderer, ad-slots | `wf_messaging-ads-connections`, A6 tests. |
| Use real connection graph invite/block state plus shell blocked-target props. | Proves both backend policy and UI affordance behavior. | connections-graph, connections-shell | `wf_messaging-ads-connections`, A1/A6 regressions. |
| Use ad campaign + ad decision fakes for fill/no-fill. | Tests actual ad eligibility behavior rather than static fixture assertions. | ad-campaign-service, ad-decision-service | `wf_messaging-ads-connections`, A4b regressions. |
| Keep `Sponsored` as the canonical disclosure token for B6. | Gives downstream visual work a stable acceptance string. | stream-renderer | `wf_messaging-ads-connections`, A6 stream tests. |

## Workflow Walkthrough

| Step | User Goal / Action | Screen or State | Owning Component | UX Decision Applied | Covering Test |
| --- | --- | --- | --- | --- | --- |
| 1 | Open required nav | Shell exposes Home, Messages, Connections, and required top banner. | app-shell-runtime, navigation-panel, ad-slots | Required shell-owned destinations and ad slot. | `wf_messaging-ads-connections` |
| 2 | Send message | Community stream contains member and owner messages. | messaging-stream-service | Message stream validates local communication. | `wf_messaging-ads-connections` |
| 3 | Invite/connect/block | Invite succeeds for allowed target; blocked target cannot be invited. | connections-graph, connections-shell | Block enforced in graph and shell. | `wf_messaging-ads-connections` |
| 4 | Render stream item | Message stream item is present and source-linked. | messaging-stream-service, stream-renderer | Stream item contract remains stable. | `wf_messaging-ads-connections` |
| 5 | Insert in-stream ad | Eligible in-stream campaign fills and renders with Sponsored disclosure. | ad-decision-service, stream-renderer | Sponsored disclosure is mandatory. | `wf_messaging-ads-connections` |
| 6 | Show top banner/no-fill state | Required top banner exists; fill/no-fill is decided by ad service. | ad-slots, app-shell-runtime, ad-decision-service | No-fill is a valid required-slot state. | `wf_messaging-ads-connections` |
| 7 | Verify extension cannot suppress required surfaces | Local extension opens while shell invariants remain true. | app-shell-runtime, loom-communities-demo-app | Extensions cannot hide Messages, Connections, or required ad slots. | `wf_messaging-ads-connections` |

## Open Questions / Tradeoffs

| Question / Tradeoff | Options Considered | Recommendation | Owner | Resolution Required Before |
| --- | --- | --- | --- | --- |
| Should unread badges be part of B6? | Add unread count contract now; validate reachability now. | Validate reachability now; add counts when message inbox UI is built. | App Shell + Messaging | Inbox visual implementation |
| Should stream ads reserve layout space before fill? | Reserve slot always; insert only on fill; show no-fill placeholder. | Insert only on fill in stream; reserve required top banner separately. | Ads + UX | Stream renderer visual design |
| Should connection blocks trigger moderation/reporting flows? | Block only; block plus report; block plus incident case. | Block only in B6; trust/safety workflows own report escalation. | Trust/Safety | Moderation workflow phase |

## WSL Ubuntu Tooling Requirement

Run all phase tooling from WSL Ubuntu, not Windows PowerShell. Use this command shape from the Windows host:

```powershell
wsl.exe -d Ubuntu -- bash -lc 'cd "/mnt/c/Users/fahd_/OneDrive/Documents/Loom/app" && <command>'
```

Inside WSL Ubuntu, `dart`, `flutter`, and `melos` must resolve from the Ubuntu toolchain. Do not run Dart, Flutter, Melos, package validation, manifest gates, phase gates, or workflow tests from Windows-native shells.

## Commit Gate

Before starting the next phase:

- Stage only this phase's intended changes.
- Run `git diff --staged` and confirm the staged scope matches this phase.
- Commit the phase changes.
- Record the resulting commit SHA in [../Build Tracker.md](../Build%20Tracker.md).
- Do not begin the next phase until the commit exists and the tracker points to it.
