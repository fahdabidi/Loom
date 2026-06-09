# App Shell Runtime

Use `CommunityAppShellRuntime` to mount extensions inside Loom-owned navigation, ad, payment, and route boundaries.

## Extension Use

- Do not render outside the shell.
- Preserve Messages, Connections, and the required top ad slot.
- Open the latest local or certified extension version through the shell route host.

## Validation

- `vt_app-shell_cards`, `vt_app-shell_required-nav`, `vt_app-shell_route-host`, and `vt_app-shell_ad-slots` prove shell invariants.
