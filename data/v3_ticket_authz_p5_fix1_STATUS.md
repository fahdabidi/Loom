# Ticket status: AuthZ.P5 fix1

## Root cause found

The failure was a third case: the visible auth screen contains one newly issued
invite code, but the broad `find.textContaining('LOOM-')` finder also matches the
static `LOOM-ABC234` hint in the invite-redemption `EditableText`. The admin
button has one `onPressed: _issueInvite` callback; `_issueInvite` makes one
`authApi.issueInvite` call and sets `_issuing` before awaiting it, which disables
the button. The fresh `_api()` fixture seeds accounts but no invites, so there
is no second persisted invite. The separate code is the redemption-field hint,
not a second API result.

## Change applied

Status: done

The fix is in the test only. The first `issued-invite-code` assertion is
unchanged. The second assertion now scopes `find.textContaining('LOOM-')` to the
`issued-invite-code` widget, so it verifies the newly issued code without
matching the unrelated redemption hint. No production code, AuthZ.P1-P4b code,
or JSON grammar was changed.

## Verification

flutter analyze: not run to completion; the sandbox Flutter tool exits before
startup with `WSL (...) ERROR: UtilBindVsockAnyPort:309: socket failed 1`.

Test suite: not run to completion for the same sandbox limitation. The focused
test and the full `melos test` command both fail before Flutter starts, so no
local pass count is available. Independent verification must confirm all 7
AuthZ.P5 tests and the full-suite baseline of 198/199 passing (only the known
a11 flake failing).

## Commit

staged, not committed
