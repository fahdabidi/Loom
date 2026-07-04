import 'dart:convert';
import 'dart:io';

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

        // The actor button is a solid accent pill with a white label (the
        // theme's primaryButton token), not the old gray ghost pill.
        const workflow = LoomWorkflowDefinition(
          workflowId: 'tabletop-game-night-rsvp',
          title: '',
          entryText: '',
          actionText: '',
          resultText: '',
        );
        await scrollToWorkflowCard(tester, workflow);
        final actorButton = tester.widget<FilledButton>(
          find.byKey(
            const ValueKey('workflow-button-tabletop-game-night-rsvp'),
          ),
        );
        expect(actorButton.style?.backgroundColor?.resolve({}), _accent);
        expect(
          actorButton.style?.foregroundColor?.resolve({}),
          Colors.white,
        );

        // Open the pushed action surface and check the response bar.
        await tester.tap(
          find.byKey(
            const ValueKey('workflow-button-tabletop-game-night-rsvp'),
          ),
        );
        await tester.pumpAndSettle();

        final going = tester.widget<FilledButton>(
          find.byKey(const ValueKey('workflow-response-going')),
        );
        expect(going.style?.backgroundColor?.resolve({}), _accent);

        final maybe = tester.widget<FilledButton>(
          find.byKey(const ValueKey('workflow-response-maybe')),
        );
        expect(
          maybe.style?.backgroundColor?.resolve({}),
          _accent.withValues(alpha: 0.12),
        );

        final cantGoElement = tester.element(
          find.byKey(const ValueKey('workflow-response-cant-go')),
        );
        final errorColor = Theme.of(cantGoElement).colorScheme.error;
        final cantGo = tester.widget<FilledButton>(
          find.byKey(const ValueKey('workflow-response-cant-go')),
        );
        expect(cantGo.style?.backgroundColor?.resolve({}), errorColor);
        expect(cantGo.style?.backgroundColor?.resolve({}), isNot(_accent));

        await tester.tap(find.byKey(const ValueKey('workflow-response-going')));
        await tester.pumpAndSettle();

        // Persona picker dialog is restyled to the community's light fill.
        await tester.tap(find.byKey(const ValueKey('persona-picker-button')));
        await tester.pumpAndSettle();
        final dialog = tester.widget<AlertDialog>(
          find.byKey(const ValueKey('persona-picker-dialog')),
        );
        expect(dialog.backgroundColor, _lightFillFor(_accent));
      },
    );

    testWidgets(
      'wf_bespoke-catalog-community-chrome-is-pixel-unchanged',
      (tester) async {
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
    find.byKey(const ValueKey('community-card-community_verify_tabletop_chrome')),
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

_PackagePairFixture _writeChromeFixture() {
  final tempDir = Directory.systemTemp.createTempSync('loom_b32_chrome_');
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
      'schemaVersion': 1,
      'communityId': 'community_verify_tabletop_chrome',
      'communityName': 'Tabletop Club',
      'extensionId': _extensionId,
      'seedDataFiles': ['seed/community.json', 'seed/workflows.json'],
      'branding': {'accentColor': '#C4703F'},
      'experience': {
        'displayName': 'Tabletop Club',
        'tagline': 'Board game nights and dues for local tabletop fans.',
        'accentColor': '#C4703F',
        'theme': {'accent': '#C4703F'},
        'personas': [
          {
            'personaId': 'tabletop-member',
            'label': 'Member',
            'roleLabel': 'Member',
            'description': 'RSVPs to game nights.',
          },
          {
            'personaId': 'tabletop-organizer',
            'label': 'Organizer',
            'roleLabel': 'Organizer',
            'description': 'Plans game nights.',
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
            'responseChoices': [
              {'responseId': 'going', 'label': 'Going'},
              {'responseId': 'maybe', 'label': 'Maybe'},
              {
                'responseId': 'cant-go',
                'label': "Can't go",
                'isDestructive': true,
              },
            ],
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
