import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

void main() {
  test('wf_production-workflow-ux-contract-matrix', () {
    var rowCount = 0;
    for (final target in loomEvidenceTargets) {
      final experience = experienceForExtensionId(
        target.extensionId,
        displayName: target.communityName,
      );
      final personas = personasForExtensionId(target.extensionId);
      for (final workflow in experience.workflows) {
        final contract = productionWorkflowContractFor(
          extensionId: target.extensionId,
          workflow: workflow,
        );
        expect(contract.category, isNotEmpty);
        expect(contract.cardSurfaceFamily, isNotEmpty);
        expect(contract.apiContract, startsWith('Community'));
        expect(contract.requiredInteractions, isNotEmpty);
        expect(contract.primaryActions, isNotEmpty);
        expect(contract.alternateActions, isNotEmpty);
        expect(contract.rendererTarget, isNotEmpty);
        expect(contract.fakeBackendSupport, contains('LocalInAppBackend'));
        expect(contract.primaryActionLabel, isNot('Complete'));
        expect(contract.primaryActionLabel, isNot('Complete workflow'));
        expect(contract.inputSummary, isNotEmpty);
        expect(contract.validationSummary, isNotEmpty);
        expect(contract.receiverSurfaceTitle, endsWith('ready'));
        for (final persona in personas) {
          final state = personaWorkflowStateFor(
            extensionId: target.extensionId,
            workflowId: workflow.workflowId,
            personaId: persona.personaId,
          );
          expect(state, isA<LoomPersonaWorkflowState>());
          rowCount += 1;
        }
      }
    }
    expect(rowCount, greaterThan(100));
  });

  test('wf_card-surface-registry-context-is-available', () {
    for (final target in loomEvidenceTargets) {
      final workflows = experienceForExtensionId(target.extensionId).workflows;
      final registry = cardSurfaceRegistryForExtensionId(target.extensionId);
      expect(registry, hasLength(workflows.length));
      for (final entry in registry) {
        expect(entry.workflowId, isNotEmpty);
        expect(entry.cardSurfaceFamily, isNotEmpty);
        expect(entry.apiContract, startsWith('Community'));
        expect(entry.requiredInteractions, isNotEmpty);
        expect(entry.primaryActions, isNotEmpty);
        expect(entry.alternateActions, isNotEmpty);
        expect(entry.rendererTarget, isNotEmpty);
        expect(entry.fakeBackendSupport, contains('LocalInAppBackend'));
      }
    }
  });

  testWidgets('wf_domain-specific-workflow-surfaces', (tester) async {
    final target = loomEvidenceTargets.singleWhere(
      (target) => target.extensionId == 'ext_mosque',
    );
    await tester.pumpWidget(const LoomCommunitiesDemoApp());
    await installEvidenceTarget(tester, target);
    await openEvidenceTarget(tester, target);

    expect(find.text('Community workflows'), findsNothing);
    expect(find.text('Announcements'), findsOneWidget);
    expect(find.text('Workflow checklist'), findsNothing);
    expect(find.text('Complete'), findsNothing);
    expect(find.text('Complete workflow'), findsNothing);
    expect(find.text('Can perform this workflow.'), findsNothing);
    expect(find.text('Publishing surface'), findsNothing);
    expect(find.text('Event surface'), findsNothing);
    expect(find.text('Action available for this role.'), findsNothing);
    expect(
      find.text('Receives the result after the responsible role submits it.'),
      findsNothing,
    );

    final workflow = experienceForExtensionId(target.extensionId).workflows
        .firstWhere((workflow) => workflow.workflowId == 'mosque-announcement');
    await scrollToWorkflowCard(tester, workflow);
    await tester.pumpAndSettle();
    expect(find.text('Publish announcement'), findsOneWidget);

    final workflowButton = find.byKey(
      ValueKey('workflow-button-${workflow.workflowId}'),
    );
    await tester.ensureVisible(workflowButton);
    await tester.pumpAndSettle();
    await tester.tap(workflowButton);
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('workflow-action-surface-${workflow.workflowId}')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(ValueKey('workflow-action-submit-${workflow.workflowId}')),
      180,
      scrollable: verticalScrollableFinder().last,
      maxScrolls: 30,
    );
    await tester.pumpAndSettle();
    expect(find.text('Publish announcement'), findsWidgets);
    expect(find.text('Complete workflow'), findsNothing);
  });

  testWidgets('wf_persona-production-ux-cross-persona-state', (tester) async {
    final target = loomEvidenceTargets.singleWhere(
      (target) => target.extensionId == 'ext_mosque',
    );
    await tester.pumpWidget(const LoomCommunitiesDemoApp());
    await installEvidenceTarget(tester, target);
    await openEvidenceTarget(tester, target);
    final workflow = experienceForExtensionId(target.extensionId).workflows
        .firstWhere((workflow) => workflow.workflowId == 'mosque-announcement');

    await selectPersona(tester, 'mosque-admin');
    await completeWorkflow(tester, workflow);
    expect(find.text('Announcement posted'), findsOneWidget);

    await selectPersona(tester, 'mosque-member');
    final workflowCard = find.byKey(
      ValueKey('workflow-${workflow.workflowId}'),
    );
    for (
      var attempt = 0;
      attempt < 8 && workflowCard.evaluate().isEmpty;
      attempt += 1
    ) {
      await tester.drag(verticalScrollableFinder().last, const Offset(0, 240));
      await tester.pumpAndSettle();
    }
    expect(workflowCard, findsOneWidget);
    expect(find.text('Receive announcement'), findsOneWidget);
    final receiveButton = find.byKey(
      ValueKey('workflow-receive-button-${workflow.workflowId}'),
    );
    await tester.ensureVisible(receiveButton);
    await tester.pumpAndSettle();
    await tester.tap(receiveButton);
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('workflow-receive-surface-${workflow.workflowId}')),
      findsOneWidget,
    );
    final receiveSubmitButton = find.byKey(
      ValueKey('workflow-receive-submit-${workflow.workflowId}'),
    );
    await tester.scrollUntilVisible(
      receiveSubmitButton,
      180,
      scrollable: verticalScrollableFinder().last,
      maxScrolls: 30,
    );
    await tester.pumpAndSettle();
    await tester.tap(receiveSubmitButton);
    await tester.pumpAndSettle();
    expect(find.text('Update ready'), findsOneWidget);
  });

  test('wf_production-ux-evidence-certification-sweep', () {
    expect(productionUxGenericCopyViolations(), isEmpty);
  });

  test('wf_independent-production-ux-review', () {
    final reviewFile = File(
      '$_repoRoot/docs/Build Plan V2/Evidence/B25/independent-production-ux-review.json',
    );
    final blueprintFile = File(
      '$_repoRoot/docs/Build Plan V2/Evidence/B25/production-ux-blueprint.md',
    );
    expect(reviewFile.existsSync(), isTrue);
    expect(blueprintFile.existsSync(), isTrue);

    final review =
        jsonDecode(reviewFile.readAsStringSync()) as Map<String, Object?>;
    expect(review['schemaVersion'], 4);
    expect(review['reviewStandardVersion'], 'b25-production-ux-v4');
    expect(review['status'], isNotEmpty);
    expect(review['finalDecision'], isNotEmpty);

    final unresolvedBlockerFindings =
        (review['unresolvedBlockerFindings'] as List<Object?>);
    final unresolvedMajorFindings =
        (review['unresolvedMajorFindings'] as List<Object?>);
    if (review['b25CanPass'] == true) {
      expect(review['finalDecision'], 'pass');
      expect(review['requiresRemediation'], isFalse);
      expect(review['requiresRerun'], isFalse);
      expect(unresolvedBlockerFindings, isEmpty);
      expect(unresolvedMajorFindings, isEmpty);
    } else {
      expect(review['finalDecision'], 'fail');
      expect(review['requiresRemediation'], isTrue);
      expect(review['requiresRerun'], isTrue);
      expect(
        unresolvedBlockerFindings.length + unresolvedMajorFindings.length,
        greaterThan(0),
      );
    }

    final blueprintCoverage = (review['blueprintCoverage'] as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(blueprintCoverage.length, greaterThanOrEqualTo(10));
    expect(blueprintCoverage.every((row) => row['status'] == 'pass'), isTrue);

    final screenRows = (review['screenRows'] as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(screenRows.length, greaterThanOrEqualTo(190));
    final rowIds = <String>{};
    for (final row in screenRows) {
      final rowId = row['rowId'] as String? ?? '';
      expect(rowId, isNotEmpty);
      expect(rowIds.add(rowId), isTrue, reason: 'Duplicate rowId: $rowId');
      expect(row['communityName'], isNotEmpty);
      expect(row['persona'], isNotEmpty);
      expect(row['screenOrState'], isNotEmpty);
      expect(row['screenshotPath'], isNotEmpty);
      expect(row['productUxCritique'], isNotEmpty);
      expect(row['verdict'], isNot('pending'));
    }

    final findings = (review['findings'] as List<Object?>)
        .cast<Map<String, Object?>>();
    final openBlockingFindings = findings
        .where(
          (finding) =>
              (finding['severity'] == 'blocker' ||
                  finding['severity'] == 'major') &&
              finding['status'] != 'resolved',
        )
        .toList();
    if (review['b25CanPass'] == true) {
      expect(openBlockingFindings, isEmpty);
    } else {
      expect(openBlockingFindings, isNotEmpty);
    }
  });

  testWidgets('wf_b25-local-shell-production-polish-gates', (tester) async {
    await tester.pumpWidget(const LoomCommunitiesDemoApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.debugShowCheckedModeBanner, isFalse);

    final target = loomEvidenceTargets.singleWhere(
      (target) => target.extensionId == 'ext_garden_club',
    );
    await installEvidenceTarget(tester, target);

    final list = tester.widget<ListView>(
      find.byKey(const ValueKey('community-list')),
    );
    final padding = list.padding!.resolve(TextDirection.ltr);
    expect(padding.bottom, greaterThanOrEqualTo(120));

    expect(
      find.byKey(
        const ValueKey('community-card-identity-community_garden_club'),
      ),
      findsOneWidget,
    );
    expect(find.text('G'), findsNothing);
  });
}

String get _repoRoot {
  final candidates = [
    Directory.current.parent.path,
    Directory.current.parent.parent.parent.path,
  ];
  for (final candidate in candidates) {
    if (File('$candidate/docs/Build Plan V2/Skill/SKILL.md').existsSync()) {
      return candidate;
    }
  }
  fail('Could not find repo root from ${Directory.current.path}');
}
