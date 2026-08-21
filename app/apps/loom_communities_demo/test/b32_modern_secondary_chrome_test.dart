import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

const _extensionId = 'ext_verify_tabletop_chrome';
const _accent = Color(0xffC4703F);

/// Mirrors `LoomCardTheme.deriveFromAccent(accent, lightSurface: true)`'s
/// fill formula.
Color _lightFillFor(Color accent) {
  return Color.alphaBlend(accent.withValues(alpha: 0.07), Colors.white);
}

void main() {
  group('B32 modern secondary chrome and controls', () {
    testWidgets(
      'wf_themed-community-gets-accent-chrome-and-solid-accent-buttons',
      (tester) async {
        final fixture = _writeChromeFixture();
        await tester.pumpWidget(const LoomCommunitiesDemoApp());
        await _installAndOpen(tester, fixture);

        // Sponsored banner: ink text on the themed fill, not hardcoded white.
        final bannerText = tester.widget<Text>(
          find.text('No sponsored message right now.'),
        );
        expect(bannerText.style?.color, isNot(Colors.white));
        final bannerBox = tester.widget<DecoratedBox>(
          find
              .ancestor(
                of: find.text('No sponsored message right now.'),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        expect(
          (bannerBox.decoration as BoxDecoration).color,
          _lightFillFor(_accent),
        );

        // Persona status strip inside the hero card: accent-tinted, not the
        // gray foreground-tinted wash.
        final personaStrip = tester.widget<DecoratedBox>(
          find.byKey(const ValueKey('active-persona-card')),
        );
        expect(
          (personaStrip.decoration as BoxDecoration).color,
          _accent.withValues(alpha: 0.08),
        );

        // V4 renders the real transition row directly on its seeded instance
        // card. The primary action is a solid accent pill with a white label.
        const instanceId = 'tabletop-game-night-rsvp';
        expect(
          find.byKey(const ValueKey('engine-native-list-root-home')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('generic-instance-card-$instanceId')),
          findsOneWidget,
        );
        final goingFinder = find.byKey(
          const ValueKey('generic-instance-$instanceId-action-going'),
        );
        await waitForEngineNativeWidget(
          tester,
          goingFinder,
          description: 'member RSVP transition controls',
        );
        final going = tester.widget<FilledButton>(goingFinder);
        expect(going.style?.backgroundColor?.resolve({}), _accent);
        expect(going.style?.foregroundColor?.resolve({}), Colors.white);

        final maybe = tester.widget<OutlinedButton>(
          find.byKey(
            const ValueKey('generic-instance-$instanceId-action-maybe'),
          ),
        );
        expect(
          maybe.style?.backgroundColor?.resolve({}),
          _accent.withValues(alpha: 0.12),
        );

        final errorColor = Colors.red.shade700;
        final cantGo = tester.widget<FilledButton>(
          find.byKey(
            const ValueKey('generic-instance-$instanceId-action-cant-go'),
          ),
        );
        expect(cantGo.style?.backgroundColor?.resolve({}), errorColor);
        expect(cantGo.style?.backgroundColor?.resolve({}), isNot(_accent));

        await scrollFinderIntoViewport(tester, goingFinder);
        await tester.tap(goingFinder);
        await tester.pumpAndSettle();
        await waitForEngineNativeWidget(
          tester,
          find.text('Response: Going'),
          description: 'persisted Going workflow state',
        );

        // Persona picker dialog is restyled to the community's light fill.
        await tester.tap(find.byKey(const ValueKey('persona-picker-button')));
        await tester.pumpAndSettle();
        final dialog = tester.widget<AlertDialog>(
          find.byKey(const ValueKey('persona-picker-dialog')),
        );
        expect(dialog.backgroundColor, _lightFillFor(_accent));
      },
    );

    testWidgets('wf_bespoke-catalog-community-chrome-is-pixel-unchanged', (
      tester,
    ) async {
      final target = loomEvidenceTargets.firstWhere(
        (target) => target.extensionId == 'ext_garden_club',
      );
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await installEvidenceTarget(tester, target);
      await openEvidenceTarget(tester, target);

      // Sponsored banner keeps its exact pre-Pass-3 white-on-transparent
      // formula for a community with no `experience.theme` block.
      final bannerText = tester.widget<Text>(
        find.text('No sponsored message right now.'),
      );
      expect(bannerText.style?.color, Colors.white);
      final bannerBox = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.text('No sponsored message right now.'),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(
        (bannerBox.decoration as BoxDecoration).color,
        Colors.white.withValues(alpha: 0.10),
      );

      // Persona picker stays the stock, unstyled AlertDialog.
      await tester.tap(find.byKey(const ValueKey('persona-picker-button')));
      await tester.pumpAndSettle();
      final dialog = tester.widget<AlertDialog>(
        find.byKey(const ValueKey('persona-picker-dialog')),
      );
      expect(dialog.backgroundColor, isNull);
    });
  });
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
    find.byKey(
      const ValueKey('community-card-community_verify_tabletop_chrome'),
    ),
  );
  await tester.pumpAndSettle();
  await selectPersona(tester, 'tabletop-member');
  await waitForEngineNativeWidget(
    tester,
    find.byKey(const ValueKey('engine-native-list-root-home')),
    description: 'Tabletop Club engine-native Home surface',
  );
}

EvidencePackagePair _writeChromeFixture() {
  final definition = engineNativeTestWorkflowDefinition(
    initialState: 'open',
    states: <String, Object?>{
      'open': <String, Object?>{'label': 'Awaiting response'},
      'going': <String, Object?>{'label': 'Going', 'isTerminal': true},
      'maybe': <String, Object?>{'label': 'Maybe', 'isTerminal': true},
      'cant-go': <String, Object?>{'label': 'Can\'t go', 'isTerminal': true},
    },
    transitions: <Map<String, Object?>>[
      <String, Object?>{
        'id': 'going',
        'label': 'Going',
        'tone': 'primary',
        'from': <String>['open'],
        'to': 'going',
        'guard': <String, Object?>{
          'allowedRoleIds': <String>['tabletop-member'],
        },
        'effects': <Object?>[
          <String, Object?>{'op': 'set', 'key': 'response', 'value': 'Going'},
        ],
      },
      <String, Object?>{
        'id': 'maybe',
        'label': 'Maybe',
        'tone': 'secondary',
        'from': <String>['open'],
        'to': 'maybe',
        'guard': <String, Object?>{
          'allowedRoleIds': <String>['tabletop-member'],
        },
        'effects': <Object?>[
          <String, Object?>{'op': 'set', 'key': 'response', 'value': 'Maybe'},
        ],
      },
      <String, Object?>{
        'id': 'cant-go',
        'label': 'Can\'t go',
        'tone': 'destructive',
        'from': <String>['open'],
        'to': 'cant-go',
        'guard': <String, Object?>{
          'allowedRoleIds': <String>['tabletop-member'],
        },
        'effects': <Object?>[
          <String, Object?>{
            'op': 'set',
            'key': 'response',
            'value': 'Can\'t go',
          },
        ],
      },
    ],
    renderBindings: <Map<String, Object?>>[
      engineNativeTestRenderBinding(
        states: <String>['open', 'going', 'maybe', 'cant-go'],
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
      'response': <String, Object?>{
        'type': 'text',
        'writableBy': 'effect',
        'storage': 'inline',
        'labelTemplate': 'Response: {value}',
        'hideWhenEmpty': true,
      },
    },
  );
  return writeEngineNativeTestPackagePair(
    tempDirectoryPrefix: 'loom_b32_chrome_',
    extensionId: _extensionId,
    communityId: 'community_verify_tabletop_chrome',
    displayName: 'Tabletop Club',
    experience: <String, Object?>{
      'displayName': 'Tabletop Club',
      'tagline': 'Board game nights and dues for local tabletop fans.',
      'accentColor': '#C4703F',
      'theme': {'accent': '#C4703F'},
      'roles': [
        {
          'roleId': 'tabletop-member',
          'label': 'Member',
          'roleLabel': 'Member',
          'description': 'RSVPs to game nights.',
        },
        {
          'roleId': 'tabletop-organizer',
          'label': 'Organizer',
          'roleLabel': 'Organizer',
          'description': 'Plans game nights.',
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
          instanceData: <String, Object?>{'title': 'RSVP to Friday game night'},
        ),
      ],
    },
  );
}
