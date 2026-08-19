---
spec: 4
doc_version: 1.0.0
status: current
last_verified: 2026-08-19
audience: llm-agent
---

# Porting the Codex authoring channel to the ChatGPT GPT

The **ChatGPT GPT is the production target.** The Codex channel exists to strengthen it: it is faster
to iterate, it can be dispatched unattended, and every rule proven there is meant to end up here.

This document is the conversion path. It exists because the two channels drifted badly once — the
production channel was carrying 11 of 18 hard rules, had never seen `identity-types.md`, and its
deliverables section instructed emitting a field its own hard rules forbade. Nothing detected that,
because nothing described how the two relate.

## The design rule that makes porting cheap

**Everything that is a *rule* lives in `docs/references/**`. Only *mechanism* lives in a channel's own
instruction file.**

Both channels have identical access rights — the public `fahdabidi/Loom` repo — so anything fetched is
automatically shared. A rule written into a channel file is a rule the other channel cannot see.

| Belongs in `docs/references/**` (shared) | Belongs in a channel file (not shared) |
|---|---|
| Grammar, archetype contracts, worked examples | How to reach the validator |
| Identity types, permissions, visibility rules | What a "deliverable" looks like |
| Antipatterns, validation diagnostics, solved patterns | Whether output is text, a file, or a download link |
| Anything an author must know to write correct JSON | Anything about the runtime the author happens to be in |

**Test before writing a rule into a channel file:** *would the other channel's author need to know
this?* If yes, it belongs in `docs/references/**`, and the channel file should only point at it.

## What the two channels actually share today

Identical, and must stay so:

- The **fetch order** — same files, same paths, same "read it in full before treating it as known".
- The **hard rules**, 1 through 13 including 2a and 12a–12d.
- The **"updating an existing community"** section: match-or-beat, the boundary-identifier table, the
  functional-correctness checklist, the persona→role case distinction.
- The **two RSVP shapes**.

Legitimately different:

| | Codex | ChatGPT GPT |
|---|---|---|
| Validator | `curl` to a local server on `127.0.0.1:8787`, enabled by `sandbox_workspace_write.network_access=true` | the `validateCommunityPackage` Action over a Cloudflare tunnel |
| Round attribution | `X-Loom-Dispatch` / `X-Loom-Round` headers, logged server-side | not wired up yet — see below |
| Packaging | none; returns the JSON as text | `buildExtensionPackage` returns a `downloadUrl` |
| Delivery | a file in a scratch dir, read by the dispatching session | a chat message with the JSON, the link, and inline fallbacks |
| Failure mode to guard | a dispatch that dies silently | a malformed Action call reported as a validation failure |

## The GPT surface has constraints the Codex channel does not

These are the real porting obstacles, and they are structural rather than editorial:

1. **The Instructions field is character-limited** (~8k). `codex-dispatch/INSTRUCTIONS.md` is ~550
   lines and cannot go there. It has to be uploaded as knowledge, with the Instructions field acting
   as a **bootstrap**: where to fetch from, the fetch order, and the few rules that must survive even
   if fetching fails.
2. **Knowledge is capped at 20 files.** The offline bundle currently carries 38. This is the strongest
   argument for the fetch model: with it, knowledge only needs a bootstrap set and the cap stops
   binding.
3. **Conversation starters** are part of the surface and shape what users actually ask for. They
   should reflect the archetypes the Skill is strongest at, and be revisited when that changes.
4. **The Instructions field outranks knowledge.** A stale instruction there overrides a correct rule
   in an uploaded file. It is the highest-risk place for drift, and the first thing to check when the
   GPT behaves unlike the Codex channel on the same input.

## Porting procedure

When a rule is proven in the Codex channel:

1. **Decide where it belongs** using the table above. Most rules belong in `docs/references/**`; put
   them there first, and have the channel file point at them.
2. If it genuinely is channel-specific, add it to **both** channel files, adapted to each mechanism.
3. Refresh the offline bundle from source — `SKILL.md` carries the copy recipe, and it must list
   **every** file the bundle mirrors. The recipe once covered 16 of 19 mirrored files, and the three
   it omitted rotted silently.
4. Regenerate `chatgpt-upload.zip`, and **verify by reading it back** rather than trusting the zip
   step.
5. Re-upload to the GPT, or let the deployment automation do it once that exists.

## Parity check — run this when either channel changes

Cheap, and it catches the drift class that actually happened:

```bash
A=.agents/skills/loom-calendar-experience-authoring/chatgpt-upload/00-INSTRUCTIONS.md
B=.agents/skills/loom-calendar-experience-authoring/codex-dispatch/INSTRUCTIONS.md

# Same hard rules on both sides?
for f in "$A" "$B"; do grep -oE '^[0-9]+[a-z]?\.' "$f" | tr '\n' ' '; echo "  <- $f"; done

# Concepts that must appear in both
for t in specVersion roleId fanId createdByFanId visibility.fields 'Existing identifiers'; do
  printf '%-24s chatgpt=%-4s codex=%s\n' "$t" "$(grep -c "$t" "$A")" "$(grep -c "$t" "$B")"
done

# Neither file may instruct emitting the legacy version field
grep -n 'schemaVersion' "$A" "$B" | grep -vi 'never\|not\|forbid\|legacy\|previously'
```

A zero on either side of the second block is the failure that happened before: the production channel
had `roleId`, `fanId`, `createdByFanId` and `visibility.fields` at zero while the Codex channel had
them throughout.

## Known gaps, as of 2026-08-19

- **Round diagnostics are Codex-only.** The GPT's Action does not send `X-Loom-Dispatch` /
  `X-Loom-Round`, so its validate rounds are not attributable and its round-one finding profile —
  the measure of whether the docs prevent errors rather than the loop catching them — is invisible.
  Porting this needs the Action's OpenAPI to declare the headers.
- **`17-worked-example-calendar.jsonc` should be checked against `specVersion: 4`.** The Instructions
  field tells authors to shape the envelope like it, so if it still carries the legacy triple, every
  run starts from a stale template.
- **The offline bundle exceeds the knowledge cap** (38 files against 20), unresolved until the fetch
  model is adopted on the GPT surface.
