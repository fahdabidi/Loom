# Debugging validator errors — read this whenever `validateCommunityPackage` doesn't come back clean

This file is specific to authoring inside a chat session that calls the `validateCommunityPackage`
action, as opposed to a local CLI run. Read it any time the validator reports a problem, before you
decide how to respond.

## Step 0 — Is the response you're about to report even real?

**Do this check before anything else, every single time.** This step exists because of an observed,
repeated failure mode: a coding agent testing this exact bundle reported the identical error text —
`UnrecognizedKwargsError: ('schemaVersion', 'packageId', ...)` — across two completely different request
schemas (one that declared those field names as top-level properties, and a later one that didn't declare
them at all, only a single `packageJson` string field). The same error text surviving a change to the
thing it was supposedly erroring about is strong evidence the text was never a real response at all — it
was invented, because either the tool was never actually called, or a plausible-sounding failure was
produced instead of the literal returned content.

**The validator has exactly two possible response shapes. Memorize both:**

**Shape A — a validation report** (the call succeeded, whether or not the package passed):
```json
{"status": "pass", "errorCount": 0, "warningCount": 0, "findings": []}
```
or, with findings:
```json
{"status": "fail", "errorCount": 1, "warningCount": 0, "findings": [
  {"type": "missing_schema_version", "message": "schemaVersion must be present and an int.",
   "location": "schemaVersion", "isWarning": false}
]}
```

**Shape B — a malformed-request error** (HTTP 400, your own request body was bad):
```json
{"error": "invalid_json", "message": "Request body is not valid JSON/JSONC: ..."}
```

**That is the complete list.** The validator is written in Dart. It never returns, and there is no code
path in it that could ever produce:
- A Python (or any other language's) exception name, e.g. anything shaped like `SomeError: (...)` or
  `SomeError('field1', 'field2')`
- A stack trace
- Prose describing an internal "tool-binding layer," "kwargs," or similar implementation vocabulary —
  the validator has no concept of any of that; it is an HTTP server with two routes
- Any response that doesn't parse as one of the two JSON shapes above

**If what you are about to write doesn't match Shape A or Shape B exactly, you do not have a real
response.** One of these happened, and you must say so explicitly rather than presenting invented text as
if it were real:

1. You never actually invoked the `validateCommunityPackage` tool this turn.
2. You invoked it, but you're now describing what you assume went wrong rather than the literal content
   that came back.
3. You don't have a real result and are filling the gap with a plausible-sounding technical detail.

All three look identical to the person reading your answer: a fabricated result. **This is a hard rule,
not a style preference: never invent error text, an exception class name, a "rejected at the X layer"
explanation, or any other detail you cannot show as the literal returned JSON.** The honest response —
"I was not able to obtain a real validator response this turn" — is always correct to give when true. A
specific, technical-sounding, wrong answer is never better than an honest, vague, true one.

## Step 1 — Confirm the call itself was shaped correctly

Before reading findings, check the request you sent:

- Request body is exactly `{"packageJson": "<the full package, JSON-encoded as a string>"}` — see
  `18-validator-action-openapi.yaml`. Not the package's fields directly at the top level. Not an empty
  object. Not a truncated string.
- If you genuinely cannot tell whether the argument you constructed was complete (this can happen when a
  package is large), do not guess — say so and ask the user to request validation again in a follow-up
  message, per `00-INSTRUCTIONS.md`'s validation loop.

## Step 2 — Once you have a REAL Shape A response, work the findings systematically

1. Split `findings` into errors (`isWarning: false`) and warnings (`isWarning: true`).
2. **Errors first, always.** For each error, look up its `type` in `04-validation.md`'s error → fix
   table. That table is organized by category (version/envelope, states, transitions, fields/formulas,
   instances, bindings, expected-affordances) — find the matching row, apply the listed fix, and move on.
   If a `type` isn't in that table, read its `message` and `location` literally — they name the exact
   JSON path and problem; do not guess at a fix that isn't grounded in what the message says.
3. Re-call the validator after fixing errors. Repeat until `errorCount` is 0. Do not skip this — a second
   fix can introduce a new error the first pass didn't have.
4. Once errors are clear, work warnings the same way. Every warning code in `04-validation.md`'s table
   has a concrete fix; apply what's reasonable, and only leave a warning unfixed with an explicit,
   specific reason in your "Gaps / assumptions" section (not a generic "warnings are optional" dismissal).
5. Cross-check against `03-antipatterns.md` even after the validator is clean — several antipatterns
   (state-vs-data modeling, AP-13's "seeded blank draft" variant) can pass structural validation while
   still being wrong.

## Step 3 — Before your final answer, re-verify shape one more time

Re-read Step 0's two shapes against what you're about to paste into your answer. If it still doesn't
match either shape exactly, go back to Step 0 — do not proceed to present it as a finished result.
