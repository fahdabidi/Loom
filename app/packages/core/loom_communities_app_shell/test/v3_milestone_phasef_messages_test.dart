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
    'loom-phasef-$extensionId-',
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
    // The engine-native store must be registered before the widget is pumped;
    // this is the established Phase B/E pattern for native SQLite-backed
    // widget tests and keeps engine calls in the same async zone.
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
  for (var attempt = 0; attempt < 50; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}

Future<void> _pumpUntilGone(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 50; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder to disappear');
}

Future<void> _selectPersona(WidgetTester tester, String personaId) async {
  await selectTestTabletopPersona(tester, personaId);
}

Future<void> _selectMessages(WidgetTester tester) async {
  final tab = find.byKey(const ValueKey('community-tab-messages'));
  await _pumpUntil(tester, tab);
  await tester.ensureVisible(tab);
  await tester.tap(tab);
  await _pumpUntil(
    tester,
    find.byKey(const ValueKey('engine-native-list-root-messages')),
  );
}

Future<WorkflowInstance> _threadById(
  WorkflowEngineApi engine,
  String instanceId,
) async {
  final page = await engine.queryInstances(
    tabId: 'messages',
    personaId: 'tabletop-member',
    limit: 100,
  );
  return page.items.firstWhere(
    (instance) => instance.instanceId == instanceId,
    orElse: () => throw StateError('Thread $instanceId was not found'),
  );
}

