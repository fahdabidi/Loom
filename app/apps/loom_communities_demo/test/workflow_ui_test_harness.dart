import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show currentCommunitySpecVersion;

const _shippedCommunityPackagePathsByExtensionId = <String, String>{
  'ext_garden_club':
      'docs/references/communities/'
      'Loom_Communities_Workflow_Engine_GardenClub_Example.jsonc',
  'ext_camera_club':
      'docs/references/communities/'
      'Loom_Communities_Workflow_Engine_CameraClub_Example.jsonc',
  'ext_neighborhood_book_club':
      'docs/references/communities/'
      'Loom_Communities_Workflow_Engine_NeighborhoodBookClub_Example.jsonc',
  'ext_chess_club':
      'docs/references/communities/'
      'Loom_Communities_Workflow_Engine_ChessClub_Example.jsonc',
  'ext_youth_soccer':
      'docs/references/communities/'
      'Loom_Communities_Workflow_Engine_RiversideYouthSoccer_Example.jsonc',
  'ext_mosque':
      'docs/references/communities/'
      'Loom_Communities_Workflow_Engine_MasjidNur_Example.jsonc',
};

File _repositoryFile(String relativePath) {
  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    final file = File('${directory.path}/$relativePath');
    if (file.existsSync()) return file;
    final parent = directory.parent;
    if (parent.path == directory.path) break;
    directory = parent;
  }
  throw StateError('Fixture not found: $relativePath');
}

Future<void> installEvidenceTarget(
  WidgetTester tester,
  LoomEvidenceTarget target, {
  ValueKey<String> openButtonKey = const ValueKey('add-community-button'),
  bool useShippedPackage = false,
}) async {
  final fixture = useShippedPackage
      ? writeEvidencePackagePair(target)
      : _writeMetadataEvidencePackagePair(target);
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
  // Engine-native shipped packages first render their membership gate inside
  // the target LocalExtensionScreen. The route proves the card tap worked even
  // though the signed-in content marker is not available until entry succeeds.
  final targetRoute = _evidenceTargetRoute(target);
  final identity = find.byKey(
    ValueKey('community-card-identity-${target.communityId}'),
  );
  for (final tapTarget in [identity, card]) {
    if (tapTarget.evaluate().isEmpty) {
      continue;
    }
    await tester.tap(tapTarget, warnIfMissed: false);
    await tester.pumpAndSettle();
    if (detail.evaluate().isNotEmpty || targetRoute.evaluate().isNotEmpty) {
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
  if (detail.evaluate().isEmpty && targetRoute.evaluate().isEmpty) {
    fail(
      'Tapped evidence target ${target.communityName} '
      '(${target.communityId}) but ${target.extensionId} did not open. '
      '${_visibleScreenDescription()}',
    );
  }
}

Finder _evidenceTargetRoute(LoomEvidenceTarget target) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is LocalExtensionScreen &&
        widget.community.communityId == target.communityId &&
        widget.community.extensionId == target.extensionId,
    description:
        'LocalExtensionScreen for ${target.communityId} '
        '(${target.extensionId})',
  );
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
      await tester.pumpAndSettle();
      continue;
    }

    final entryGate = find.byKey(const ValueKey('community-entry-gate'));
    final entryChecking = find.byKey(
      const ValueKey('community-entry-checking'),
    );
    final entrySurface = entryGate.evaluate().isNotEmpty
        ? entryGate
        : entryChecking;
    if (entrySurface.evaluate().isNotEmpty) {
      // The engine-native entry Scaffold intentionally has no AppBar. Pop its
      // known community route directly instead of asking pageBack() to find a
      // back-button widget that cannot exist on this screen.
      final didPop = await Navigator.of(
        tester.element(entrySurface.first),
      ).maybePop();
      if (!didPop) {
        fail(
          'Could not return to the community list from the engine-native '
          'community entry route because its Navigator could not pop. '
          '${_visibleScreenDescription()}',
        );
      }
      await tester.pumpAndSettle();
      continue;
    }

    fail(
      'Could not return to the community list: the list was not ready and '
      'the current screen had neither a Back tooltip nor a known '
      'engine-native entry route to pop. ${_visibleScreenDescription()}',
    );
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
      'scrollables=${find.byType(Scrollable).evaluate().length}. '
      '${_visibleScreenDescription()}',
    );
  }
}

