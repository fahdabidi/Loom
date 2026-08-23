# Archived — pre-specVersion-4 — NOT USED

These 12 files are **V2-era design records**. They are not shipped community packages.

- Not installed, loaded, validated, or referenced by any code.
- Do not conform to specVersion 4. They predate the v4 identity split
  (`roles` / `roleId` / `allowedRoleIds`) and declare no `specVersion` at all.
- Six share a filename with a live community (BookClub, CameraClub, ChessClub,
  GardenClub, Mosque, YouthSoccer). **They are not those communities.** They carry no
  `extensionId` and cannot be installed.
- Six were never communities at all — `Calendar_RSVP`, `Giving_Dues`, `Marketplace`
  and three HOA examples are feature-design fragments.

## The only authoritative community packages

`docs/references/communities/*.jsonc` — eleven packages, one per product doc, all
specVersion 4, all validating with zero errors.

Community JSON is written **only** by the authoring Skill. Never hand-authored, never
copied from here.

## Why these were archived

A sweep on 2026-08-22 found 12 pre-v4 community-shaped files that no validator had ever
checked — the validator only ever ran against `docs/references/communities/`. Separately,
the six community packages bundled into the APK had drifted 1,300–4,100 lines from what
ships and were themselves pre-v4, which is how this came to light.

Each file here was verified unreferenced by any `.dart`, `.sh`, `.yaml` or reference doc
before being moved.

**Do not migrate these to v4.** Migrating a V2 design record destroys the history it
exists to preserve. If you need a v4 example, read a live package or the authoring
Skill's examples.
