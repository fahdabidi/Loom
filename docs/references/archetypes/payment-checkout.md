---
spec: 4
doc_version: 1.0.0
status: current
last_verified: 2026-08-05
audience: llm-agent
derived_from:
  - app/packages/core/loom_communities_app_shell/lib/src/part26_generic_instance_card.dart
  - app/packages/core/loom_communities_app_shell/lib/src/part27_engine_native_binding_dispatcher.dart
---

# `paymentCheckout` — dues/donations + receipt

**Read [archetypes/README.md](./README.md) first — this family is 🟡 GENERIC,
not a bespoke widget.** Declaring `cardSurfaceFamily: "paymentCheckout"`
reaches `GenericWorkflowInstanceCard` — no per-community wiring required, and
every transition/guard/formula genuinely works — but the card is the shared
icon+pills+buttons template, not a payment-shaped UI.

## JSON shape

```jsonc
{
  "states": ["unpaid", "paid"], "role": "actor", "tabId": "giving",
  "cardSurfaceFamily": "paymentCheckout", "bindingKind": "primary"
}
```

`role: "actor"` scopes the binding to the member who owes the payment — the
generic card resolves `instanceDataSchema` fields (amount, purpose, due date)
into fact pills and `availableTransitionsAsync` into real buttons (`pay`,
etc.) exactly as it does for any other workflow type.

## The platform-services boundary

A real "pay" action needs a receipt ID from a real payment/ID-generation
service — there is no such platform service in this codebase. Tabletop
Club's frozen JSON and the engine do not fake one: rather than hardcode a
fake receipt ID to make the UI look complete, this is recorded as an honest,
named gap (see `spec-version.json`'s `knownGaps`). **Do not invent a receipt-
ID scheme in JSON to paper over this** — declare the transition and let it
produce whatever the engine's real effect model supports today; a real
payment-service integration is future platform work, not something to fake
in a community's JSON.

## Why no bespoke widget

Tracker 3 Phase D built the generic transition/query/theme-cascade
infrastructure this family needs (live payment history, correct tab-theme
resolution) rather than a one-off "amount + pay button" widget, because that
infrastructure is what every other generic-card archetype also needs and
what Phase 3's Skill actually depends on. If a future community's design
needs a genuinely distinct payment UI (e.g. a stepped checkout), that is new
bespoke-widget scope, not something this family already provides.
