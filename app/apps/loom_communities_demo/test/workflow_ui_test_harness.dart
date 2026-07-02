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
  await _returnToCommunityList(tester);
  _expectCommunityListReady(tester);
  final card = find.byKey(ValueKey('community-card-${target.communityId}'));
  await _scrollToCardIfNeeded(tester, card);
  if (card.evaluate().isEmpty) {
    fail(
      'Could not find evidence target ${target.communityName} '
      '(${target.communityId}) from the community list.',
    );
  }
  await _centerCardInList(tester, card);
  final detail = find.byKey(ValueKey('local-extension-${target.extensionId}'));
  final identity = find.byKey(
    ValueKey('community-card-identity-${target.communityId}'),
  );
  for (final tapTarget in [identity, card]) {
    if (tapTarget.evaluate().isEmpty) {
      continue;
    }
    await tester.tap(tapTarget, warnIfMissed: false);
    await tester.pumpAndSettle();
    if (detail.evaluate().isNotEmpty) {
      return;
    }
    await _returnToCommunityList(tester);
    _expectCommunityListReady(tester);
    await _scrollToCardIfNeeded(tester, card);
    await _centerCardInList(tester, card);
  }
  final cardRect = tester.getRect(card);
  await tester.tapAt(cardRect.center);
  await tester.pumpAndSettle();
  if (detail.evaluate().isEmpty) {
    fail(
      'Tapped evidence target ${target.communityName} '
      '(${target.communityId}) but ${target.extensionId} did not open.',
    );
  }
}

Future<void> _returnToCommunityList(WidgetTester tester) async {
  for (var attempt = 0; attempt < 8; attempt += 1) {
    await tester.pumpAndSettle();
    if (_communityListIsReady()) {
      return;
    }
    final backButton = find.byTooltip('Back');
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton.first, warnIfMissed: false);
    } else {
      await tester.pageBack();
    }
    await tester.pumpAndSettle();
  }
  _expectCommunityListReady(tester);
}

bool _communityListIsReady() {
  return find
          .byKey(const ValueKey('add-community-button'))
          .evaluate()
          .isNotEmpty &&
      find.byKey(const ValueKey('community-list')).evaluate().isNotEmpty &&
      find.byType(Scrollable).evaluate().isNotEmpty;
}

Finder _communityListScrollable() {
  return find.byType(Scrollable).last;
}

Future<void> _scrollToCardIfNeeded(WidgetTester tester, Finder card) async {
  if (card.evaluate().isNotEmpty) {
    return;
  }
  if (find.byType(Scrollable).evaluate().isEmpty) {
    fail(
      'Community list scrollable was not available while opening a '
      'community card.',
    );
  }
  final scrollable = _communityListScrollable();
  for (final offset in const [Offset(0, 260), Offset(0, -260)]) {
    for (var attempt = 0; attempt < 40; attempt += 1) {
      await tester.drag(scrollable, offset, warnIfMissed: false);
      await tester.pumpAndSettle();
      if (card.evaluate().isNotEmpty) {
        return;
      }
    }
  }
}

Future<void> _centerCardInList(WidgetTester tester, Finder card) async {
  if (card.evaluate().isEmpty) {
    return;
  }
  await Scrollable.ensureVisible(
    tester.element(card),
    alignment: 0.35,
    duration: Duration.zero,
  );
  await tester.pumpAndSettle();
}

void _expectCommunityListReady(WidgetTester tester) {
  if (!_communityListIsReady()) {
    fail(
      'Community list was not ready. '
      'addButton=${find.byKey(const ValueKey('add-community-button')).evaluate().length}, '
      'communityList=${find.byKey(const ValueKey('community-list')).evaluate().length}, '
      'scrollables=${find.byType(Scrollable).evaluate().length}',
    );
  }
}

Future<void> selectPersona(WidgetTester tester, String personaId) async {
  await tester.tap(find.byKey(const ValueKey('persona-picker-button')));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('persona-picker-dialog')), findsOneWidget);
  await tester.tap(find.byKey(ValueKey('persona-option-$personaId')));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('persona-picker-dialog')), findsNothing);
}

