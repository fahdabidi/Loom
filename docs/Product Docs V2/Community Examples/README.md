# Community Example Product Experience Docs

**The seven legacy-community product-experience docs (Garden Club, Camera Club, Chess Club, Book Club,
Youth Soccer, Mosque, HOA) have moved to
[`docs/references/communities/`](../../references/communities/README.md)** (2026-07-15), so every
community's product doc lives in one place alongside the new engine-native Tabletop Club reference.
**`ad-off-product-experience.md`, `export-and-migration-product-experience.md`, and
`platform-social-product-experience.md` likewise moved there (2026-08-10)** — despite their generic-sounding
filenames, these are the product docs for the 3 remaining pure-legacy communities (Ad-Free Community, Data
Portability Community, Member Social Space respectively; see each doc's own "Evidence community name" row),
renamed to `ad-free-community-product-experience.md`, `data-portability-community-product-experience.md`,
and `member-social-space-product-experience.md` at their new location. This folder still holds the
non-community product docs (the shell itself, the persona/role inventory) and remains the home for any *new*
community example doc until it is likewise relocated.

This folder holds native Loom repo product experience specs for example communities reviewed by B25.

Each community doc should use the Skill template at
`docs/Build Plan V2/Skill/references/community-product-experience-template.md` and define the rich
product experience before the UI is judged:

- community identity and product promise
- personas, roles, and jobs-to-be-done
- home information architecture
- domain-native product surfaces
- workflow-to-surface mapping
- persona and state matrix
- required visible content and seed data
- API, rules, events, and validation mapping
- visual and interaction standard
- review/remediation log

Native Loom repo B25 runs create or update docs here. Standalone Skill runs must not mutate this
folder in a fetched Loom checkout; they write the equivalent product doc in the extension workspace at
`docs/product/community-product-experience.md`.
