# Phase 5 — AI Archive Q&A

**Surface:** both · **UX gate:** med · **On green:** AUTO → Phase 6
**Shared conventions:** [README.md](./README.md).

## 0. Prerequisite gate (validate Phase 4 done)
README gate + confirm: content has summaries (Phase 2), `AIContentPolicy` enabled for the demo creator (Phase 2), discovery feed exists (Phase 3, for the summary-rank hook). Phase 4 integration tests pass.

## 1. Workflows & user stories in this phase
- **FE-S7 / FE-W11** — Fan asks a creator's archive → cited answer.
- **RE-S9** — BYO-agent "rank by summary, ignore clickbait" preference re-orders the discovery feed.
- **MN-S5** — Creator earns AI source royalties (source-attribution receipts).
- (Creator enablement `CE-W7` already done in Phase 2.)

## 2. Tools (WSL Ubuntu)
Standard set. Seed transcripts/summaries for a few of the demo creator's items so Q&A has grounding.

## 2A. UX reference research & decision output
Before implementing archive Q&A UX, review reference mockups and design guidance from popular social/search/AI surfaces such as YouTube search/comments, Instagram/TikTok creator content surfaces, Facebook search/groups, WhatsApp chat patterns, and established cited-answer products. Focus on question entry, answer cards, citations/source previews, creator attribution, confidence/disclosure, receipt visibility, and how AI controls appear without overwhelming content consumption.

Apply the shared social-app UX baseline from [README.md](./README.md), plus these Phase 5 specifics:
- Treat archive Q&A as a social search/chat hybrid: a focused question composer, recent/suggested prompts, answer cards, citation chips, and source preview sheets.
- Keep cited answers scannable: short answer summary first, expandable details second, then creator/source attribution and receipt status.
- Use WhatsApp-style message clarity for the question/answer flow without making the surface look like a generic chat app; Loom content and creator provenance should stay prominent.
- Put AI policy, confidence, and source-royalty disclosure behind clear info chips or sheets so the answer surface remains usable.
- The summary-first ranking preference should appear as a compact toggle/filter with an obvious why-shown note when it changes discovery ordering.

Create [Phase 5 - UX Decisions.md](./Phase%205%20-%20UX%20Decisions.md) summarizing references reviewed, UX patterns extracted, key UX and implementation decisions, and a walkthrough of how the implemented UX demonstrates fan archive questions, cited answers, source-attribution receipts, and summary-first ranking controls using the collected guidance.

## 3. APIs invoked & stubs to implement
- **AI Gateway API:** `askArchive` (question + scope + policy ref → answer + **citations**), `rankBySummary` (re-rank eligible candidates using summaries; sets `summaryUsedForRelevance` / `titleDeemphasized`). Fake: `AiGatewayFake` (deterministic canned answers keyed to seed transcripts).
- **Creator Metadata API:** read `AIContentPolicy` + `summary`/transcript refs (reuse fake).
- **Receipt Ledger API:** ingest `AIUsageReceipt`, `SourceAttributionReceipt`. Reuse `ReceiptLedgerFake`.
- **Fan Vault API:** store the BYO-agent ranking preference (reuse `FanVaultFake`); `feature_discovery` reads it (no cross-feature dependency).

## 4. Data storage (local store)
New tables: `transcripts(contentId, segments[])` (seed), `ai_sessions(fanId, memoryPolicy)`, receipts extended for AI types. Fan Vault gains `rankingPreference` (summary-first on/off).

## 5. Source files & components to create/update
- `core/loom_api_contracts/clients/`: fill `ai_gateway_api.dart`. Models: `ArchiveAnswer`, `Citation`, `RankPreference`, `AIUsageReceipt`, `SourceAttributionReceipt`.
- `core/loom_fake_backend/`: `ai_gateway_fake.dart`; extend `receipt_ledger_fake.dart`.
- `core/loom_design_system/components/`: `qa_answer_card.dart` (answer + citation chips), `citation_link.dart`, `byo_agent_toggle.dart`.
- `features/fan/feature_ai_qa/`: screens `archive_qa`; `qa_notifier`; mappers; `CHARTER.md`.
- `features/fan/feature_discovery/`: read `rankingPreference` from Fan Vault and pass to `getFeed`/`rankBySummary`; render why-shown note when summary-first changed order. (No import of `feature_ai_qa`.)

## 6. API best-practice checks (phase-specific)
- `askArchive` request is one call: question + scope (creator/content) + policy ref; the answer carries citations (source ids) → each cited source yields a `SourceAttributionReceipt`.
- **No transcript over-fetch:** only cited segments are returned to the client, not whole transcripts.
- AI calls are metered (`AIUsageReceipt`), idempotent per question submission.
- `rankBySummary` does **not** expand the candidate set (same eligible candidates, re-weighted) — verify candidate count unchanged.

## 7. Component boundary / design checks
- `feature_ai_qa` imports only contracts + design_system + app_shell.
- Summary-rank coupling flows through **Fan Vault preference**, not a direct feature→feature import — verify with `melos run lint:boundaries`.

## 8. Automated validation checks
README baseline. Unit tests: citation→source-attribution receipt mapping, summary-rank preserves candidate set, transcript minimal-return.

## 9. Integration tests
- `it_p5_archive_qa` — ask a question → cited answer; `AIUsageReceipt` + `SourceAttributionReceipt` emitted.
- `it_p5_summary_rank` — enable BYO-agent preference → discovery feed re-orders; why-shown notes summary used / title deemphasized; candidate set unchanged.
- `it_p5_ai_royalty_receipt` — source-attribution receipts attribute to the correct creator (royalty basis present).

## 10. Definition of done
Fan can query a creator archive with citations; AI usage + source-attribution receipts flow; summary-first ranking re-orders the feed without expanding candidates; all checks green; API Review filed; UX Decisions doc filed. Update the Phase completion tracker in [../Demo App Implementation Plan.md](../Demo%20App%20Implementation%20Plan.md) with Phase 5 status, completion date, API review link/name, and gate evidence before marking this phase complete. Commit all Phase 5 changes to git and record the commit SHA in the tracker before proceeding.

## 11. Next phase
Med UX, no API-shaping beyond validated. After Phase 5 changes are committed and the commit SHA is recorded, **AUTO-PROCEED: immediately begin [Phase 6 — Wallet & Revenue Dashboard](./Phase%206%20-%20Wallet%20and%20Revenue%20Dashboard.md).**
