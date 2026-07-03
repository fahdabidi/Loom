# AI Gateway

Use `CommunityAiGatewayApi` for permission-aware answers over community records.

## Extension Use

- Route source lookup through search.
- Preserve citations so members can inspect source records.
- Do not answer from protected data unless the source policy allows it.

## Validation

- `vt_ai-gateway_answer` proves cited answers.
- `vt_ai-gateway_source-policy` proves source policy metadata.
- `ct_ai-gateway__digest_citations` proves digest preserves citations.
