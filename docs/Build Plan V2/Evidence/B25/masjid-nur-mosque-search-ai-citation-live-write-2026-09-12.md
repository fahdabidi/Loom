**Workflow:** `mosque-search-ai-citation` in Masjid Nur
**Outcome:** Both halves of the proof standard were met — signed in as `loom-masjid-owner-1`, asked a question from the Resources tab FAB, then drove `provide-curated-answer` (`asked → answered`), `hide-search-source` (a `to: null` transition proven by an `instance_data` mutation) and `report-stale-citation` (`answered → reported`), with the row confirmed in Postgres.

**No terminal state is claimed.** This workflow declares none — `asked`, `answered` and `reported`
all have `isTerminal` unset, and `reopen-reported-question` cycles `reported → asked` by design. The
proof standard met here is a **clearly advanced** state: `reported`, two state changes downstream of
creation.

**Package identity:** `app/packages/core/loom_communities_app_shell/assets/Loom_Communities_Workflow_Engine_Mosque_Example.jsonc`
- `"skillVersion": "3.6.0"`
- `sha256 7a7b48223d14f7ae50237af3a7c290f646eb84ca2c1efa4c0f54ec9d6b6fe1ff`

## Identity

- Keycloak account: `loom-masjid-owner-1`
- Fan id: `fan-masjid-owner-1`
- Role: `owner`
- No sign-in was performed this session; the app already held an authenticated
  `fan-masjid-owner-1` session, so neither Chrome nor the app was cleared. See the companion
  `mosque-volunteer-signup` manifest for how the identity was confirmed. It is confirmed again here
  by `created_by_fan_id`, and independently by `askedByFanId` inside `instance_data`.

## Baseline, measured in this session

- `workflow_instances` held **50** rows before the run.
- `select ... where workflow_type='mosque-search-ai-citation'` returned **0 rows** — a real negative
  result; this row had never been driven.

After both rows in this session the total is **52**. This row is distinguished by its instance id
and `created_at`, not by the count.

## Path driven

Every transition in this workflow is available to `owner`; this is the one Masjid row with no
member-only steps, so no identity switch was needed at any point.

1. **Create** — `Resources` tab → FAB → **"Ask Masjid Nur"**
   (`byRoleIds: ["community-member", "owner"]`). Single required field `query=JumuahTime`.
   Landed in `asked`.
2. **`provide-curated-answer`** — owner-guarded, `asked → answered`. Inputs
   `answerBody=Jumuah1pm`, `citationLabel=MasjidSite`, `citationUrl=masjid.example/jumuah`.
3. **`hide-search-source`** — owner-guarded, `to: null`. Input
   `citationUrl=masjid.example/jumuah`.
4. **`report-stale-citation`** — member-or-owner, `answered → reported`. Input
   `reportReason=LinkOutdated`.

## Final UI state

The card sits in `reported` and offers exactly two actions — **"Refine query"**
(`refine-search-query`, any state → `asked`) and **"Reopen for new answer"**
(`reopen-reported-question`, owner, `reported → asked`). Both are correct for `reported`; the four
`answered`-only actions are correctly gone.

## Database row (independent confirmation, same session)

    instance_id       community_mosque_mosque-search-ai-citation_tywwugk8wksw
    community_id      community_mosque
    workflow_type     mosque-search-ai-citation
    created_by_fan_id fan-masjid-owner-1
    current_state     reported
    created_at        1789242164103  (2026-09-12T19:42:44.103Z)

Final `instance_data`:

    { "query": "JumuahTime",
      "citations": [ { "label": "MasjidSite", "source": "masjid.example/jumuah" } ],
      "answeredAt": "2026-09-12T19:44:13.394346Z",
      "answerSource": "Masjid admin curated",
      "askedByFanId": "fan-masjid-owner-1",
      "reportReason": "LinkOutdated",
      "citationStatus": "reported-stale",
      "curatedAnswerBody": "Jumuah1pm",
      "saveAnswerHistory": [],
      "hiddenCitationUrls": [ "masjid.example/jumuah" ] }

**Do the two halves agree? Yes.** `created_by_fan_id` and `askedByFanId` are both
`fan-masjid-owner-1`, the identity driven. `current_state` is `reported`, matching the card, whose
only remaining actions are the two the package declares out of `reported`.

**`hide-search-source` is proven by the data, not the state.** It declares `to: null`, so the row
stayed `answered` when it fired — confirmed in Postgres at that moment — and its evidence is that
`hiddenCitationUrls` went from `[]` to `["masjid.example/jumuah"]` and `citationStatus` went from
`current` to `source-hidden-pending-renderer-redaction`. The later `report-stale-citation` then
advanced the state and overwrote `citationStatus` to `reported-stale`.

## The missing AI service — expected, and it behaved as declared

This is one of the four missing-platform-service areas (external search / AI). The ticket's
expectation held exactly:

- **`aiAnswerBody` is absent from `instance_data`** at every point in the run. It is
  `writableBy: platform` and no platform writer exists, so the field is honestly unwritten rather
  than stubbed. This is the declared state, not a defect.
- In `asked` the card read **"Waiting for an answer"** with no AI content.
- `citations` was populated only by the human `provide-curated-answer` effect, and `answerSource`
  reads `"Masjid admin curated"` — the package is explicit that the answer came from a person.

Nothing was surprisingly populated; there is no finding to report here.

## Defect observed — citation list renders its object KEYS, not its values

On the `answered` and `reported` cards the **Sources** section renders the literal strings
**`label`** and **`source`** instead of the stored values `MasjidSite` and
`masjid.example/jumuah`.

- Stored correctly: `"citations": [{"label": "MasjidSite", "source": "masjid.example/jumuah"}]`.
- Rendered: a bold `label` next to a chip reading `source`.

So the data is right and the renderer is wrong. `citations` is declared
`"type": "list"` with `writableBy: platform`; the surface appears to iterate the map's keys rather
than resolving each entry's values, which makes the citation unreadable to a member — the whole
point of a citation. This is user-visible and reproduced on both screens. **Reported, not worked
around.**

A second, milder item worth recording rather than filing: after `hide-search-source` the source chip
is still displayed. The package itself names this — `citationStatus` is set to the literal
`source-hidden-pending-renderer-redaction` — so the renderer-side redaction is a declared,
acknowledged gap rather than an unexpected failure.

## Truncation check

All stored values were settled against the database, not the screen. **Nothing was truncated**,
including the 21-character `masjid.example/jumuah`, which was typed twice (once into
`provide-curated-answer`, once into `hide-search-source`) and matched byte-for-byte — the
`hiddenCitationUrls` entry equals the `citations[0].source` value, which is also what made the hide
meaningful rather than a no-op against a mistyped URL.

## Environment

- Emulator `emulator-5554` on the Windows host, via `ADB_SERVER_SOCKET=tcp:192.168.56.1:5037`.
- All six `loom` pods `1/1 Running`.
- No ANR and no `FATAL EXCEPTION` in logcat during the run.
- No `403` or `unknown_permission_id` was encountered at any point.
- No application code, community JSON, or tracker was modified. No credential was created or reset.
