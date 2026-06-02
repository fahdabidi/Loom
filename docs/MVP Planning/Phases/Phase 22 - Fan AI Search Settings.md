# Phase 22 — Fan AI Search Settings & Source Connections

**Surface:** Fan App · **UX gate:** HIGH · **On green:** STOP for UX
**Shared conventions:** [README.md](./README.md).

> **Status:** Ready for execution after Phase 21. Adds a fan **Settings** surface where a fan connects
> their own **AI search agent** (Claude / OpenAI / Gemini via MCP, simulated), enables **external content
> sources**, (simulated) connects **YouTube**, and sets a **"prefer creator content"** default. This is the
> supply side of the "bring your own AI to search" story — Phase 23 consumes the config. Mirrors the Phase 5
> summary-first agent toggle, expanded into a real settings screen.

## 0. Prerequisite gate (validate Phase 21 done)
README gate + confirm Phase 21 committed/recorded: AI-search/external-source/agent-config contracts + fakes +
store + YouTube seed exist; Phase 21 integration tests pass.

## 1. Workflows & user stories in this phase
- **FE-S16 / connect AI search agent** — Fan picks a provider (Claude/OpenAI/Gemini/custom) and connects via
  an MCP endpoint/token; connection state is shown (simulated; real-OAuth/MCP noted as production path).
- **FE-S16 / enable external sources** — Fan enables external content in search and (simulated) **connects
  YouTube**; other source types (twitch/discord/blog/webpage) shown as available/coming.
- **FE-S16 / prefer creator content** — Fan toggles the default that creator content is preferred when it matches.
- Disclosure: settings state that the fan's agent receives query context (data egress to the fan's chosen provider).

## 2. Tools (WSL Ubuntu)
Standard set. Emulator screenshots of the settings surface (connected vs disconnected states).

## 2A. UX reference research & decision output
Record in [Phase 22 - UX Decisions.md](./Phase%2022%20-%20UX%20Decisions.md):
- Account/integration settings patterns (connected services, provider pickers, connect/disconnect, status chips).
- MCP/agent connection UX (endpoint + token field, test/verify, scoped-access disclosure).
- Privacy-forward consent copy for query egress to a third-party AI provider.

Apply the shared baseline plus: settings live behind a profile/account entry (not cluttering discovery); the
agent connection uses labels + icons for clarity; connect actions are explicit and reversible; copy is honest
that connections are simulated in the demo and what a real connection would do.

## 3. APIs invoked & stubs to implement
No new API surfaces. Reuse Phase 21:
- **Fan Vault API:** `getSearchAgentConfig` / `putSearchAgentConfig` (provider, MCP endpoint, preferCreators, externalSourcesEnabled); external-source connection get/put.
- Validation only; no AI call happens here (search runs in Phase 23).

## 4. Data storage (local store)
No new tables. Read/write `fan_search_agent_configs` and `external_source_connections` from Phase 21. Confirm
`resetDemo()` restores defaults (disconnected, preferCreators=true).

## 5. Source files & components to create/update
- New feature package `features/fan/feature_fan_settings/` (route/entry, controller/view-model, mappers) —
  imports contracts + design system + app_shell only.
- Design system: `settings/settings_section.dart`, `settings/connected_service_row.dart`,
  `settings/agent_connect_sheet.dart` (provider picker + endpoint/token + connect), `settings/toggle_row.dart`.
- App shell / fan nav: add a Settings entry (profile/account menu or toolbar), reusing the existing account chip.

## 6. API best-practice checks (phase-specific)
- Config writes are **idempotent** + versioned; connect/disconnect are reversible.
- No secrets persisted beyond demo scope; connection is simulated (no real network/token exchange in this phase).
- Disclosure of query-egress is shown before enabling the agent (ties to Data Rights).

## 7. Component boundary / design checks
- Settings components live in `loom_design_system`; connect/persist logic in `feature_fan_settings`.
- No feature→feature/fake/store imports; `lint:boundaries` clean; charter added.

## 8. Automated validation checks
README baseline plus unit/widget tests: provider selection + connect/disconnect persists; prefer-creators and
external-sources toggles persist; disclosure shown before enabling; `resetDemo()` restores defaults.

## 9. Integration tests
- `it_p22_connect_agent` — Fan opens Settings, connects a (simulated) Claude agent + enables external sources + connects YouTube; state persists and re-renders as connected.
- `it_p22_prefer_creators_default` — Toggling prefer-creators persists and is readable by the search path (consumed in Phase 23).

## 10. Definition of done
A fan can connect an AI search agent, enable external sources, (simulated) connect YouTube, and set
prefer-creators — all persisted and reversible, with query-egress disclosure; all checks + integration tests
green; emulator screenshots captured. [Phase 22 - API Review.md](./Phase%2022%20-%20API%20Review.md) and
[Phase 22 - UX Decisions.md](./Phase%2022%20-%20UX%20Decisions.md) filed; tracker updated with status, date,
API review, gate evidence, and commit SHA.

## 11. Next phase
After Phase 22 changes are committed and recorded, **AUTO-PROCEED: immediately begin
[Phase 23 — AI Search Results: creator + external, agent ranking, title normalization](./Phase%2023%20-%20AI%20Search%20Results.md).**
