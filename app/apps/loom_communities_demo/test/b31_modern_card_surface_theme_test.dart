import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show currentCommunitySpecVersion;

import 'workflow_ui_test_harness.dart';

const _extensionId = 'ext_verify_tabletop_club';

/// Mirrors `LoomCardTheme.deriveFromAccent(accent, lightSurface: true)`'s
/// fill formula — the light, subtle card fill every card surface in a
/// community that declares an `experience.theme` block resolves to.
Color _lightFillFor(Color accent) {
  return Color.alphaBlend(accent.withValues(alpha: 0.07), Colors.white);
}

void main() {
  group('B31 modern card surface theme applies everywhere, gated correctly', () {
    testWidgets(
      'wf_package-driven-community-gets-the-light-modern-treatment',
      (tester) async {
        final fixture = _writeTabletopClubPackagePair();
        await tester.pumpWidget(const LoomCommunitiesDemoApp());
        await _installAndOpen(tester, fixture);

        const accent = Color(0xffC4703F);

        // Hero card identity avatar: accent-tinted (from the resolved
        // border color), not the legacy plain-white-tint every unthemed
        // community uses.
        final avatar = tester.widget<CircleAvatar>(
          find.byKey(
            const ValueKey(
              'opened-community-identity-community_verify_tabletop_club',
            ),
          ),
        );
        expect(avatar.backgroundColor, accent.withValues(alpha: 0.18));

        // The "Home" tab-label header renders with the light fill too.
        final header = tester.widget<DecoratedBox>(
          find.byKey(const ValueKey('selected-tab-home')),
        );
        expect(
          (header.decoration as BoxDecoration).color,
          _lightFillFor(accent),
        );

        // The workflow tile itself (not just its chrome frame) is light too.
        const workflow = LoomWorkflowDefinition(
          workflowId: 'tabletop-game-night-rsvp',
          title: '',
          entryText: '',
          actionText: '',
          resultText: '',
        );
        await scrollToWorkflowCard(tester, workflow);
        final tile = tester.widget<DecoratedBox>(
          find.byKey(const ValueKey('workflow-tabletop-game-night-rsvp')),
        );
        expect(
          (tile.decoration as BoxDecoration).color,
          _lightFillFor(accent),
        );

        // The pushed action surface (opened from the tile's actor button)
        // also renders its hero panel with the light fill, not the dark
        // neutral fill `_resolvedCardThemeFor` used to fall back to when it
        // independently re-derived the community card theme outside of
        // `build()` without the `lightSurface` flag.
        await selectPersona(tester, 'tabletop-member');
        await scrollToWorkflowCard(tester, workflow);
        await tester.tap(
          find.byKey(const ValueKey('workflow-button-tabletop-game-night-rsvp')),
        );
        await tester.pumpAndSettle();
        final hero = tester.widget<DecoratedBox>(
          find.descendant(
            of: find.byKey(
              const ValueKey('action-surface-hero-tabletop-game-night-rsvp'),
            ),
            matching: find.byType(DecoratedBox),
          ).first,
        );
        expect((hero.decoration as BoxDecoration).color, _lightFillFor(accent));
      },
    );

    testWidgets(
      'wf_bespoke-catalog-community-is-pixel-unchanged',
      (tester) async {
        final target = loomEvidenceTargets.firstWhere(
          (target) => target.extensionId == 'ext_garden_club',
        );
        await tester.pumpWidget(const LoomCommunitiesDemoApp());
        await installEvidenceTarget(tester, target);
        await openEvidenceTarget(tester, target);

        // Hero card identity avatar keeps its exact pre-Pass-2 formula.
        final avatar = tester.widget<CircleAvatar>(
          find.byKey(
            ValueKey('opened-community-identity-${target.communityId}'),
          ),
        );
        expect(avatar.backgroundColor, Colors.white.withValues(alpha: 0.18));

        // The "Home" tab-label header keeps its exact pre-Pass-2 fill
        // (accent at 90% alpha), not the new light treatment.
        final header = tester.widget<DecoratedBox>(
          find.byKey(const ValueKey('selected-tab-home')),
        );
        const communityAccent = Color(0xff3A7D44);
        expect(
          (header.decoration as BoxDecoration).color,
          communityAccent.withValues(alpha: 0.90),
        );

        // A bespoke-catalog workflow tile keeps its own hand-picked solid
        // accent fill, unrelated to the community accent above.
        const workflow = LoomWorkflowDefinition(
          workflowId: 'garden-export-custom-schemas',
          title: '',
          entryText: '',
          actionText: '',
          resultText: '',
        );
        await selectPersona(tester, 'garden-coordinator');
        await scrollToWorkflowCard(tester, workflow);
        final tile = tester.widget<DecoratedBox>(
          find.byKey(const ValueKey('workflow-garden-export-custom-schemas')),
        );
        expect(
          (tile.decoration as BoxDecoration).color,
          const Color(0xff376f57),
        );

        // Its pushed action surface keeps its exact pre-Pass-2 hero panel
        // fill too — solid accent, not the light treatment.
        final actorButton = find.byKey(
          const ValueKey('workflow-button-garden-export-custom-schemas'),
        );
        if (actorButton.evaluate().isNotEmpty) {
          await tester.tap(actorButton);
          await tester.pumpAndSettle();
          final hero = tester.widget<DecoratedBox>(
            find.descendant(
              of: find.byKey(
                const ValueKey(
                  'action-surface-hero-garden-export-custom-schemas',
                ),
              ),
              matching: find.byType(DecoratedBox),
            ).first,
          );
          expect(
            (hero.decoration as BoxDecoration).color,
            const Color(0xff376f57),
          );
        }
      },
    );
  });
}

