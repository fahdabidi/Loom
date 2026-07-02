import 'dart:convert';

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
const _workflowShardCount = int.fromEnvironment(
  'LOOM_EVIDENCE_WORKFLOW_SHARD_COUNT',
  defaultValue: 1,
);
const _workflowShardIndex = int.fromEnvironment(
  'LOOM_EVIDENCE_WORKFLOW_SHARD_INDEX',
);
const _preloadExampleCommunities = bool.fromEnvironment(
  'LOOM_PRELOAD_EXAMPLE_COMMUNITIES',
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('wf_full-ui-screenshot-evidence-b12-b20', (tester) async {
    await binding.convertFlutterSurfaceToImage();
    binding.reportData ??= <String, dynamic>{};
    final entries = <Map<String, Object?>>[];
    final installedExtensionIds = _preloadExampleCommunities
        ? {for (final target in loomEvidenceTargets) target.extensionId}
        : <String>{};
    final screenshotVisibleTextByName = <String, String>{};
    final totalWorkflowEvidenceEntries = _workflowEvidenceEntryCount();
    var completedWorkflowEvidenceEntries = 0;

    void emitProgress(
      String status, {
      required String phase,
      required String workflowId,
      String? communityName,
      String? screenshotName,
    }) {
      if (status == 'workflow-complete') {
        completedWorkflowEvidenceEntries += 1;
      }
      _emitCaptureProgress({
        'status': status,
        'phase': phase,
        'workflowId': workflowId,
        if (communityName != null) 'communityName': communityName,
        if (screenshotName != null) 'screenshotName': screenshotName,
        'completedWorkflows': completedWorkflowEvidenceEntries,
        'totalWorkflows': totalWorkflowEvidenceEntries,
      });
    }

    Future<void> capture(String name) {
      _emitCaptureProgress({
        'status': 'screenshot-start',
        'phase': _phaseForScreenshotName(name),
        'screenshotName': name,
        'completedWorkflows': completedWorkflowEvidenceEntries,
        'totalWorkflows': totalWorkflowEvidenceEntries,
      });
      return _capture(binding, tester, screenshotVisibleTextByName, name);
    }

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
      if (find
          .byKey(ValueKey('local-extension-${target.extensionId}'))
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

    Future<void> returnToCommunityList() async {
      if (find.text('Loom Communities').evaluate().isNotEmpty) {
        return;
      }
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Loom Communities'), findsOneWidget);
    }

    if (_includePhase('B12')) {
      emitProgress(
        'workflow-start',
        phase: 'B12',
        workflowId: 'workflow-ui-evidence-harness',
      );
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
      await capture('B12_harness_start');
      await tester.tap(find.byKey(const ValueKey('add-community-button')));
      await tester.pumpAndSettle();
      await capture('B12_harness_action');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await capture('B12_harness_complete');
      entries.add({
        ...harnessEntry,
        'screenshotNames': [
          'B12_harness_start',
          'B12_harness_action',
          'B12_harness_complete',
        ],
        'status': 'pass',
      });
      emitProgress(
        'workflow-complete',
        phase: 'B12',
        workflowId: 'workflow-ui-evidence-harness',
      );
    }

    var targetWorkflowOrdinal = 0;
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
      final completedSetupWorkflowIds = <String>{};

      Future<void> ensurePrerequisiteChain(
        LoomWorkflowDefinition workflow,
      ) async {
        final policy = personaPolicyForWorkflow(
          target.extensionId,
          workflow.workflowId,
        );
        final prerequisiteWorkflowId = policy.prerequisiteWorkflowId;
        if (prerequisiteWorkflowId == null ||
            completedSetupWorkflowIds.contains(prerequisiteWorkflowId)) {
          return;
        }
        final prerequisite = experience.workflows.firstWhere(
          (candidate) => candidate.workflowId == prerequisiteWorkflowId,
        );
        await ensurePrerequisiteChain(prerequisite);
        final prerequisitePolicy = personaPolicyForWorkflow(
          target.extensionId,
          prerequisite.workflowId,
        );
        final prerequisitePersonaId = prerequisitePolicy.actorPersonaIds.first;
        await selectPersona(tester, prerequisitePersonaId);
        await completeWorkflow(tester, prerequisite);
        completedSetupWorkflowIds.add(prerequisiteWorkflowId);
      }

      for (final workflow in experience.workflows) {
        final workflowOrdinal = targetWorkflowOrdinal;
        targetWorkflowOrdinal += 1;
        if (!_includeWorkflowShard(workflowOrdinal)) {
          continue;
        }
        emitProgress(
          'workflow-start',
          phase: target.phase,
          workflowId: workflow.workflowId,
          communityName: target.communityName,
        );
        final policy = personaPolicyForWorkflow(
          target.extensionId,
          workflow.workflowId,
        );
        await ensurePrerequisiteChain(workflow);
        final actorPersonaId = policy.actorPersonaIds.first;
        await selectPersona(tester, actorPersonaId);
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
        await capture(start);

        final workflowButton = find.byKey(
          ValueKey('workflow-button-${workflow.workflowId}'),
        );
        await tester.ensureVisible(workflowButton);
        await tester.pumpAndSettle();
        await tester.tap(workflowButton);
        await tester.pumpAndSettle();
        expect(
          find.byKey(
            ValueKey('workflow-action-surface-${workflow.workflowId}'),
          ),
          findsOneWidget,
        );
        await capture(action);

        final submitButton = find.byKey(
          ValueKey('workflow-action-submit-${workflow.workflowId}'),
        );
        await tester.scrollUntilVisible(
          submitButton,
          180,
          scrollable: verticalScrollableFinder().last,
          maxScrolls: 30,
        );
        await tester.pumpAndSettle();
        await tester.tap(submitButton);
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
        await capture(complete);

        entries.add({
          ...entry,
          'screenshotNames': [start, action, complete],
          'status': 'pass',
        });
        completedSetupWorkflowIds.add(workflow.workflowId);
        emitProgress(
          'workflow-complete',
          phase: target.phase,
          workflowId: workflow.workflowId,
          communityName: target.communityName,
        );
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
    final gardenTarget = loomEvidenceTargets.firstWhere(
      (target) => target.extensionId == 'ext_garden_club',
    );
    final gardenExperience = experienceForExtensionId(
      gardenTarget.extensionId,
      displayName: gardenTarget.communityName,
    );
    final gardenRsvp = gardenExperience.workflows.firstWhere(
      (workflow) => workflow.workflowId == 'garden-event-rsvp',
    );
    final hoaTarget = loomEvidenceTargets.firstWhere(
      (target) => target.extensionId == 'ext_hoa',
    );
    final soccerTarget = loomEvidenceTargets.firstWhere(
      (target) => target.extensionId == 'ext_youth_soccer',
    );
    final soccerExperience = experienceForExtensionId(
      soccerTarget.extensionId,
      displayName: soccerTarget.communityName,
    );
    final soccerRoster = soccerExperience.workflows.firstWhere(
      (workflow) => workflow.workflowId == 'soccer-team-roster',
    );

    if (_includePhase('B17')) {
      emitProgress(
        'workflow-start',
        phase: 'B17',
        workflowId: 'wf_persona-role-inventory-capability-matrix',
        communityName: mosqueTarget.communityName,
      );
      await ensureTargetOpen(mosqueTarget);
      await capture('B17_persona_inventory_active_admin');
      await tester.tap(find.byKey(const ValueKey('persona-picker-button')));
      await tester.pumpAndSettle();
      await capture('B17_persona_inventory_picker');
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
      emitProgress(
        'workflow-complete',
        phase: 'B17',
        workflowId: 'wf_persona-role-inventory-capability-matrix',
        communityName: mosqueTarget.communityName,
      );
    }

    if (_includePhase('B18')) {
      emitProgress(
        'workflow-start',
        phase: 'B18',
        workflowId: 'wf_demo-app-persona-picker',
        communityName: mosqueTarget.communityName,
      );
      await ensureTargetOpen(mosqueTarget);
      await tester.tap(find.byKey(const ValueKey('persona-picker-button')));
      await tester.pumpAndSettle();
      await capture('B18_persona_picker_dialog');
      await tester.tap(
        find.byKey(const ValueKey('persona-option-mosque-member')),
      );
      await tester.pumpAndSettle();
      await _scrollToWorkflow(tester, announcement);
      await capture('B18_persona_picker_member_selected');
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
      emitProgress(
        'workflow-complete',
        phase: 'B18',
        workflowId: 'wf_demo-app-persona-picker',
        communityName: mosqueTarget.communityName,
      );
    }

    if (_includePhase('B19')) {
      emitProgress(
        'workflow-start',
        phase: 'B19',
        workflowId: 'wf_community-persona-aware-ux',
        communityName: mosqueTarget.communityName,
      );
      await ensureTargetOpen(mosqueTarget);
      await selectPersona(tester, 'mosque-member');
      await _scrollToWorkflow(tester, careRequest);
      await capture('B19_member_care_request_actor');
      await selectPersona(tester, 'mosque-admin');
      await _scrollToWorkflow(tester, announcement);
      await capture('B19_admin_announcement_actor');
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
      emitProgress(
        'workflow-complete',
        phase: 'B19',
        workflowId: 'wf_community-persona-aware-ux',
        communityName: mosqueTarget.communityName,
      );
    }

    if (_includePhase('B20')) {
      emitProgress(
        'workflow-start',
        phase: 'B20',
        workflowId: 'wf_multi-persona-workflow-evidence',
        communityName: mosqueTarget.communityName,
      );
      await ensureTargetOpen(mosqueTarget);
      await selectPersona(tester, 'mosque-admin');
      await _scrollToWorkflow(tester, announcement);
      await capture('B20_announcement_admin_start');
      final announcementActionButton = find.byKey(
        ValueKey('workflow-button-${announcement.workflowId}'),
      );
      await tester.scrollUntilVisible(
        announcementActionButton,
        180,
        scrollable: verticalScrollableFinder().last,
        maxScrolls: 30,
      );
      await tester.pumpAndSettle();
      await tester.tap(announcementActionButton, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          ValueKey('workflow-action-surface-${announcement.workflowId}'),
        ),
        findsOneWidget,
      );
      await capture('B20_announcement_admin_action');
      final announcementSubmitButton = find.byKey(
        ValueKey('workflow-action-submit-${announcement.workflowId}'),
      );
      await tester.scrollUntilVisible(
        announcementSubmitButton,
        180,
        scrollable: verticalScrollableFinder().last,
        maxScrolls: 30,
      );
      await tester.pumpAndSettle();
      await tester.tap(announcementSubmitButton);
      await tester.pumpAndSettle();
      await _scrollToWorkflow(tester, announcement);
      await capture('B20_announcement_admin_complete');
      await selectPersona(tester, 'mosque-member');
      await _scrollToWorkflow(tester, announcement);
      await capture('B20_announcement_member_ready');
      final announcementReceiveButton = find.byKey(
        ValueKey('workflow-receive-button-${announcement.workflowId}'),
      );
      await tester.scrollUntilVisible(
        announcementReceiveButton,
        180,
        scrollable: verticalScrollableFinder().last,
        maxScrolls: 30,
      );
      await tester.pumpAndSettle();
      await tester.tap(announcementReceiveButton, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          ValueKey('workflow-receive-surface-${announcement.workflowId}'),
        ),
        findsOneWidget,
      );
      await capture('B20_announcement_member_action');
      final announcementReceiveSubmitButton = find.byKey(
        ValueKey('workflow-receive-submit-${announcement.workflowId}'),
      );
      await tester.scrollUntilVisible(
        announcementReceiveSubmitButton,
        180,
        scrollable: verticalScrollableFinder().last,
        maxScrolls: 30,
      );
      await tester.pumpAndSettle();
      await tester.tap(announcementReceiveSubmitButton);
      await tester.pumpAndSettle();
      await _scrollToWorkflow(tester, announcement);
      await capture('B20_announcement_member_received');
      await _selectCommunityTab(tester, 'calendar');
      await capture('B20_member_calendar_tab_pinned_event');
      await _selectCommunityTab(tester, 'messages');
      await capture('B20_member_messages_tab');
      await selectPersona(tester, 'mosque-admin');
      await _selectCommunityTab(tester, 'admin');
      await capture('B20_admin_custom_tab_pinned_surface');
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
          'B20_member_calendar_tab_pinned_event',
          'B20_member_messages_tab',
          'B20_admin_custom_tab_pinned_surface',
        ],
        'status': 'pass',
      });
      emitProgress(
        'workflow-complete',
        phase: 'B20',
        workflowId: 'wf_multi-persona-workflow-evidence',
        communityName: mosqueTarget.communityName,
      );

      emitProgress(
        'workflow-start',
        phase: 'B20',
        workflowId: 'wf_app-shell-capability-evidence',
        communityName: 'Loom Communities',
      );
      final capabilityScreenshots = <String>[];

      await returnToCommunityList();
      await capture('B20_app_shell_main_community_list_states');
      capabilityScreenshots.add('B20_app_shell_main_community_list_states');

      await ensureTargetOpen(gardenTarget);
      await selectPersona(tester, 'garden-member');
      await _selectCommunityTab(tester, 'home');
      await _scrollToWorkflow(tester, gardenRsvp);
      await capture('B20_app_shell_garden_home_medium_minimized_stack');
      capabilityScreenshots.add(
        'B20_app_shell_garden_home_medium_minimized_stack',
      );
      final gardenExpandButton = find.byKey(
        ValueKey('workflow-expand-${gardenRsvp.workflowId}'),
      );
      await tester.ensureVisible(gardenExpandButton);
      await tester.pumpAndSettle();
      await tester.tap(gardenExpandButton, warnIfMissed: false);
      await tester.pumpAndSettle();
      await capture('B20_app_shell_garden_home_expanded_surface');
      capabilityScreenshots.add('B20_app_shell_garden_home_expanded_surface');

      await ensureTargetOpen(hoaTarget);
      await selectPersona(tester, 'hoa-homeowner');
      await _selectCommunityTab(tester, 'documents');
      await capture('B20_app_shell_hoa_documents_pinning_policy');
      capabilityScreenshots.add('B20_app_shell_hoa_documents_pinning_policy');

      await ensureTargetOpen(soccerTarget);
      await selectPersona(tester, 'soccer-coach');
      await _selectCommunityTab(tester, 'home');
      await _scrollToWorkflow(tester, soccerRoster);
      await capture('B20_app_shell_soccer_roster_renderer_medium');
      capabilityScreenshots.add('B20_app_shell_soccer_roster_renderer_medium');
      final soccerExpandButton = find.byKey(
        ValueKey('workflow-expand-${soccerRoster.workflowId}'),
      );
      await tester.ensureVisible(soccerExpandButton);
      await tester.pumpAndSettle();
      await tester.tap(soccerExpandButton, warnIfMissed: false);
      await tester.pumpAndSettle();
      await capture('B20_app_shell_soccer_roster_renderer_expanded');
      capabilityScreenshots.add(
        'B20_app_shell_soccer_roster_renderer_expanded',
      );

      entries.add({
        'phase': 'B20',
        'appId': 'app-shell-capability-evidence',
        'workflowId': 'wf_app-shell-capability-evidence',
        'communityId': 'loom-communities',
        'communityName': 'Loom Communities',
        'expectedAssertions': [
          'main community list shows themed launch cards with medium and minimized states',
          'Garden Club Home tab proves medium/minimized workflow surfaces and tap-to-expanded behavior',
          'HOA Documents tab proves an explicit pin-first-critical-surface policy with a pinned document/status surface',
          'Riverside Youth Soccer roster proves renderer selection by card-surface family in medium and expanded states',
        ],
        'screenshotNames': capabilityScreenshots,
        'status': 'pass',
      });
      emitProgress(
        'workflow-complete',
        phase: 'B20',
        workflowId: 'wf_app-shell-capability-evidence',
        communityName: 'Loom Communities',
      );
    }

    if (find
        .byKey(ValueKey('local-extension-${mosqueTarget.extensionId}'))
        .evaluate()
        .isNotEmpty) {
      await tester.pageBack();
      await tester.pumpAndSettle();
    }

    binding.reportData!['workflowEvidenceSchemaVersion'] = 1;
    binding.reportData!['emulatorName'] = 'emulator-5554';
    binding.reportData!['deviceClass'] = 'Android emulator';
    binding.reportData!['workflowEvidence'] = entries;
    binding.reportData!['screenshotVisibleTextByName'] =
        screenshotVisibleTextByName;
    _emitCaptureProgress({
      'status': 'run-complete',
      'completedWorkflows': completedWorkflowEvidenceEntries,
      'totalWorkflows': totalWorkflowEvidenceEntries,
    });
  });
}

