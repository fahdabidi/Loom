import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

Future<void> installEvidenceTarget(
  WidgetTester tester,
  LoomEvidenceTarget target, {
  ValueKey<String> openButtonKey = const ValueKey('add-community-button'),
}) async {
  final fixture = writeEvidencePackagePair(target);
  await tester.tap(find.byKey(openButtonKey));
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
}

Future<void> openEvidenceTarget(
  WidgetTester tester,
  LoomEvidenceTarget target,
) async {
  final card = find.byKey(ValueKey('community-card-${target.communityId}'));
  await tester.scrollUntilVisible(
    card,
    160,
    scrollable: find.byType(Scrollable).last,
    maxScrolls: 40,
  );
  await tester.ensureVisible(card);
  await tester.pumpAndSettle();
  await tester.tap(card, warnIfMissed: false);
  await tester.pumpAndSettle();
  expect(
    find.byKey(ValueKey('local-extension-${target.extensionId}')),
    findsOneWidget,
  );
}

Future<void> selectPersona(WidgetTester tester, String personaId) async {
  await tester.tap(find.byKey(const ValueKey('persona-picker-button')));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('persona-picker-dialog')), findsOneWidget);
  await tester.tap(find.byKey(ValueKey('persona-option-$personaId')));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('persona-picker-dialog')), findsNothing);
}

Future<void> scrollToWorkflowCard(
  WidgetTester tester,
  LoomWorkflowDefinition workflow,
) async {
  final workflowCard = find.byKey(ValueKey('workflow-${workflow.workflowId}'));
  if (workflowCard.evaluate().isNotEmpty) {
    await tester.ensureVisible(workflowCard);
    await tester.pumpAndSettle();
    return;
  }

  final scrollable = find.byType(Scrollable);
  expect(scrollable, findsWidgets);
  for (final offset in const [Offset(0, -240), Offset(0, 240)]) {
    for (var attempt = 0; attempt < 40; attempt += 1) {
      await tester.drag(scrollable.last, offset, warnIfMissed: false);
      await tester.pumpAndSettle();
      if (workflowCard.evaluate().isNotEmpty) {
        await tester.ensureVisible(workflowCard);
        await tester.pumpAndSettle();
        return;
      }
    }
  }

  fail('Could not find workflow card ${workflow.workflowId}');
}

Future<void> completeWorkflow(
  WidgetTester tester,
  LoomWorkflowDefinition workflow,
) async {
  await scrollToWorkflowCard(tester, workflow);
  await tester.tap(
    find.byKey(ValueKey('workflow-button-${workflow.workflowId}')),
  );
  await tester.pumpAndSettle();
  expect(
    find.byKey(ValueKey('workflow-action-surface-${workflow.workflowId}')),
    findsOneWidget,
  );
  await tester.tap(
    find.byKey(ValueKey('workflow-action-submit-${workflow.workflowId}')),
  );
  await tester.pumpAndSettle();
  await scrollToWorkflowCard(tester, workflow);
  expect(
    find.byKey(ValueKey('workflow-complete-${workflow.workflowId}')),
    findsOneWidget,
  );
  expect(
    find.byKey(ValueKey('workflow-result-${workflow.workflowId}')),
    findsOneWidget,
  );
}

Future<void> completeWorkflowAsActor(
  WidgetTester tester, {
  required String extensionId,
  required LoomWorkflowDefinition workflow,
}) async {
  final policy = personaPolicyForWorkflow(extensionId, workflow.workflowId);
  await selectPersona(tester, policy.actorPersonaIds.first);
  await completeWorkflow(tester, workflow);
}

Future<void> receiveWorkflow(
  WidgetTester tester,
  LoomWorkflowDefinition workflow,
) async {
  await scrollToWorkflowCard(tester, workflow);
  await tester.tap(
    find.byKey(ValueKey('workflow-receive-button-${workflow.workflowId}')),
  );
  await tester.pumpAndSettle();
  expect(
    find.byKey(ValueKey('workflow-receive-surface-${workflow.workflowId}')),
    findsOneWidget,
  );
  await tester.tap(
    find.byKey(ValueKey('workflow-receive-submit-${workflow.workflowId}')),
  );
  await tester.pumpAndSettle();
  await scrollToWorkflowCard(tester, workflow);
  expect(
    find.byKey(ValueKey('workflow-received-${workflow.workflowId}')),
    findsOneWidget,
  );
  expect(
    find.byKey(ValueKey('workflow-received-result-${workflow.workflowId}')),
    findsOneWidget,
  );
}

Future<void> completeTargetWorkflows(
  WidgetTester tester,
  LoomEvidenceTarget target,
) async {
  await tester.pumpWidget(const LoomCommunitiesDemoApp());
  await installEvidenceTarget(tester, target);
  await openEvidenceTarget(tester, target);
  final experience = experienceForExtensionId(
    target.extensionId,
    displayName: target.communityName,
  );
  expect(find.text(experience.tagline), findsOneWidget);
  for (final workflow in experience.workflows) {
    await completeWorkflowAsActor(
      tester,
      extensionId: target.extensionId,
      workflow: workflow,
    );
  }
}

EvidencePackagePair writeEvidencePackagePair(LoomEvidenceTarget target) {
  final tempDir = Directory.systemTemp.createTempSync(
    'loom_${target.extensionId}_',
  );
  final extensionFile = File(
    '${tempDir.path}/${target.handle}.loom-extension.zip',
  );
  final initializationFile = File(
    '${tempDir.path}/${target.handle}.loom-init.zip',
  );
  extensionFile.writeAsStringSync(
    jsonEncode({
      'schemaVersion': 1,
      'mode': 'local-demo',
      'extensionId': target.extensionId,
      'displayName': target.communityName,
      'version': '1.0.0',
      'permissions': [
        'community.install',
        'content.publish',
        'events.write',
        'forms.write',
        'payments.write',
        'export.read',
      ],
      'assets': {
        'logo': 'assets/brand/${target.handle}-logo.png',
        'cardImage': 'assets/brand/${target.handle}-card.png',
        'heroImage': 'assets/brand/${target.handle}-hero.png',
        'defaultCardImage': 'assets/brand/${target.handle}-default-card.png',
      },
      'routes': [
        {
          'routeId': 'home',
          'title': target.communityName,
          'surface': 'community-home',
        },
      ],
      'workflows': [
        for (final workflow in experienceForExtensionId(
          target.extensionId,
        ).workflows)
          workflow.workflowId,
      ],
    }),
  );
  initializationFile.writeAsStringSync(
    jsonEncode({
      'schemaVersion': 1,
      'packageId': 'init_${target.communityId}',
      'communityId': target.communityId,
      'communityHandle': target.handle,
      'communityName': target.communityName,
      'displayName': target.communityName,
      'extensionId': target.extensionId,
      'seedDataFiles': target.seedDataFiles,
      'branding': {
        'cardAssetId': 'seed/assets/${target.handle}-card.png',
        'logoAssetId': 'seed/assets/${target.handle}-logo.png',
        'heroImageAssetId': 'seed/assets/${target.handle}-hero.png',
        'accentColor': target.accentColor,
      },
    }),
  );
  return EvidencePackagePair(
    extensionPath: extensionFile.path,
    initializationPath: initializationFile.path,
  );
}

class EvidencePackagePair {
  const EvidencePackagePair({
    required this.extensionPath,
    required this.initializationPath,
  });

  final String extensionPath;
  final String initializationPath;
}
