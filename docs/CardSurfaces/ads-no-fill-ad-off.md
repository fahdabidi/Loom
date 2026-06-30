# Ads, No-Fill, and Ad-Off Surface

## Supported Interactions

- Request ad decision, show sponsored disclosure, record impression/click, record no-fill and reason,
  inspect ad-off entitlement, suppress/restore ads, and show receipt evidence.

## Personas and Permissions

| Persona | Permissions | Can do |
| --- | --- | --- |
| Member | `community.surface.ads.read`, `community.surface.ads.ad_off.pay` | See ads/no-fill, buy member ad-off, view receipt. |
| Owner | `community.surface.ads.community_ad_off.pay` | Buy community ad-off and inspect suppression. |
| Governance | `community.surface.ads.audit` | Inspect policy, no-fill reason, disclosure evidence. |

## Custom Experience Guidance

Customize sponsor category labels and no-fill messaging only within policy. Extensions cannot hide
required shell ad surfaces; sensitive contexts must show no-fill or suppressed state.

## API Support

Requires `CommunityAdSurfaceApi`: `requestAdDecision`, `recordImpression`, `recordClick`,
`recordNoFill`, `getNoFillReason`, `getDisclosure`, `getAdOffEntitlement`, `suppressAds`,
`restoreAds`, `receiptEvidence`.
