# Phase 5 - API Review

Date: 2026-06-01

## Reviewed surfaces

- `AiGatewayApi`: archive Q&A, cited answer payloads, and summary-first re-ranking.
- `FanVaultApi`: persisted BYO-agent summary-first ranking preference.
- `CreatorMetadataApi`: channel home and AI content policy reads for archive Q&A entry.
- `ReceiptLedgerApi`: AI usage and source-attribution receipt types.
- `DemoLocalStore`: Drift schema version 6 with transcripts, AI sessions, and ranking preferences.

## Contract decisions

- `askArchive` is one call with passport id, creator scope, question, policy ref, and idempotency key.
- `ArchiveAnswer` returns only the answer, confidence label, cited segments, and emitted receipts. Whole transcripts are not returned.
- Citations include content id, title, segment, start label, creator attribution, and royalty basis so the UI can explain source use without extra calls.
- AI receipts extend the shared receipt enum with `aiUsage` and `sourceAttribution`, allowing later revenue phases to consume the same ledger.
- Summary-first ranking is explicit: discovery reads `RankPreference` from Fan Vault and calls `rankBySummary` with the already eligible candidates. The candidate set is not expanded.

## Store and fake backend review

- `transcripts` stores seeded cited segments per content item.
- `ai_sessions` records the question, answer, cited content ids, and memory policy.
- `fan_ranking_preferences` persists the summary-first BYO-agent toggle.
- `AiGatewayFake` scores transcript segments deterministically, returns at most two citations, creates an AI session, and emits one usage receipt plus source-attribution receipts.
- `AiGatewayFake.rankBySummary` reorders only the passed candidates and annotates why summaries were used and title signals were deemphasized.

## Gate evidence

- `melos bootstrap`: passed.
- Drift generation: `dart run build_runner build --delete-conflicting-outputs` regenerated schema version 6 outputs.
- `melos run analyze`: passed across 26 packages.
- `melos run lint:boundaries`: passed.
- `melos run test`: passed, 15 tests.
- Focused Phase 5 integration tests: passed 3/3 on `emulator-5554`.
- `melos run test:integration`: passed, 23 tests on `emulator-5554` after a clean rerun. An earlier run hit a Gradle asset cleanup lock at `it_p4_multiformat_render`; `./gradlew --stop` plus `flutter clean` cleared it.
- `flutter build apk --debug`: passed.
- `adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk`: passed.
- `adb -s emulator-5554 shell am start -n com.example.loom_demo/.MainActivity`: passed.
- Launch screenshot captured at `data/validation/phase5-manual-checkpoint.png`.

## Residual notes

- Physical-device validation remains deferred to Phase 9.
- The Q&A fake is deterministic and transcript-backed for validation; real model/provider orchestration remains out of scope for the demo backend.
- Revenue allocation for source royalties is represented by receipts now and will be surfaced in later revenue phases.
