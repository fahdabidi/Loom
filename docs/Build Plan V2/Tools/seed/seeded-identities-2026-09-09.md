# Seeded test-identity manifest

**Generated 2026-09-09 from the live cluster.** This file exists because the cluster held test
identities that existed nowhere in git: a rebuild would have silently lost every seeded fan, and
nothing recorded which ones were supposed to be there.

**This is a record, not a fixture.** Nothing reads it at runtime. It is the answer to "what should
exist after a rebuild", to be replayed with
`docs/Build Plan V2/Tools/code/seed_role_holder.sh <slug> <groupId> <roleId> <adminUser>`, which
provisions through the real authorization flow — the fan requests membership for themselves, a
community admin approves and grants the role. **Never restore these with a database insert:** the
three identity layers (Keycloak account carrying the `fanId` attribute, `fan_passport` row,
`group_membership_role` grant) must each be created by the mechanism that owns them, and a direct
insert produces rows that look correct and cannot sign in.

**Convention:** Keycloak user `loom-<slug>`, fan id `fan-<slug>`, one shared test password recorded
in the Access Control tracker. So each row below implies its Keycloak account and passport.

**Not covered here, and still hand-made:** the Keycloak realm's `loom-test-client`, and the
`test-fan-alice`/`test-fan-bob` accounts with their `fanId` attributes. Those predate this manifest
and remain unreconstructed — see the Build Tracker row.

**Live counts at generation:** 63 role grants, 68 fan passports. The passport count exceeds the grant
count because some fans hold no role, and because a fan holding two roles in one community appears
twice below.

| Group | Role | Fan |
|---|---|---|
| loom_communities_ad-free-community | ad-free-community-admin | fan-ad-off-admin |
| loom_communities_ad-free-community | ad-off-member | fan-ad-off-member-1 |
| loom_communities_ad-free-community | ad-off-member | fan-ad-off-member-2 |
| loom_communities_ad-free-community | ad-off-owner | fan-ad-off-owner-1 |
| loom_communities_ad-free-community | ad-off-owner | fan-ad-off-owner-2 |
| loom_communities_camera-club | camera-club-admin | fan-camera-club-admin |
| loom_communities_camera-club | camera-club-member | fan-camera-member-1 |
| loom_communities_camera-club | camera-club-member | fan-camera-member-2 |
| loom_communities_camera-club | camera-club-organizer | fan-camera-organizer-1 |
| loom_communities_camera-club | camera-club-organizer | fan-camera-organizer-2 |
| loom_communities_cedar-commons-hoa | cedar-commons-hoa-admin | fan-hoa-admin |
| loom_communities_cedar-commons-hoa | hoa-board | fan-hoa-board-1 |
| loom_communities_cedar-commons-hoa | hoa-board | fan-test-alice |
| loom_communities_cedar-commons-hoa | hoa-member | fan-hoa-member-1 |
| loom_communities_cedar-commons-hoa | hoa-member | fan-hoa-member-2 |
| loom_communities_cedar_commons_hoa | cedar_commons_hoa_admin | fan_alice |
| loom_communities_cedar_commons_hoa | cedar_commons_hoa_member | fan_bob |
| loom_communities_chess-club | chess-club-admin | fan-chess-admin |
| loom_communities_chess-club | chess-member | fan-chess-member-1 |
| loom_communities_chess-club | chess-member | fan-chess-member-2 |
| loom_communities_chess-club | chess-organizer | fan-chess-organizer-1 |
| loom_communities_chess-club | chess-organizer | fan-chess-organizer-2 |
| loom_communities_chess-club | chess-owner | fan-chess-owner-1 |
| loom_communities_chess-club | chess-owner | fan-chess-owner-2 |
| loom_communities_data-portability-community | data-portability-community-admin | fan-portability-admin |
| loom_communities_data-portability-community | portability-member | fan-portability-member-1 |
| loom_communities_data-portability-community | portability-member | fan-portability-member-2 |
| loom_communities_data-portability-community | portability-owner | fan-portability-owner-1 |
| loom_communities_data-portability-community | portability-owner | fan-portability-owner-2 |
| loom_communities_data-portability-community | portability-receiving-provider | fan-portability-provider-1 |
| loom_communities_data-portability-community | portability-receiving-provider | fan-portability-provider-2 |
| loom_communities_garden-club | garden-club-admin | fan-garden-admin |
| loom_communities_garden-club | garden-coordinator | fan-garden-coordinator-1 |
| loom_communities_garden-club | garden-coordinator | fan-garden-coordinator-2 |
| loom_communities_garden-club | garden-member | fan-garden-member-1 |
| loom_communities_garden-club | garden-member | fan-garden-member-2 |
| loom_communities_masjid-nur | community-member | fan-masjid-member-1 |
| loom_communities_masjid-nur | community-member | fan-masjid-member-2 |
| loom_communities_masjid-nur | masjid-nur-admin | fan-masjid-admin |
| loom_communities_masjid-nur | owner | fan-masjid-owner-1 |
| loom_communities_masjid-nur | owner | fan-masjid-owner-2 |
| loom_communities_member-social-space | member | fan-social-member-1 |
| loom_communities_member-social-space | member | fan-social-member-2 |
| loom_communities_member-social-space | member-social-space-admin | fan-social-admin |
| loom_communities_member-social-space | moderator | fan-social-moderator-1 |
| loom_communities_member-social-space | moderator | fan-social-moderator-2 |
| loom_communities_neighborhood-book-club | book-member | fan-book-member-1 |
| loom_communities_neighborhood-book-club | book-member | fan-book-member-2 |
| loom_communities_neighborhood-book-club | book-organizer | fan-book-organizer-1 |
| loom_communities_neighborhood-book-club | book-organizer | fan-book-organizer-2 |
| loom_communities_neighborhood-book-club | neighborhood-book-club-admin | fan-book-admin |
| loom_communities_riverside-youth-soccer | riverside-youth-soccer-admin | fan-soccer-admin |
| loom_communities_riverside-youth-soccer | soccer-coach | fan-soccer-coach-1 |
| loom_communities_riverside-youth-soccer | soccer-coach | fan-soccer-coach-2 |
| loom_communities_riverside-youth-soccer | soccer-guardian | fan-soccer-guardian-1 |
| loom_communities_riverside-youth-soccer | soccer-guardian | fan-soccer-guardian-2 |
| loom_communities_riverside-youth-soccer | soccer-owner | fan-soccer-owner-1 |
| loom_communities_riverside-youth-soccer | soccer-owner | fan-soccer-owner-2 |
| loom_communities_tabletop-club | tabletop-club-admin | fan-tabletop-admin |
| loom_communities_tabletop-club | tabletop-member | fan-tabletop-member-1 |
| loom_communities_tabletop-club | tabletop-member | fan-tabletop-member-2 |
| loom_communities_tabletop-club | tabletop-organizer | fan-tabletop-organizer-1 |
| loom_communities_tabletop-club | tabletop-organizer | fan-tabletop-organizer-2 |
