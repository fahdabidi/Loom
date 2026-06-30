# Plant or Item Exchange Surface

## Supported Interactions

- Create offer/request, edit offer, claim, cancel claim, mark unavailable, schedule pickup, complete
  handoff, display claimant/owner state, and protect contact details until appropriate.

## Personas and Permissions

| Persona | Permissions | Can do |
| --- | --- | --- |
| Member | `community.surface.exchange.write` | Offer, request, claim, cancel, mark complete. |
| Coordinator | `community.surface.exchange.review` | Review listings and moderate handoff issues. |
| Viewer | `community.surface.exchange.read` | Browse available public listings. |

## Custom Experience Guidance

Customize item fields, availability labels, pickup constraints, privacy fields, review workflow, and
handoff copy. Use for plants, books, tools, sports gear, meal swaps, or lost-and-found.

## API Support

Requires `CommunityExchangeApi`: `createOffer`, `updateOffer`, `cancelOffer`, `claimOffer`,
`cancelClaim`, `markUnavailable`, `schedulePickup`, `handoffComplete`, `listClaims`,
`privacyScopedContact`.
