import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';

import 'package:loom_workflow_engine/loom_workflow_engine.dart';

import 'authz_p6_test_helpers.dart';

const _fixtureRelative =
    'docs/references/communities/Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc';

File _fixtureFile() {
  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidate = File('${directory.path}/$_fixtureRelative');
    if (candidate.existsSync()) return candidate;
    directory = directory.parent;
  }
  throw StateError('Could not find frozen Tabletop fixture');
}

class _InstalledTabletop {
  const _InstalledTabletop(this.community, this.engine, this.temp);

  final LocalInstalledCommunity community;
  final WorkflowEngineApi engine;
  final Directory temp;

  Future<void> dispose() => temp.delete(recursive: true);
}

Future<_InstalledTabletop> _install(String extensionId) async {
  final source =
      jsonDecode(stripJsonComments(_fixtureFile().readAsStringSync()))
          as Map<String, dynamic>;
  source['extensionId'] = extensionId;
  final temp = await Directory.systemTemp.createTemp(
    'loom-phasee-$extensionId-',
  );
  try {
    final init = File('${temp.path}/tabletop.loom-init.zip');
    final extension = File('${temp.path}/tabletop.loom-extension.zip');
    await init.writeAsString(jsonEncode(source));
    await extension.writeAsString(
      jsonEncode(<String, Object?>{
        'specVersion': currentCommunitySpecVersion,
        'extensionId': extensionId,
        'displayName': source['displayName'],
        'version': '1.0.0',
        'mode': 'local-demo',
        'permissions': <String>[],
      }),
    );
    final community = LocalInAppBackend()
        .installLocalPackagePairFromFiles(
          extensionPackagePath: extension.path,
          initializationPackagePath: init.path,
        )
        .community;
    // Resolve the experience and the shared engine before pumping, matching
    // the established engine-native widget-test installation pattern.
    experienceForExtensionId(
      community.extensionId,
      displayName: community.displayName,
      specVersion: community.specVersion,
      experienceConfiguration: community.experienceConfiguration,
    );
    final engine = await workflowEngineForExtensionId(community.extensionId);
    return _InstalledTabletop(community, engine, temp);
  } catch (_) {
    await temp.delete(recursive: true);
    rethrow;
  }
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}

Future<void> _pumpUntilGone(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder to disappear');
}

Future<void> _selectPersona(WidgetTester tester, String fanId) async {
  await selectTestTabletopPersona(tester, fanId);
}

Future<void> _selectTab(
  WidgetTester tester, {
  required String tabId,
  required String rootKey,
}) async {
  final tab = find.byKey(ValueKey('community-tab-$tabId'));
  await _pumpUntil(tester, tab);
  final root = find.byKey(ValueKey(rootKey));
  if (root.evaluate().isNotEmpty) return;
  await tester.ensureVisible(tab);
  await tester.tap(tab);
  await _pumpUntil(tester, root);
}

Future<WorkflowInstance> _proposalByTitle(
  WorkflowEngineApi engine,
  String title,
) async {
  final page = await engine.queryInstances(
    tabId: 'home',
    fanId: 'tabletop-member',
    limit: 100,
  );
  return page.items.firstWhere(
    (instance) =>
        instance.workflowType == 'game-purchase-proposal' &&
        instance.instanceData['gameName'] == title,
    orElse: () => throw StateError('Proposal $title was not found'),
  );
}

