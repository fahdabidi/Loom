# Phase 9 - UX Decisions

## Reference Patterns Applied

- Google Takeout-style exports: explicit job start, processing state, and completed bundle summary.
- Meta/Instagram/TikTok account-data surfaces: contents checklist before the user opens the artifact.
- WhatsApp export flows: portable local bundle framing rather than a cloud-sync framing.
- YouTube Studio dashboards: Creator Studio export belongs with revenue, audience, campaigns, and recommendations.
- Subscription and receipt products: fan transparency should reconcile money and receipts in Wallet.

## Decisions

- Export is a Creator Studio utility named "Export and transparency" so it reads as an operational creator task, not a fan-facing social feature.
- The export screen uses a job/status card with sections for channel, content, manifests, receipts, settlement, and policies.
- The raw JSON bundle is available from a bottom sheet so reviewers can inspect portability without leaving the app.
- Fan transparency is folded into Wallet as "Supported creators" because Wallet already owns allocations, purchases, and receipt context.
- Reset lives in a demo menu in the shell, not in the primary Fan App or Creator Studio navigation.

## Workflow Walkthrough

1. Creator opens Studio and selects Export and transparency.
2. Creator starts the export job and sees queued/processing/complete progress.
3. Completed export shows a portable contents checklist and bundle summary.
4. Fan opens Wallet and sees how support reconciles to creators through allocation rows.
5. Reviewer opens the demo menu and resets to seed v1.
6. Full demo can restart from Fan App with a clean seed world.

## Implementation Notes

- `StudioExportPanel` follows the existing Studio card pattern with compact status, section rows, and icon actions.
- `SupportedCreatorsView` mirrors receipt-statement density but names the fan outcome directly.
- The reset action increments the shell key so active surfaces rebuild after seed restoration.
- Phase 9 screenshots should include export complete, supported creators, and the reset confirmation.
