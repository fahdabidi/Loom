# Utility Funding Service

Use `CommunityUtilityFundingApi` to allocate a share of settlement funds to Loom utility funding.

## Extension Use

- Calculate allocation from a settlement output.
- Keep basis points explicit in workflow configuration.
- Display owner and utility amounts separately in admin surfaces.

## Validation

- `vt_utility-funding_calculate` proves basis-point allocation.
- `ct_settlement__utility-funding_allocation` proves settlement output is accepted.
