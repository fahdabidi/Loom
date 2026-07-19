# Ticket status: CALR.2g live package regeneration

## Generation script

Status: done
Path: `app/packages/core/loom_communities_app_shell/tool/generate_tabletop_club_package.dart`

## Regenerated package files

Status: done
Confirm: does the init file now contain `event-rsvp-response`? yes

## Regression test

Status: done

## Verification

dart analyze: not clean (blocked before analysis: the sandbox's Flutter SDK is read-only and cannot create `/home/fahd_/flutter/bin/cache/lockfile`).
Test suite: pass count (0/1; not run because the same read-only Flutter SDK cache lockfile blocks `flutter test`).

## Findings on tabletop-club-fresh / tabletop-club-v3

did not investigate, out of scope per ticket

## Commit

456ac56cf381ae4aa777af98017a3d8c4b4fe468