Future<void> selectPersona(WidgetTester tester, String personaId) async {
  await _waitForCommunityEntryResolution(tester);
  // Shipped engine-native packages bind role policy to an active account, so
  // enter through the real account form. Metadata fixtures remain on the
  // legacy role-picker path below because they do not render this gate.
  if (find
      .byKey(const ValueKey('community-entry-gate'))
      .evaluate()
      .isNotEmpty) {
    await _createEvidenceAccount(tester, personaId);
    await _waitForEvidenceFinder(
      tester,
      find.byKey(const ValueKey('persona-picker-button')),
      description: 'community content after signing up as $personaId',
    );
    return;
  }

  final pickerButton = find.byKey(const ValueKey('persona-picker-button'));
  await _waitForEvidenceFinder(
    tester,
    pickerButton,
    description: 'persona picker while selecting $personaId',
  );
  await tester.tap(pickerButton);
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('persona-picker-dialog')), findsOneWidget);

  final personaOption = find.byKey(ValueKey('persona-option-$personaId'));
  if (personaOption.evaluate().isEmpty) {
    fail(
      'Persona $personaId was not available in the persona picker. '
      '${_visibleScreenDescription()}',
    );
  }
  final selectedPersona = tester.widget<ListTile>(personaOption).selected;
  final signedInAccount = find.textContaining('Signed in as ');
  if (signedInAccount.evaluate().isEmpty || selectedPersona) {
    await tester.tap(personaOption);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('persona-picker-dialog')), findsNothing);
    return;
  }

  final specificPerson = find.byKey(
    const ValueKey('persona-sign-in-specific-person'),
  );
  await tester.ensureVisible(specificPerson);
  await tester.tap(specificPerson);
  await tester.pumpAndSettle();
  await _waitForEvidenceFinder(
    tester,
    find.byKey(const ValueKey('open-signup-display-name')),
    description: 'account chooser while selecting $personaId',
  );

  final accountName = _evidenceAccountName(personaId);
  final existingAccount = find.ancestor(
    of: find.text(accountName),
    matching: find.byType(ListTile),
  );
  if (existingAccount.evaluate().isNotEmpty) {
    await tester.ensureVisible(existingAccount.first);
    await tester.tap(existingAccount.first, warnIfMissed: false);
  } else {
    await _createEvidenceAccount(tester, personaId);
  }
  await _waitForEvidenceFinder(
    tester,
    pickerButton,
    description: 'community content after signing in as $personaId',
  );
}