Future<void> selectWorkflowTab(
  WidgetTester tester, {
  required LoomExperienceDefinition experience,
  required String personaId,
  required LoomWorkflowDefinition workflow,
}) async {
  final tabs = appShellTabsFor(experience: experience, personaId: personaId);
  final targetTab = tabs.firstWhere(
    (tab) =>
        tab.tabId != 'home' &&
        tab.matchesWorkflow(
          extensionId: experience.extensionId,
          workflow: workflow,
        ),
    orElse: () =>
        tabs.firstWhere((tab) => tab.tabId == 'home', orElse: () => tabs.first),
  );
  final tabFinder = find.byKey(ValueKey('community-tab-${targetTab.tabId}'));
  final tabRail = find.byKey(const ValueKey('community-bottom-tabs'));
  for (
    var attempt = 0;
    attempt < 8 && tabFinder.evaluate().isEmpty;
    attempt += 1
  ) {
    await tester.drag(tabRail, const Offset(-220, 0), warnIfMissed: false);
    await tester.pumpAndSettle();
  }
  if (tabFinder.evaluate().isEmpty) {
    return;
  }
  await tester.tap(tabFinder, warnIfMissed: false);
  await tester.pumpAndSettle();
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

  final scrollable = verticalScrollableFinder();
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

  final homeTab = find.byKey(const ValueKey('community-tab-home'));
  if (homeTab.evaluate().isNotEmpty) {
    await tester.ensureVisible(homeTab);
    await tester.pumpAndSettle();
    await tester.tap(homeTab);
    await tester.pumpAndSettle();
    if (workflowCard.evaluate().isNotEmpty) {
      await tester.ensureVisible(workflowCard);
      await tester.pumpAndSettle();
      return;
    }
  }

  fail('Could not find workflow card ${workflow.workflowId}');
}

Finder verticalScrollableFinder() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable &&
        (widget.axisDirection == AxisDirection.down ||
            widget.axisDirection == AxisDirection.up),
    description: 'vertical Scrollable',
  );
}

Future<void> completeWorkflow(
  WidgetTester tester,
  LoomWorkflowDefinition workflow,
) async {
  await scrollToWorkflowCard(tester, workflow);
  final workflowButton = find.byKey(
    ValueKey('workflow-button-${workflow.workflowId}'),
  );
  await scrollFinderIntoViewport(tester, workflowButton);
  await tester.pumpAndSettle();
  await tester.tap(workflowButton);
  await tester.pumpAndSettle();
  expect(
    find.byKey(ValueKey('workflow-action-surface-${workflow.workflowId}')),
    findsOneWidget,
  );
  final submitButton = find.byKey(
    ValueKey('workflow-action-submit-${workflow.workflowId}'),
  );
  await scrollFinderIntoViewport(tester, submitButton);
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
}

Future<void> scrollFinderIntoViewport(
  WidgetTester tester,
  Finder finder,
) async {
  final scrollable = verticalScrollableFinder().last;
  await tester.scrollUntilVisible(
    finder,
    180,
    scrollable: scrollable,
    maxScrolls: 30,
  );
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(
    tester.element(finder),
    alignment: 0.35,
    duration: Duration.zero,
  );
  await tester.pumpAndSettle();

  for (var attempt = 0; attempt < 16; attempt += 1) {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        180,
        scrollable: scrollable,
        maxScrolls: 30,
      );
      await tester.pumpAndSettle();
    }
    await Scrollable.ensureVisible(
      tester.element(finder),
      alignment: 0.35,
      duration: Duration.zero,
    );
    await tester.pumpAndSettle();
    final rect = tester.getRect(finder);
    final viewportHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    const safeTop = 112.0;
    final safeBottom = viewportHeight - 96.0;
    if (rect.top >= safeTop && rect.bottom <= safeBottom) {
      return;
    }
    final dragOffset = rect.top < safeTop
        ? const Offset(0, 220)
        : const Offset(0, -220);
    await tester.drag(scrollable, dragOffset, warnIfMissed: false);
    await tester.pumpAndSettle();
  }
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
  final receiveButton = find.byKey(
    ValueKey('workflow-receive-button-${workflow.workflowId}'),
  );
  await scrollFinderIntoViewport(tester, receiveButton);
  await tester.tap(receiveButton);
  await tester.pumpAndSettle();
  expect(
    find.byKey(ValueKey('workflow-receive-surface-${workflow.workflowId}')),
    findsOneWidget,
  );
  final receiveSubmitButton = find.byKey(
    ValueKey('workflow-receive-submit-${workflow.workflowId}'),
  );
  await scrollFinderIntoViewport(tester, receiveSubmitButton);
  await tester.tap(receiveSubmitButton);
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
