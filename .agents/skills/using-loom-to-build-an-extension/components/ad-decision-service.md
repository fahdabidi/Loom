# Ad Decision Service

Use `CommunityAdDecisionApi` for top banner and in-stream ad fill/no-fill decisions.

## Extension Use

- Pass `sensitiveContext: true` whenever the current surface contains protected or sensitive data.
- Do not suppress required ad slots; render no-fill states when returned.
- Let wallet ad-off entitlements block fills.

## Validation

- `vt_ad-decision_slot-eligibility` proves eligible fill.
- `vt_ad-decision_sensitive-no-fill` proves sensitive no-fill.
- `ct_protected-vault__ads_no-fill-sensitive` proves protected contexts do not fill ads.