Future<void> _waitForCommunityEntryResolution(WidgetTester tester) async {
  for (var attempt = 0; attempt < 80; attempt += 1) {
    if (find
        .byKey(const ValueKey('community-entry-checking'))
        .evaluate()
        .isEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
  fail(
    'Community entry did not finish checking membership. '
    '${_visibleScreenDescription()}',
  );
}

Future<void> _createEvidenceAccount(
  WidgetTester tester,
  String personaId,
) async {
  final displayName = find.byKey(const ValueKey('open-signup-display-name'));
  final personaDropdown = find.byKey(
    const ValueKey('open-signup-persona-dropdown'),
  );
  final submit = find.byKey(const ValueKey('open-signup-submit'));
  for (final finder in [displayName, personaDropdown, submit]) {
    if (finder.evaluate().isEmpty) {
      fail(
        'The community entry account form was incomplete while selecting '
        '$personaId. ${_visibleScreenDescription()}',
      );
    }
  }

  await tester.ensureVisible(personaDropdown);
  await tester.tap(personaDropdown);
  await tester.pumpAndSettle();
  final personaChoice = find.byKey(ValueKey('open-signup-persona-$personaId'));
  if (personaChoice.evaluate().isEmpty) {
    fail(
      'Persona $personaId was not offered by the community entry account '
      'form. ${_visibleScreenDescription()}',
    );
  }
  // DropdownMenuItem renders the selected value in the button and another
  // copy in the open modal route. The overlay copy is last in paint order;
  // target it explicitly so selecting the initial persona is unambiguous.
  await tester.tap(personaChoice.last, warnIfMissed: false);
  await tester.pumpAndSettle();

  await tester.ensureVisible(displayName);
  await tester.enterText(displayName, _evidenceAccountName(personaId));
  await tester.ensureVisible(submit);
  await tester.tap(submit, warnIfMissed: false);
  await tester.pump();
}

String _evidenceAccountName(String personaId) => 'Evidence $personaId';

Future<void> _waitForEvidenceFinder(
  WidgetTester tester,
  Finder finder, {
  required String description,
}) async {
  for (var attempt = 0; attempt < 80; attempt += 1) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
  fail('Timed out waiting for $description. ${_visibleScreenDescription()}');
}

String _visibleScreenDescription() {
  final markers = <String>[];
  void addMarker(String label, Finder finder) {
    final count = finder.evaluate().length;
    if (count > 0) markers.add('$label=$count');
  }

  addMarker(
    'communityEntryGate',
    find.byKey(const ValueKey('community-entry-gate')),
  );
  addMarker(
    'communityEntryChecking',
    find.byKey(const ValueKey('community-entry-checking')),
  );
  addMarker(
    'localPackageLoader',
    find.byKey(const ValueKey('load-local-community-button')),
  );
  addMarker(
    'personaPicker',
    find.byKey(const ValueKey('persona-picker-dialog')),
  );
  addMarker('localExtensionScreen', find.byType(LocalExtensionScreen));
  addMarker('alertDialog', find.byType(AlertDialog));
  addMarker('scaffold', find.byType(Scaffold));
  addMarker('scrollable', find.byType(Scrollable));

  final extensionIds = find
      .byType(LocalExtensionScreen)
      .evaluate()
      .map(
        (element) =>
            (element.widget as LocalExtensionScreen).community.extensionId,
      )
      .toSet()
      .toList(growable: false);
  final visibleTexts = <String>{};
  for (final element in find.byType(Text).evaluate()) {
    final widget = element.widget as Text;
    final value = (widget.data ?? widget.textSpan?.toPlainText())?.trim();
    if (value == null || value.isEmpty) continue;
    visibleTexts.add(
      value.length <= 100 ? value : '${value.substring(0, 97)}...',
    );
    if (visibleTexts.length == 16) break;
  }
  return 'Visible screen: markers=[${markers.join(', ')}], '
      'extensionIds=$extensionIds, texts=${visibleTexts.toList()}';
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
  final packagePath =
      _shippedCommunityPackagePathsByExtensionId[target.extensionId];
  if (packagePath == null) {
    throw StateError(
      'No shipped community package is registered for '
      '${target.extensionId}.',
    );
  }
  final decoded = jsonDecode(
    stripJsonComments(_repositoryFile(packagePath).readAsStringSync()),
  );
  if (decoded is! Map<String, dynamic>) {
    throw StateError('Shipped community package must contain a JSON object.');
  }
  final packageExtensionId = decoded['extensionId'];
  if (packageExtensionId != target.extensionId) {
    throw StateError(
      'Shipped community package extensionId $packageExtensionId does not '
      'match evidence target ${target.extensionId}.',
    );
  }
  final experience = decoded['experience'];
  final appShell = decoded['appShell'];
  if (experience is! Map<String, dynamic> ||
      appShell is! Map<String, dynamic>) {
    throw StateError(
      'Shipped community package ${target.extensionId} must declare both '
      'experience and appShell.',
    );
  }
  final workflowDefinitions = experience['workflowDefinitions'];
  if (workflowDefinitions is! Map<String, dynamic>) {
    throw StateError(
      'Shipped community package ${target.extensionId} must declare '
      'experience.workflowDefinitions.',
    );
  }

  final tempDir = Directory.systemTemp.createTempSync(
    'loom_${target.extensionId}_',
  );
  final extensionFile = File(
    '${tempDir.path}/${target.handle}.loom-extension.zip',
  );
  final initializationFile = File(
    '${tempDir.path}/${target.handle}.loom-init.zip',
  );
  final initialization = Map<String, dynamic>.from(decoded)
    // Keep the package's genuine experience and appShell while hydrating the
    // demo catalog entry. The shipped soccer corpus uses a different
    // communityId; its existing package generator performs the same
    // normalization for local sideloads.
    ..['communityId'] = target.communityId;
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
      'workflows': workflowDefinitions.keys.toList(growable: false),
    }),
  );
  initializationFile.writeAsStringSync(jsonEncode(initialization));
  return EvidencePackagePair(
    extensionPath: extensionFile.path,
    initializationPath: initializationFile.path,
  );
}

EvidencePackagePair _writeMetadataEvidencePackagePair(
  LoomEvidenceTarget target,
) {
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
      'workflows': <String>[],
    }),
  );
  initializationFile.writeAsStringSync(
    jsonEncode({
      'specVersion': currentCommunitySpecVersion,
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
