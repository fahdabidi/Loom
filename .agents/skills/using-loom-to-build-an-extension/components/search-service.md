# Search Service

Use `CommunitySearchApi` for permission-aware community search.

## Extension Use

- Avoid paid ranking fields; search results explain source matches only.
- Request restricted search results only when the actor has the matching policy grant.
- Feed AI with search hits rather than direct component storage reads.

## Validation

- `vt_search_permission-aware` proves restricted results require policy.
- `ct_search__ai-gateway_retrieval` proves AI uses search retrieval.