Future<void> _capture(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  Map<String, String> screenshotVisibleTextByName,
  String name,
) async {
  await tester.pump();
  screenshotVisibleTextByName[name] = _visibleTextFor(tester);
  await binding.takeScreenshot(name);
}

String _visibleTextFor(WidgetTester tester) {
  final seen = <String>{};
  final chunks = <String>[];
  for (final element in find.byType(Text).evaluate()) {
    final widget = element.widget as Text;
    final raw = widget.data ?? widget.textSpan?.toPlainText() ?? '';
    final clean = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty || !seen.add(clean)) {
      continue;
    }
    chunks.add(clean);
    if (chunks.length >= 80) {
      break;
    }
  }
  return chunks.join(' | ');
}

void _emitCaptureProgress(Map<String, Object?> event) {
  debugPrint(
    'B25_CAPTURE_PROGRESS ${jsonEncode({'emittedAt': DateTime.now().toUtc().toIso8601String(), ...event})}',
    wrapWidth: 2048,
  );
}

String _phaseForScreenshotName(String name) {
  final separator = name.indexOf('_');
  return separator == -1 ? 'unknown' : name.substring(0, separator);
}

int _workflowEvidenceEntryCount() {
  var total = 0;
  if (_includePhase('B12')) {
    total += 1;
  }
  var targetWorkflowOrdinal = 0;
  for (final target in loomEvidenceTargets.where(
    (target) => _includePhase(target.phase),
  )) {
    for (final _ in experienceForExtensionId(
      target.extensionId,
      displayName: target.communityName,
    ).workflows) {
      final workflowOrdinal = targetWorkflowOrdinal;
      targetWorkflowOrdinal += 1;
      if (_includeWorkflowShard(workflowOrdinal)) {
        total += 1;
      }
    }
  }
  if (_includePhase('B17')) {
    total += 1;
  }
  if (_includePhase('B18')) {
    total += 1;
  }
  if (_includePhase('B19')) {
    total += 1;
  }
  if (_includePhase('B20')) {
    total += 2;
  }
  return total;
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

bool _includeWorkflowShard(int workflowOrdinal) {
  if (_workflowShardCount <= 1) {
    return true;
  }
  if (_workflowShardIndex < 0 || _workflowShardIndex >= _workflowShardCount) {
    return true;
  }
  return workflowOrdinal % _workflowShardCount == _workflowShardIndex;
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
  final scrollable = verticalScrollableFinder().last;
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

Future<void> _selectCommunityTab(WidgetTester tester, String tabId) async {
  final tab = find.byKey(ValueKey('community-tab-$tabId'));
  await tester.scrollUntilVisible(
    tab,
    120,
    scrollable: find.descendant(
      of: find.byKey(const ValueKey('community-bottom-tabs')),
      matching: find.byType(Scrollable),
    ),
    maxScrolls: 16,
  );
  await tester.pumpAndSettle();
  await tester.tap(tab, warnIfMissed: false);
  await tester.pumpAndSettle();
}

int _personaMatrixRowCount() {
  return loomEvidenceTargets
      .map(
        (target) =>
            personaWorkflowMatrixForExtensionId(target.extensionId).length,
      )
      .fold(0, (total, count) => total + count);
}
