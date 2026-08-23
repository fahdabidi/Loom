import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

const _extensionId = 'ext_verify_tabletop_club';

/// Mirrors `LoomCardTheme.deriveFromAccent(accent, lightSurface: true)`'s
/// fill formula — the light, subtle card fill every card surface in a
/// community that declares an `experience.theme` block resolves to.
Color _lightFillFor(Color accent) {
  return Color.alphaBlend(accent.withValues(alpha: 0.07), Colors.white);
}

void main() {
  group(
    'B31 modern card surface theme applies everywhere, gated correctly',
    () {
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

          // The engine-native workflow card itself (not just its tab chrome) is
          // light too.
          const instanceId = 'tabletop-game-night-rsvp';
          expect(
            find.byKey(const ValueKey('engine-native-list-root-home')),
            findsOneWidget,
          );
          final workflowCard = find.byKey(
            const ValueKey('generic-instance-card-$instanceId'),
          );
          expect(workflowCard, findsOneWidget);
          final tile = tester.widget<Card>(workflowCard);
          expect(tile.color, _lightFillFor(accent));

          // V4 has no pushed legacy action surface. Its engine transition lives
          // on the card and must inherit the same modern theme before and after
          // the persisted mutation.
          await selectActorIdentity(tester, 'tabletop-member');
          final reserveButton = find.byKey(
            const ValueKey('generic-instance-$instanceId-action-reserve-seat'),
          );
          await waitForEngineNativeWidget(
            tester,
            reserveButton,
            description: 'member-gated reserve-seat transition',
          );
          expect(reserveButton, findsOneWidget);
          final themedButton = tester.widget<FilledButton>(reserveButton);
          expect(themedButton.style?.backgroundColor?.resolve({}), accent);
          await scrollFinderIntoViewport(tester, reserveButton);
          await tester.tap(reserveButton);
          await tester.pumpAndSettle();
          final reserved = find.textContaining('Reserved');
          await waitForEngineNativeWidget(
            tester,
            reserved,
            description: 'persisted Reserved workflow state',
          );
          expect(reserved, findsOneWidget);
          final completedCard = tester.widget<Card>(
            find.byKey(const ValueKey('generic-instance-card-$instanceId')),
          );
          expect(completedCard.color, _lightFillFor(accent));
        },
      );

      testWidgets('wf_bespoke-catalog-community-is-pixel-unchanged', (
        tester,
      ) async {
        final target = loomEvidenceTargets.firstWhere(
          (target) => target.extensionId == 'ext_garden_club',
        );
        await tester.pumpWidget(const LoomCommunitiesDemoApp());
        await installMetadataEvidenceTarget(tester, target);
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
        await selectActorIdentity(tester, 'garden-coordinator');
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
            find
                .descendant(
                  of: find.byKey(
                    const ValueKey(
                      'action-surface-hero-garden-export-custom-schemas',
                    ),
                  ),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          );
          expect(
            (hero.decoration as BoxDecoration).color,
            const Color(0xff376f57),
          );
        }
      });
    },
  );
}

Future<void> _installAndOpen(
  WidgetTester tester,
  EvidencePackagePair fixture,
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
    find.byKey(const ValueKey('community-card-community_verify_tabletop_club')),
  );
  await tester.pumpAndSettle();
  await selectActorIdentity(tester, 'tabletop-organizer');
  await waitForEngineNativeWidget(
    tester,
    find.byKey(const ValueKey('engine-native-list-root-home')),
    description: 'Tabletop Club engine-native Home surface',
  );
}

EvidencePackagePair _writeTabletopClubPackagePair() {
  final definition = engineNativeTestWorkflowDefinition(
    initialState: 'open',
    states: <String, Object?>{
      'open': <String, Object?>{'label': 'RSVP open'},
      'reserved': <String, Object?>{'label': 'Reserved', 'isTerminal': true},
    },
    transitions: <Map<String, Object?>>[
      <String, Object?>{
        'id': 'reserve-seat',
        'label': 'Reserve seat',
        'tone': 'primary',
        'from': <String>['open'],
        'to': 'reserved',
        'guard': <String, Object?>{
          'allowedRoleIds': <String>['tabletop-member'],
        },
        'effects': <Object?>[
          <String, Object?>{'op': 'set', 'key': 'status', 'value': 'Reserved'},
        ],
      },
    ],
    renderBindings: <Map<String, Object?>>[
      engineNativeTestRenderBinding(
        states: <String>['open', 'reserved'],
        tabId: 'home',
        cardSurfaceFamily: 'statusTimeline',
      ),
    ],
    instanceDataSchema: <String, Object?>{
      'title': <String, Object?>{
        'type': 'text',
        'storage': 'inline',
        'labelTemplate': '{value}',
      },
      'status': <String, Object?>{
        'type': 'text',
        'writableBy': 'effect',
        'storage': 'inline',
        'labelTemplate': 'Status: {value}',
      },
    },
  );
  return writeEngineNativeTestPackagePair(
    tempDirectoryPrefix: 'loom_b31_tabletop_',
    extensionId: _extensionId,
    communityId: 'community_verify_tabletop_club',
    displayName: 'Tabletop Club',
    experience: <String, Object?>{
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
      'workflowDefinitions': <String, Object?>{
        'tabletop-game-night-rsvp': definition,
      },
      'workflowInstances': <Object?>[
        engineNativeTestWorkflowInstance(
          instanceId: 'tabletop-game-night-rsvp',
          workflowType: 'tabletop-game-night-rsvp',
          currentState: 'open',
          createdByFanId: 'tabletop-organizer',
          instanceData: <String, Object?>{
            'title': 'RSVP to Friday game night',
            'status': 'Open',
          },
        ),
      ],
    },
  );
}