Future<WorkflowInstance> _pumpUntilThread(
  WidgetTester tester,
  WorkflowEngineApi engine,
  String instanceId,
  bool Function(WorkflowInstance instance) predicate,
) async {
  WorkflowInstance? latest;
  for (var attempt = 0; attempt < 50; attempt++) {
    latest = (await tester.runAsync(() => _threadById(engine, instanceId)))!;
    if (predicate(latest)) return latest;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  throw TestFailure(
    'Timed out waiting for persisted state on $instanceId; latest=$latest',
  );
}

Future<void> _postMessage(
  WidgetTester tester, {
  required String instanceId,
  required String body,
}) async {
  final action = find.byKey(
    ValueKey('generic-instance-$instanceId-action-post-message'),
  );
  await _pumpUntil(tester, action);
  await tester.ensureVisible(action);
  await tester.tap(action);

  final editor = find.byKey(const ValueKey('generic-transition-input-body'));
  await _pumpUntil(tester, editor);
  await tester.enterText(editor, body);
  await tester.tap(
    find.byKey(const ValueKey('generic-transition-input-confirm')),
  );
  await _pumpUntil(tester, find.text(body));
}

void main() {
  testWidgets(
    'engine-native Messages renders seeded threads and completes the full thread lifecycle',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('phasef-messages-pipeline'),
      ))!;
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: LocalExtensionScreen(
              community: installed.community,
              seedDataFiles: const [],
              authApi: activeAuthForInstalledCommunity(
                community: installed.community,
                personaTypeId: 'tabletop-member',
              ),
            ),
          ),
        );
        await _selectPersona(tester, 'tabletop-member');
        await _selectMessages(tester);

        // F.2: both real frozen instances resolve through the messages binding
        // and the generic tile keeps the computed messageCount visible.
        await _pumpUntil(tester, find.text('Welcome new members!'));
        await _pumpUntil(tester, find.text('Game suggestions for next week'));
        expect(
          find.byKey(const ValueKey('generic-instance-card-thread-welcome')),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey(
              'generic-instance-field-thread-welcome-messageCount',
            ),
          ),
          findsOneWidget,
        );
        expect(find.text('2'), findsAtLeastNWidgets(2));

        // The messages list is an in-instance structured list, not another
        // queryInstances repeater. Sender, body, and frozen timestamps are
        // visible from the generic card.
        expect(
          find.byKey(
            const ValueKey(
              'generic-instance-list-field-thread-welcome-messages',
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey(
              'generic-instance-list-sender-thread-welcome-messages-0',
            ),
          ),
          findsOneWidget,
        );
        expect(find.text('tabletop-organizer'), findsAtLeastNWidgets(1));
        expect(
          find.text(
            'Welcome to the Tabletop Club! Our first game night is Friday at 7pm in the community room.',
          ),
          findsOneWidget,
        );
        expect(find.text('2026-07-01T10:00:00.000Z'), findsOneWidget);

        // F.3: post-message opens the generic transition-input dialog and
        // sends the body as applyTransition input.body.
        const postedBody = 'The new game room has plenty of table space.';
        await _postMessage(
          tester,
          instanceId: 'thread-welcome',
          body: postedBody,
        );
        final posted = (await tester.runAsync(
          () => _threadById(installed.engine, 'thread-welcome'),
        ))!;
        final postedMessages = posted.instanceData['messages'] as List;
        final lastPosted = postedMessages.last as Map;
        expect(lastPosted['senderFanId'], 'tabletop-member');
        expect(lastPosted['body'], postedBody);
        expect(DateTime.tryParse('${lastPosted['timestamp']}'), isNotNull);
        expect(posted.instanceData['messageCount'], 3);

        // F.3: mark-read is a real transition/effect, and unread is an
        // internal effect-owned field rather than a fake card-local flag.
        final markRead = find.byKey(
          const ValueKey(
            'generic-instance-thread-game-suggestions-action-mark-read',
          ),
        );
        await _pumpUntil(tester, markRead);
        await tester.ensureVisible(markRead);
        await tester.tap(markRead);
        final read = await _pumpUntilThread(
          tester,
          installed.engine,
          'thread-game-suggestions',
          (instance) => instance.instanceData['unread'] == false,
        );
        expect(read.instanceData['unread'], isFalse);
        expect(
          find.byKey(
            const ValueKey(
              'generic-instance-field-thread-game-suggestions-unread',
            ),
          ),
          findsNothing,
        );

        // Archive is terminal. The v4 package keeps an archived summary
        // binding, while removing the open-state action row.
        final archive = find.byKey(
          const ValueKey(
            'generic-instance-thread-game-suggestions-action-archive',
          ),
        );
        await _pumpUntil(tester, archive);
        await tester.ensureVisible(archive);
        await tester.tap(archive);
        await _pumpUntilGone(tester, archive);
        expect(find.text('Game suggestions for next week'), findsOneWidget);
        final archived = (await tester.runAsync(
          () => _threadById(installed.engine, 'thread-game-suggestions'),
        ))!;
        expect(archived.currentState, 'archived');

        // F.4: the tab-scoped creation grammar scans the same JSON binding and
        // exposes the real New thread FAB. The generic form uses the existing
        // audience-style picker for participantPersonaIds.
        final fab = find.byKey(
          const ValueKey('creatable-fab-discussion-thread'),
        );
        await _pumpUntil(tester, fab);
        await tester.tap(fab);
        final subjectEditor = find.byKey(
          const ValueKey('new-discussion-thread-editor-subject'),
        );
        await _pumpUntil(tester, subjectEditor);
        await tester.enterText(subjectEditor, 'New table setup ideas');
        final memberChoice = find.byKey(
          const ValueKey('audience-picker-member-tabletop-member'),
        );
        await _pumpUntil(tester, memberChoice);
        // The v4 prefill already includes the actor; the picker proves the
        // candidate is present without toggling that required participant off.
        await tester.tap(
          find.byKey(const ValueKey('new-discussion-thread-submit')),
        );
        await _pumpUntilGone(
          tester,
          find.byKey(const ValueKey('new-discussion-thread-submit')),
        );

        final created = (await tester.runAsync(() async {
          final page = await installed.engine.queryInstances(
            tabId: 'messages',
            personaId: 'tabletop-member',
            limit: 100,
          );
          return page.items.firstWhere(
            (instance) =>
                instance.instanceData['subject'] == 'New table setup ideas',
          );
        }))!;
        expect(created.currentState, 'open');
        expect(created.instanceData['participantFanIds'], ['tabletop-member']);
        await _pumpUntil(tester, find.text('New table setup ideas'));
        await _postMessage(
          tester,
          instanceId: created.instanceId,
          body: 'I can bring the folding card tables.',
        );
        final replied = (await tester.runAsync(
          () => _threadById(installed.engine, created.instanceId),
        ))!;
        final createdMessages = replied.instanceData['messages'] as List;
        final createdReply = createdMessages.single as Map;
        expect(createdReply['senderFanId'], 'tabletop-member');
        expect(createdReply['body'], 'I can bring the folding card tables.');
        expect(DateTime.tryParse('${createdReply['timestamp']}'), isNotNull);
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );
}