Future<void> _installAndOpen(
  WidgetTester tester,
  _PackagePairFixture fixture,
) async {
  await tester.tap(find.byKey(const ValueKey('add-community-button')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('extension-package-path-field')),
    fixture.extensionPath,
  );
  await tester.enterText(
    find.byKey(const ValueKey('initialization-package-path-field')),
    fixture.initializationPath,
  );
  await tester.tap(find.byKey(const ValueKey('load-local-community-button')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(
      const ValueKey('community-card-community_verify_tabletop_club'),
    ),
  );
  await tester.pumpAndSettle();
}

class _PackagePairFixture {
  const _PackagePairFixture({
    required this.extensionPath,
    required this.initializationPath,
  });

  final String extensionPath;
  final String initializationPath;
}

_PackagePairFixture _writeTabletopClubPackagePair() {
  final tempDir = Directory.systemTemp.createTempSync('loom_b31_tabletop_');
  final extensionFile = File(
    '${tempDir.path}/$_extensionId.loom-extension.zip',
  );
  final initializationFile = File(
    '${tempDir.path}/$_extensionId.loom-init.zip',
  );
  extensionFile.writeAsStringSync(
    jsonEncode({
      'schemaVersion': 1,
      'mode': 'local-demo',
      'extensionId': _extensionId,
      'displayName': 'Tabletop Club',
      'version': '1.0.0',
      'permissions': ['content.publish', 'events.write', 'forms.write'],
    }),
  );
  initializationFile.writeAsStringSync(
    jsonEncode({
      'specVersion': currentCommunitySpecVersion,
      'communityId': 'community_verify_tabletop_club',
      'communityName': 'Tabletop Club',
      'extensionId': _extensionId,
      'seedDataFiles': ['seed/community.json', 'seed/workflows.json'],
      'branding': {'accentColor': '#C4703F'},
      'experience': {
        'displayName': 'Tabletop Club',
        'tagline':
            'Board game nights, loaner games, and dues for local tabletop fans.',
        'accentColor': '#C4703F',
        'theme': {'accent': '#C4703F'},
        'roles': [
          {
            'roleId': 'tabletop-organizer',
            'label': 'Organizer',
            'roleLabel': 'Organizer',
            'description': 'Plans game nights and tournaments.',
          },
          {
            'roleId': 'tabletop-member',
            'label': 'Member',
            'roleLabel': 'Member',
            'description': 'RSVPs to game nights and tournaments.',
          },
        ],
        'workflows': [
          {
            'workflowId': 'tabletop-game-night-rsvp',
            'title': 'RSVP to Friday game night',
            'entryText':
                'Friday game night at the community room, 7-10pm. 12 of 20 seats filled.',
            'actionText': "Reserve a seat at Friday's game night.",
            'resultText': "You're on the roster for Friday's game night.",
            'calendar': {
              'date': '2026-07-10',
              'time': '19:00',
              'location': 'Community room',
              'capacityLabel': '12 of 20 seats filled',
            },
          },
        ],
        'personaPolicies': {
          'tabletop-game-night-rsvp': {
            'actorPersonaIds': ['tabletop-member'],
            'receiverPersonaIds': ['tabletop-organizer'],
            'receiverEntryText': "A member RSVP'd to Friday's game night.",
            'receiverActionText': 'Acknowledge RSVP',
            'receiverResultText': 'RSVP acknowledged and added to the roster.',
          },
        },
      },
    }),
  );
  return _PackagePairFixture(
    extensionPath: extensionFile.path,
    initializationPath: initializationFile.path,
  );
}