Future<String> _createAndSubmitProposal(
  WidgetTester tester,
  WorkflowEngineApi engine, {
  required String title,
  required String reason,
}) async {
  final fab = find.byKey(
    const ValueKey('creatable-fab-game-purchase-proposal'),
  );
  await _pumpUntil(tester, fab);
  await tester.tap(fab);

  final gameNameEditor = find.byKey(
    const ValueKey('new-game-purchase-proposal-editor-gameName'),
  );
  final reasonEditor = find.byKey(
    const ValueKey('new-game-purchase-proposal-editor-reason'),
  );
  await _pumpUntil(tester, gameNameEditor);
  await tester.enterText(gameNameEditor, title);
  await tester.enterText(reasonEditor, reason);
  await tester.pump();

  final create = find.byKey(
    const ValueKey('new-game-purchase-proposal-submit'),
  );
  await _pumpUntil(tester, create);
  await tester.tap(create);
  await _pumpUntilGone(tester, create);

  final draft = (await tester.runAsync(() => _proposalByTitle(engine, title)))!;
  expect(draft.currentState, 'draft');
  final card = find.byKey(
    ValueKey('generic-instance-card-${draft.instanceId}'),
  );
  await _pumpUntil(tester, card);
  final submit = find.byKey(
    ValueKey('generic-instance-${draft.instanceId}-action-submit'),
  );
  await _pumpUntil(tester, submit);
  await tester.ensureVisible(submit);
  await tester.tap(submit);
  WorkflowInstance? pending;
  WorkflowInstance? lastObserved;
  for (var attempt = 0; attempt < 40; attempt++) {
    final current = (await tester.runAsync(
      () => _proposalByTitle(engine, title),
    ))!;
    lastObserved = current;
    if (current.currentState == 'pending') {
      pending = current;
      break;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  final errorText = find
      .byKey(ValueKey('generic-instance-error-${draft.instanceId}'))
      .evaluate()
      .map((element) => element.widget)
      .whereType<Text>()
      .map((text) => text.data)
      .whereType<String>()
      .join(' | ');
  expect(
    pending,
    isNotNull,
    reason:
        'Submit should move $title to pending; '
        'lastState=${lastObserved?.currentState}, '
        'data=${lastObserved?.instanceData}, error=$errorText',
  );
  final submitted = pending!;
  await _pumpUntilGone(tester, submit);

  expect(submitted.currentState, 'pending');
  return submitted.instanceId;
}

Finder _card(String instanceId) =>
    find.byKey(ValueKey('generic-instance-card-$instanceId'));

Finder _action(String instanceId, String transitionId) =>
    find.byKey(ValueKey('generic-instance-$instanceId-action-$transitionId'));

Future<void> _decideFromAdmin(
  WidgetTester tester, {
  required WorkflowEngineApi engine,
  required String instanceId,
  required String transitionId,
  required String expectedState,
}) async {
  final card = _card(instanceId);
  await _pumpUntil(tester, card);
  final action = _action(instanceId, transitionId);
  await _pumpUntil(tester, action);
  await tester.ensureVisible(action);
  await tester.tap(action);
  WorkflowInstance? decided;
  for (var attempt = 0; attempt < 40; attempt++) {
    final page = (await tester.runAsync(
      () => engine.queryInstances(
        tabId: 'admin',
        fanId: 'tabletop-organizer',
        limit: 100,
      ),
    ))!;
    final matches = page.items.where(
      (instance) => instance.instanceId == instanceId,
    );
    final current = matches.isEmpty ? null : matches.first;
    if (current?.currentState == expectedState) {
      decided = current;
      break;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(
    decided,
    isNotNull,
    reason: '$transitionId should move $instanceId to $expectedState.',
  );
  await _pumpUntilGone(tester, action);
  expect(card, findsOneWidget);
}

void main() {
  test('cosmetic-only Admin override decorates the generated organizer tab '
      'without granting one to members', () {
    final source =
        jsonDecode(stripJsonComments(_fixtureFile().readAsStringSync()))
            as Map<String, dynamic>;
    final experience = experienceForExtensionId(
      'phasee-admin-tab-cosmetics',
      displayName: source['displayName'] as String?,
      specVersion: source['specVersion'] as int?,
      experienceConfiguration: source['experience'] as Map<String, Object?>,
    );
    final appShellConfiguration = Map<String, Object?>.from(
      source['appShell']! as Map,
    );
    final tabs = (appShellConfiguration['tabs']! as List)
        .map((tab) => Map<String, Object?>.from(tab as Map))
        .toList();
    final admin = tabs.singleWhere((tab) => tab['tabId'] == 'admin');
    admin
      ..['label'] = 'Organizer desk'
      ..['iconKey'] = 'board'
      ..['description'] = 'Review proposals and publish club updates.';
    appShellConfiguration['tabs'] = tabs;

    final memberTabIds = appShellTabsFor(
      experience: experience,
      roleId: 'tabletop-member',
      appShellConfiguration: appShellConfiguration,
      hasActiveMembership: true,
    ).map((tab) => tab.tabId);
    expect(memberTabIds, isNot(contains('admin')));

    final organizerAdmin = appShellTabsFor(
      experience: experience,
      roleId: 'tabletop-organizer',
      appShellConfiguration: appShellConfiguration,
      hasActiveMembership: true,
    ).singleWhere((tab) => tab.tabId == 'admin');
    expect(organizerAdmin.label, 'Organizer desk');
    expect(organizerAdmin.icon, Icons.fact_check_outlined);
    expect(
      organizerAdmin.description,
      'Review proposals and publish club updates.',
    );
    expect(
      organizerAdmin.isVisibleFor('tabletop-organizer', experience: experience),
      isTrue,
    );
    expect(
      organizerAdmin.rendererContractId,
      'engine-native-generic-list',
      reason: 'The Admin tab mixes multiple card archetypes.',
    );
    expect(organizerAdmin.visibleRoleIds, ['tabletop-organizer']);
  });

  testWidgets(
    'member proposals flow from Home creation through the live Admin queue, '
    'decisions, and revision',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('phasee-purchase-proposals'),
      ))!;
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: LocalExtensionScreen(
              community: installed.community,
              seedDataFiles: const [],
              authApi: activeAuthForInstalledCommunity(
                community: installed.community,
                roleId: 'tabletop-member',
              ),
            ),
          ),
        );
        await _selectPersona(tester, 'tabletop-member');

        const approvedTitle = 'Phase E Approved Game';
        const rejectedTitle = 'Phase E Rejected Game';
        const changesTitle = 'Phase E Changes Game';
        final approvedId = await _createAndSubmitProposal(
          tester,
          installed.engine,
          title: approvedTitle,
          reason: 'A distinctive proposal for the approval path.',
        );
        final rejectedId = await _createAndSubmitProposal(
          tester,
          installed.engine,
          title: rejectedTitle,
          reason: 'A distinctive proposal for the rejection path.',
        );
        final changesId = await _createAndSubmitProposal(
          tester,
          installed.engine,
          title: changesTitle,
          reason: 'A distinctive proposal for the revision path.',
        );

        final initialPending = (await tester.runAsync(() async {
          final result = <String, WorkflowInstance>{};
          for (final title in [approvedTitle, rejectedTitle, changesTitle]) {
            final proposal = await _proposalByTitle(installed.engine, title);
            result[title] = proposal;
          }
          return result;
        }))!;
        expect(initialPending[approvedTitle]!.currentState, 'pending');
        expect(initialPending[rejectedTitle]!.currentState, 'pending');
        expect(initialPending[changesTitle]!.currentState, 'pending');

        // The direct engine read proves the member cannot use organizer-only
        // decisions; the Admin UI assertions below prove the same actions are
        // available to the organizer through the rendered queue.
        final memberActions = (await tester.runAsync(
          () => installed.engine.availableTransitionsAsync(
            workflowType: 'game-purchase-proposal',
            instanceId: changesId,
            currentState: 'pending',
            instanceData: initialPending[changesTitle]!.instanceData,
            fanId: 'tabletop-member',
          ),
        ))!;
        expect(
          memberActions.map((transition) => transition.id),
          isNot(contains('approve')),
        );
        expect(
          memberActions.map((transition) => transition.id),
          isNot(contains('request-changes')),
        );
        expect(
          memberActions.map((transition) => transition.id),
          isNot(contains('reject')),
        );
        expect(find.byKey(const ValueKey('community-tab-admin')), findsNothing);

        await _selectPersona(tester, 'tabletop-organizer');
        await _selectTab(
          tester,
          tabId: 'admin',
          rootKey: 'engine-native-list-root-admin',
        );

        // These titles were created during this test, so seeing them here
        // proves the Admin surface is a fresh query-bound pending queue, not
        // a projection of only the frozen seed rows.
        await _pumpUntil(tester, find.text(approvedTitle));
        await _pumpUntil(tester, find.text(rejectedTitle));
        await _pumpUntil(tester, find.text(changesTitle));
        expect(find.text(approvedTitle), findsOneWidget);
        expect(find.text(rejectedTitle), findsOneWidget);
        expect(find.text(changesTitle), findsOneWidget);
        expect(
          find.descendant(
            of: _card(approvedId),
            matching: _action(approvedId, 'approve'),
          ),
          findsOneWidget,
        );

        await _decideFromAdmin(
          tester,
          engine: installed.engine,
          instanceId: approvedId,
          transitionId: 'approve',
          expectedState: 'approved',
        );
        final approved = (await tester.runAsync(
          () => _proposalByTitle(installed.engine, approvedTitle),
        ))!;
        expect(approved.currentState, 'approved');
        expect(approved.instanceData['decidedByFanId'], 'tabletop-organizer');
        expect(approved.instanceData['decidedAt'], isNotNull);

        await _decideFromAdmin(
          tester,
          engine: installed.engine,
          instanceId: rejectedId,
          transitionId: 'reject',
          expectedState: 'rejected',
        );
        final rejected = (await tester.runAsync(
          () => _proposalByTitle(installed.engine, rejectedTitle),
        ))!;
        expect(rejected.currentState, 'rejected');
        expect(rejected.instanceData['decidedByFanId'], 'tabletop-organizer');
        expect(rejected.instanceData['decidedAt'], isNotNull);

        await _decideFromAdmin(
          tester,
          engine: installed.engine,
          instanceId: changesId,
          transitionId: 'request-changes',
          expectedState: 'changes-requested',
        );
        final changesRequested = (await tester.runAsync(
          () => _proposalByTitle(installed.engine, changesTitle),
        ))!;
        expect(changesRequested.currentState, 'changes-requested');
        expect(
          changesRequested.instanceData['decidedByFanId'],
          'tabletop-organizer',
        );

        await _selectPersona(tester, 'tabletop-member');
        await _selectTab(
          tester,
          tabId: 'home',
          rootKey: 'engine-native-list-root-home',
        );

        // Home's actor binding now shows the real approved and rejected
        // instances, while the compose/revise binding shows the real
        // changes-requested instance. The state assertions above and these
        // binding-scoped cards together prove the member sees their own live
        // outcomes, not a hardcoded status card.
        await _pumpUntil(tester, _card(approvedId));
        await _pumpUntil(tester, _card(rejectedId));
        await _pumpUntil(tester, _card(changesId));
        expect(
          find.descendant(
            of: _card(approvedId),
            matching: find.text(approvedTitle),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: _card(rejectedId),
            matching: find.text(rejectedTitle),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(
              ValueKey('generic-instance-field-$changesId-gameName'),
            ),
            matching: find.text(changesTitle),
          ),
          findsOneWidget,
        );
        expect(_action(approvedId, 'approve'), findsNothing);
        expect(_action(rejectedId, 'reject'), findsNothing);
        expect(_action(changesId, 'approve'), findsNothing);

        // `decidedAt` is an effect-owned, unlabeled internal field. The
        // shared generic card must suppress it rather than exposing its key.
        expect(
          find.descendant(
            of: _card(approvedId),
            matching: find.text('decidedAt'),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: _card(rejectedId),
            matching: find.text('decidedAt'),
          ),
          findsNothing,
        );

        final revisedTitle = 'Phase E Changes Game Revised';
        final revisedReason =
            'The organizer requested a clearer justification.';
        final gameNameEditor = find.byKey(
          ValueKey('generic-instance-editor-$changesId-gameName'),
        );
        final reasonEditor = find.byKey(
          ValueKey('generic-instance-editor-$changesId-reason'),
        );
        await _pumpUntil(tester, gameNameEditor);
        await tester.ensureVisible(gameNameEditor);
        await tester.enterText(gameNameEditor, revisedTitle);
        await tester.ensureVisible(reasonEditor);
        await tester.enterText(reasonEditor, revisedReason);
        await tester.pump();
        final save = find.byKey(ValueKey('generic-instance-save-$changesId'));
        await _pumpUntil(tester, save);
        await tester.ensureVisible(save);
        await tester.tap(save);
        final revisedTitleFact = find.descendant(
          of: find.byKey(
            ValueKey('generic-instance-field-$changesId-gameName'),
          ),
          matching: find.text(revisedTitle),
        );
        await _pumpUntil(tester, revisedTitleFact);

        final revisedSubmit = _action(changesId, 'submit');
        await _pumpUntil(tester, revisedSubmit);
        await tester.ensureVisible(revisedSubmit);
        await tester.tap(revisedSubmit);
        await _pumpUntilGone(tester, revisedSubmit);

        final resubmitted = (await tester.runAsync(
          () => _proposalByTitle(installed.engine, revisedTitle),
        ))!;
        expect(resubmitted.currentState, 'pending');
        expect(resubmitted.instanceData['reason'], revisedReason);

        // A second Admin query after resubmission must show the revised
        // proposal again in the pending queue.
        await _selectPersona(tester, 'tabletop-organizer');
        await _selectTab(
          tester,
          tabId: 'admin',
          rootKey: 'engine-native-list-root-admin',
        );
        await _pumpUntil(tester, find.text(revisedTitle));
        expect(find.text(revisedTitle), findsOneWidget);
        expect(find.text(changesTitle), findsNothing);
        expect(_action(changesId, 'approve'), findsOneWidget);
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );
}
