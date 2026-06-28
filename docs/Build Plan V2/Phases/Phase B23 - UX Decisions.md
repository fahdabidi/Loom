# Phase B23 - UX Decisions

## Decisions

- Actor personas see production action labels and production review dialogs.
- Receiver personas see production receiver surfaces, not generic result receipt copy.
- Read-only personas see `View only` and review-oriented copy.
- Disabled personas see concise role-based unavailability copy.
- Waiting states say `Waiting for the required prior action`, avoiding test-harness language.

## Evidence

- `wf_persona-production-ux-cross-persona-state` validates the Masjid Nur admin publish/member receive
  flow on production surfaces.
- Existing B20 multi-persona sweep still passes across all example/test communities.
