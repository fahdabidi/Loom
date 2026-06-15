# Stream Renderer

Use stream item props for posts, messages, and in-stream ads.

## Extension Use

- Render `kind: ad` with a visible sponsored disclosure.
- Keep ad decisions separate from stream rendering.
- Do not hide required in-stream ad items unless the ad decision returns no-fill.

## Validation

- `vt_stream-renderer_ad-item-disclosure` proves ad disclosure.
- `ct_stream-renderer__workflow_in-stream-ad` proves workflow reuse.
