import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

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
        'schemaVersion': 1,
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

Future<void> _selectPersona(WidgetTester tester, String personaId) async {
  final personaPicker = find.byKey(const ValueKey('persona-picker-button'));
  await _pumpUntil(tester, personaPicker);
  await tester.tap(personaPicker);
  await tester.pump();
  final option = find.byKey(ValueKey('persona-option-$personaId'));
  await _pumpUntil(tester, option);
  await tester.tap(option);
  await tester.pump();
}

Future<void> _selectTab(
  WidgetTester tester, {
  required String tabId,
  required String rootKey,
}) async {
  final tab = find.byKey(ValueKey('community-tab-$tabId'));
  await _pumpUntil(tester, tab);
  await tester.ensureVisible(tab);
  await tester.tap(tab);
  await _pumpUntil(tester, find.byKey(ValueKey(rootKey)));
}

Future<WorkflowInstance> _proposalByTitle(
  WorkflowEngineApi engine,
  String title,
) async {
  final page = await engine.queryInstances(
    tabId: 'home',
    personaId: 'tabletop-member',
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
  await _pumpUntilGone(tester, submit);

  final pending = (await tester.runAsync(
    () => _proposalByTitle(engine, title),
  ))!;
  expect(pending.currentState, 'pending');
  return pending.instanceId;
}

Finder _card(String instanceId) =>
    find.byKey(ValueKey('generic-instance-card-$instanceId'));

Finder _action(String instanceId, String transitionId) =>
    find.byKey(ValueKey('generic-instance-$instanceId-action-$transitionId'));

Future<void> _decideFromAdmin(
  WidgetTester tester, {
  required String instanceId,
  required String transitionId,
}) async {
  final card = _card(instanceId);
  await _pumpUntil(tester, card);
  final action = _action(instanceId, transitionId);
  await _pumpUntil(tester, action);
  await tester.ensureVisible(action);
  await tester.tap(action);
  await _pumpUntilGone(tester, card);
}

void main() {
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
            personaId: 'tabletop-member',
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
        expect(
          find.byKey(const ValueKey('community-tab-admin')),
          findsNothing,
        );

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
          instanceId: approvedId,
          transitionId: 'approve',
        );
        final approved = (await tester.runAsync(
          () => _proposalByTitle(installed.engine, approvedTitle),
        ))!;
        expect(approved.currentState, 'approved');
        expect(
          approved.instanceData['decidedByPersonaId'],
          'tabletop-organizer',
        );
        expect(approved.instanceData['decidedAt'], isNotNull);

        await _decideFromAdmin(
          tester,
          instanceId: rejectedId,
          transitionId: 'reject',
        );
        final rejected = (await tester.runAsync(
          () => _proposalByTitle(installed.engine, rejectedTitle),
        ))!;
        expect(rejected.currentState, 'rejected');
        expect(
          rejected.instanceData['decidedByPersonaId'],
          'tabletop-organizer',
        );
        expect(rejected.instanceData['decidedAt'], isNotNull);

        await _decideFromAdmin(
          tester,
          instanceId: changesId,
          transitionId: 'request-changes',
        );
        final changesRequested = (await tester.runAsync(
          () => _proposalByTitle(installed.engine, changesTitle),
        ))!;
        expect(changesRequested.currentState, 'changes-requested');
        expect(
          changesRequested.instanceData['decidedByPersonaId'],
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
