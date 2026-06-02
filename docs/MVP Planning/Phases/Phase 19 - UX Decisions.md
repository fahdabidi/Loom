# Phase 19 - UX Decisions

## Reference Patterns Applied

Phase 19 used creator-console patterns common in YouTube Studio, Twitch creator dashboards, Shopify theme editors, and extension/app marketplaces:

- Left-side configuration with an always-visible preview when width allows; stacked preview-first layout on phone width.
- Explicit save state instead of silently publishing every draft edit.
- Certified extension marketplace cards that surface category, risk tier, approved surfaces, and permissions before install.
- Install approval sheet with reversible scoped grants.
- Module ordering controls that use familiar up/down icon actions instead of drag-only behavior, so the workflow remains usable on emulator and phone.
- Compact creator switcher chips for comparing different channel configurations without leaving the console.

## Key Decisions

- The console keeps a draft `CreatorExperienceConfig` separate from the last saved config. Theme, banner, module order, and visibility update the live preview immediately, but the fan channel changes only after Save.
- Extension install writes immediately through `ExtensionRegistryApi.installExtension`, then saves a matching surface module into `CreatorExperienceConfig`, proving the fan renderer reads creator-authored extension slots.
- Reconfigure uses a deterministic re-install/update path for the same extension install ID. This is enough for the fake backend and keeps the UI honest about the API behavior.
- Suspend removes the extension module from the draft/persisted config and calls `suspendExtension`, so the fan surface stops rendering it.
- The gaming starter-pack assembly lives in the console as a curator/demo utility and writes through `StarterPackApi.putStarterPack`, which the Phase 12 onboarding flow reads.

## Workflow Walkthrough

1. Creator opens `Customize fan experience` from Creator Studio.
2. The console loads creator identity, current experience config, certified extensions, and starter-pack state.
3. Creator switches between Nova, Ember, and Iron to compare different seeded creator worlds.
4. Creator chooses a theme and banner; the preview updates immediately with the selected tone and header.
5. Creator arranges surface modules with up/down controls and toggles visibility.
6. Creator opens the extension browser, reviews risk tier, permissions, and approved surfaces, then approves install from the sheet.
7. The installed extension appears in module order and in the preview, then the fan channel can render it through the Phase 16-18 runtime.
8. Creator can retune or suspend installed extensions.
9. Creator assembles the five-creator gaming starter pack, which feeds the Phase 12 fan onboarding workflow.

## Tradeoffs

- The phone UI uses explicit module buttons instead of drag gestures. It is less flashy, but more reliable for emulator tests and easier to validate manually.
- The live preview is a compact Studio preview, not a nested fan channel. This keeps feature boundaries clean; full fan rendering remains owned by the fan channel feature.
- Extension config forms show applied values rather than free-form text fields in this phase. That keeps the workflow deterministic while still proving config propagation and reconfiguration.
