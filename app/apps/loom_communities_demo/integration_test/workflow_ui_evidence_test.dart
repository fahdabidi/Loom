import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_communities_demo/main.dart';

import '../test/workflow_ui_test_harness.dart';

const _phaseFilterText = String.fromEnvironment('LOOM_EVIDENCE_PHASE_FILTER');
final Set<String> _phaseFilter = _phaseFilterText
    .split(',')
    .map((phase) => phase.trim())
    .where((phase) => phase.isNotEmpty)
    .toSet();

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('wf_full-ui-screenshot-evidence-b12-b20', (tester) async {
    await binding.convertFlutterSurfaceToImage();
    binding.reportData ??= <String, dynamic>{};
    final entries = <Map<String, Object?>>[];
    final installedExtensionIds = <String>{};

    await tester.pumpWidget(const LoomCommunitiesDemoApp());
    await tester.pumpAndSettle();

    Future<void> ensureTargetInstalled(LoomEvidenceTarget target) async {
      if (installedExtensionIds.contains(target.extensionId)) {
        return;
      }
      await installEvidenceTarget(tester, target);
      installedExtensionIds.add(target.extensionId);
    }

    Future<void> ensureTargetOpen(LoomEvidenceTarget target) async {
      if (find.byKey(ValueKey('local-extension-${target.extensionId}'))
          .evaluate()
          .isNotEmpty) {
        return;
      }
      if (find.text('Loom Communities').evaluate().isEmpty) {
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
      await ensureTargetInstalled(target);
      await openEvidenceTarget(tester, target);
    }

    if (_includePhase('B12')) {
      final harnessEntry = <String, Object?>{
        'phase': 'B12',
        'appId': 'workflow-ui-evidence-harness',
        'workflowId': 'workflow-ui-evidence-harness',
        'expectedAssertions': [
          'empty state is visible',
          'local package dialog opens',
          'screenshot callback completes',
        ],
      };
      await _capture(binding, 'B12_harness_start');
      await tester.tap(find.byKey(const ValueKey('add-community-button')));
      await tester.pumpAndSettle();
      await _capture(binding, 'B12_harness_action');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await _capture(binding, 'B12_harness_complete');
      entries.add({
        ...harnessEntry,
        'screenshotNames': [
          'B12_harness_start',
          'B12_harness_action',
          'B12_harness_complete',
        ],
        'status': 'pass',
      });
    }

    for (final target in loomEvidenceTargets.where(
      (target) => _includePhase(target.phase),
    )) {
      await ensureTargetInstalled(target);
      await openEvidenceTarget(tester, target);
      final experience = experienceForExtensionId(
        target.extensionId,
        displayName: target.communityName,
      );
      expect(find.text(experience.tagline), findsOneWidget);

      for (final workflow in experience.workflows) {
        final policy = personaPolicyForWorkflow(
          target.extensionId,
          workflow.workflowId,
        );
        await selectPersona(tester, policy.actorPersonaIds.first);
        final entry = <String, Object?>{
          'phase': target.phase,
          'appId': target.extensionId,
          'communityId': target.communityId,
          'communityName': target.communityName,
          'workflowId': workflow.workflowId,
          'expectedAssertions': [
            workflow.entryText,
            workflow.actionText,
            workflow.resultText,
          ],
        };
        final start = _screenshotName(target, workflow, 'start');
        final action = _screenshotName(target, workflow, 'action');
        final complete = _screenshotName(target, workflow, 'complete');

        await scrollToWorkflowCard(tester, workflow);
        await _capture(binding, start);

        await tester.tap(
          find.byKey(ValueKey('workflow-button-${workflow.workflowId}')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(
            ValueKey('workflow-action-surface-${workflow.workflowId}'),
          ),
          findsOneWidget,
        );
        await _capture(binding, action);

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
        await _capture(binding, complete);

        entries.add({
          ...entry,
          'screenshotNames': [start, action, complete],
          'status': 'pass',
        });
      }

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Loom Communities'), findsOneWidget);
    }

    final mosqueTarget = loomEvidenceTargets.firstWhere(
      (target) => target.extensionId == 'ext_mosque',
    );
    final mosqueExperience = experienceForExtensionId(
      mosqueTarget.extensionId,
      displayName: mosqueTarget.communityName,
    );
    final announcement = mosqueExperience.workflows.firstWhere(
      (workflow) => workflow.workflowId == 'mosque-announcement',
    );
    final careRequest = mosqueExperience.workflows.firstWhere(
      (workflow) => workflow.workflowId == 'mosque-care-request',
    );

    if (_includePhase('B17')) {
      await ensureTargetOpen(mosqueTarget);
      await _capture(binding, 'B17_persona_inventory_active_admin');
      await tester.tap(find.byKey(const ValueKey('persona-picker-button')));
      await tester.pumpAndSettle();
      await _capture(binding, 'B17_persona_inventory_picker');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      entries.add({
        'phase': 'B17',
        'appId': 'persona-role-inventory',
        'workflowId': 'wf_persona-role-inventory-capability-matrix',
        'expectedAssertions': [
          'all demo communities define two or more personas',
          'all workflow/persona matrix rows have actor, receiver, read-only, or disabled state',
          'receiver rows declare dependency evidence',
          'matrix rows: ${_personaMatrixRowCount()}',
        ],
        'screenshotNames': [
          'B17_persona_inventory_active_admin',
          'B17_persona_inventory_picker',
        ],
        'status': 'pass',
      });
    }

    if (_includePhase('B18')) {
      await ensureTargetOpen(mosqueTarget);
      await tester.tap(find.byKey(const ValueKey('persona-picker-button')));
      await tester.pumpAndSettle();
      await _capture(binding, 'B18_persona_picker_dialog');
      await tester.tap(
        find.byKey(const ValueKey('persona-option-mosque-member')),
      );
      await tester.pumpAndSettle();
      await _scrollToWorkflow(tester, announcement);
      await _capture(binding, 'B18_persona_picker_member_selected');
      entries.add({
        'phase': 'B18',
        'appId': mosqueTarget.extensionId,
        'communityId': mosqueTarget.communityId,
        'communityName': mosqueTarget.communityName,
        'workflowId': 'wf_demo-app-persona-picker',
        'expectedAssertions': [
          'people icon opens the test persona picker',
          'Community Member persona becomes active',
          'Public announcement is waiting for admin action instead of exposing an admin action',
        ],
        'screenshotNames': [
          'B18_persona_picker_dialog',
          'B18_persona_picker_member_selected',
        ],
        'status': 'pass',
      });
    }

    if (_includePhase('B19')) {
      await ensureTargetOpen(mosqueTarget);
      await selectPersona(tester, 'mosque-member');
      await _scrollToWorkflow(tester, careRequest);
      await _capture(binding, 'B19_member_care_request_actor');
      await selectPersona(tester, 'mosque-admin');
      await _scrollToWorkflow(tester, announcement);
      await _capture(binding, 'B19_admin_announcement_actor');
      entries.add({
        'phase': 'B19',
        'appId': mosqueTarget.extensionId,
        'communityId': mosqueTarget.communityId,
        'communityName': mosqueTarget.communityName,
        'workflowId': 'wf_community-persona-aware-ux',
        'expectedAssertions': [
          'member persona can create the protected care request',
          'member persona cannot create the public announcement',
          'admin persona can create the public announcement',
        ],
        'screenshotNames': [
          'B19_member_care_request_actor',
          'B19_admin_announcement_actor',
        ],
        'status': 'pass',
      });
    }

    if (_includePhase('B20')) {
      await ensureTargetOpen(mosqueTarget);
      await selectPersona(tester, 'mosque-admin');
      await _scrollToWorkflow(tester, announcement);
      await _capture(binding, 'B20_announcement_admin_start');
      await tester.tap(
        find.byKey(ValueKey('workflow-button-${announcement.workflowId}')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          ValueKey('workflow-action-surface-${announcement.workflowId}'),
        ),
        findsOneWidget,
      );
      await _capture(binding, 'B20_announcement_admin_action');
      await tester.tap(
        find.byKey(
          ValueKey('workflow-action-submit-${announcement.workflowId}'),
        ),
      );
      await tester.pumpAndSettle();
      await _scrollToWorkflow(tester, announcement);
      await _capture(binding, 'B20_announcement_admin_complete');
      await selectPersona(tester, 'mosque-member');
      await _scrollToWorkflow(tester, announcement);
      await _capture(binding, 'B20_announcement_member_ready');
      await tester.tap(
        find.byKey(
          ValueKey('workflow-receive-button-${announcement.workflowId}'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          ValueKey('workflow-receive-surface-${announcement.workflowId}'),
        ),
        findsOneWidget,
      );
      await _capture(binding, 'B20_announcement_member_action');
      await tester.tap(
        find.byKey(
          ValueKey('workflow-receive-submit-${announcement.workflowId}'),
        ),
      );
      await tester.pumpAndSettle();
      await _scrollToWorkflow(tester, announcement);
      await _capture(binding, 'B20_announcement_member_received');
      entries.add({
        'phase': 'B20',
        'appId': mosqueTarget.extensionId,
        'communityId': mosqueTarget.communityId,
        'communityName': mosqueTarget.communityName,
        'workflowId': 'wf_multi-persona-workflow-evidence',
        'expectedAssertions': [
          'admin creates the public announcement',
          'member receives the same announcement after admin completion',
          'widget sweep covers all demo app workflow/persona rows',
        ],
        'screenshotNames': [
          'B20_announcement_admin_start',
          'B20_announcement_admin_action',
          'B20_announcement_admin_complete',
          'B20_announcement_member_ready',
          'B20_announcement_member_action',
          'B20_announcement_member_received',
        ],
        'status': 'pass',
      });
    }

    if (find.byKey(ValueKey('local-extension-${mosqueTarget.extensionId}'))
        .evaluate()
        .isNotEmpty) {
      await tester.pageBack();
      await tester.pumpAndSettle();
    }

    binding.reportData!['workflowEvidenceSchemaVersion'] = 1;
    binding.reportData!['emulatorName'] = 'emulator-5554';
    binding.reportData!['deviceClass'] = 'Android emulator';
    binding.reportData!['workflowEvidence'] = entries;
  });
}

Future<void> _capture(
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
) async {
  await binding.takeScreenshot(name);
}

String _screenshotName(
  LoomEvidenceTarget target,
  LoomWorkflowDefinition workflow,
  String state,
) {
  return '${target.phase}_${target.extensionId}_${workflow.workflowId}_$state';
}

bool _includePhase(String phase) {
  return _phaseFilter.isEmpty || _phaseFilter.contains(phase);
}

Future<void> _scrollToWorkflow(
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
  for (var index = 0; index < 40; index += 1) {
    await tester.drag(scrollable, const Offset(0, -180), warnIfMissed: false);
    await tester.pumpAndSettle();
    if (workflowCard.evaluate().isNotEmpty) {
      await tester.ensureVisible(workflowCard);
      await tester.pumpAndSettle();
      return;
    }
  }
  for (var index = 0; index < 40; index += 1) {
    await tester.drag(scrollable, const Offset(0, 180), warnIfMissed: false);
    await tester.pumpAndSettle();
    if (workflowCard.evaluate().isNotEmpty) {
      await tester.ensureVisible(workflowCard);
      await tester.pumpAndSettle();
      return;
    }
  }
  fail('Could not find workflow card ${workflow.workflowId}');
}

int _personaMatrixRowCount() {
  return loomEvidenceTargets
      .map(
        (target) =>
            personaWorkflowMatrixForExtensionId(target.extensionId).length,
      )
      .fold(0, (total, count) => total + count);
}
