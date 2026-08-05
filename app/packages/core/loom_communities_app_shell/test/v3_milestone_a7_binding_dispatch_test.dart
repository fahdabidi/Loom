import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

LoomWorkflowStateMachine _machine(
  String type,
  List<Map<String, dynamic>> bindings, {
  Map<String, dynamic>? transitions,
}) => LoomWorkflowStateMachine.fromJson({
  'initialState': 'open',
  'states': {
    'open': {'label': 'Open'},
    'done': {'label': 'Done'},
  },
  'transitions': transitions == null ? <dynamic>[] : [transitions],
  'renderBindings': bindings,
}, type);

Map<String, dynamic> _binding(
  String tabId, {
  String role = 'any',
  List<String> states = const ['open'],
  String? audienceMemberField,
}) => {
  'tabId': tabId,
  'states': states,
  'role': role,
  'cardSurfaceFamily': 'event',
  'bindingKind': 'primary',
  if (audienceMemberField != null) 'audienceMemberField': audienceMemberField,
};

class _CountingEngine implements WorkflowEngineApi {
  _CountingEngine(this.query);
  final Future<InstancePage> Function({
    required String tabId,
    required String personaId,
    required int limit,
    String? cursor,
  })
  query;
  int queries = 0;

  @override
  Future<InstancePage> queryInstances({
    required String tabId,
    required String personaId,
    SurfaceQuery query = const SurfaceQuery.empty(),
    int limit = 25,
    String? cursor,
  }) {
    queries++;
    return this.query(
      tabId: tabId,
      personaId: personaId,
      limit: limit,
      cursor: cursor,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DelegatingEngine extends _CountingEngine {
  _DelegatingEngine(this.delegate)
    : super(
        ({required tabId, required personaId, required limit, cursor}) =>
            delegate.queryInstances(
              tabId: tabId,
              personaId: personaId,
              limit: limit,
              cursor: cursor,
            ),
      );
  final WorkflowEngineApi delegate;
}

WorkflowInstance _instance(String id, String type, {String state = 'open'}) =>
    WorkflowInstance(
      instanceId: id,
      workflowType: type,
      currentState: state,
      instanceData: const {'title': 'controlled'},
      createdByPersonaId: 'owner',
    );

Future<WorkflowInstance> _read(
  LocalWorkflowEngineApi engine,
  String id,
) async => (await engine.queryInstances(
  tabId: 'read',
  personaId: 'reader',
)).items.singleWhere((item) => item.instanceId == id);

void main() {
  testWidgets(
    'real pages include Calendar only, all identities, and default any',
    (tester) async {
      final local = LocalWorkflowEngineApi(
        db: WorkflowDatabase.memory(),
        communityId: 'a7-pages',
      );
      final calendar = _machine('calendar-event', [
        _binding('calendar'),
        _binding('home'),
      ]);
      final homeOnly = _machine('home-only', [_binding('home')]);
      local
        ..registerDefinition(calendar)
        ..registerDefinition(homeOnly);
      final ids = <String>[];
      for (final title in ['01', '02', '03']) {
        ids.add(
          await local.createInstance(
            workflowType: 'calendar-event',
            personaId: 'owner',
            initialInstanceData: {'title': title},
          ),
        );
      }
      final hiddenId = await local.createInstance(
        workflowType: 'home-only',
        personaId: 'owner',
        initialInstanceData: const {'title': '04-home-only'},
      );
      final engine = _DelegatingEngine(local);
      late List<EngineNativeResolvedBinding> seen;
      await tester.pumpWidget(
        _host(
          EngineNativeBindingDispatcher(
            engine: engine,
            definitions: {'calendar-event': calendar, 'home-only': homeOnly},
            tabId: 'calendar',
            personaId: 'viewer',
            pageSize: 1,
            builder: (_, bindings, __) {
              seen = bindings;
              return Text(bindings.map((b) => b.identity).join('|'));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(engine.queries, 4);
      expect(seen.map((b) => b.instance.instanceId), orderedEquals(ids));
      expect(
        seen.map((b) => b.definitionBindingIndex),
        orderedEquals([0, 0, 0]),
      );
      expect(seen.map((b) => b.identity).toSet(), hasLength(3));
      expect(seen.any((b) => b.instance.instanceId == hiddenId), isFalse);
      expect(seen.every((b) => b.binding.tabId == 'calendar'), isTrue);
      expect(() => seen.add(seen.first), throwsUnsupportedError);
    },
  );

  testWidgets(
    'real resolver applies state and roles and preserves all binding order',
    (tester) async {
      final local = LocalWorkflowEngineApi(
        db: WorkflowDatabase.memory(),
        communityId: 'a7-roles',
      );
      final machine = _machine('roles', [
        _binding('calendar', role: 'alpha'),
        _binding('calendar', role: 'beta'),
        _binding('calendar', role: 'alpha'),
        _binding('calendar', role: 'alpha', states: const ['done']),
        _binding('calendar', role: 'missing'),
      ]);
      local.registerDefinition(machine);
      final id = await local.createInstance(
        workflowType: 'roles',
        personaId: 'owner',
        initialInstanceData: const {'title': 'roles'},
      );
      late List<EngineNativeResolvedBinding> seen;
      await tester.pumpWidget(
        _host(
          EngineNativeBindingDispatcher(
            engine: local,
            definitions: {'roles': machine},
            tabId: 'calendar',
            personaId: 'viewer',
            rolesForInstance: (_, __) => const ['alpha', 'beta'],
            builder: (_, bindings, __) {
              seen = bindings;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        seen.map((b) => b.definitionBindingIndex),
        orderedEquals([0, 1, 2]),
      );
      expect(
        seen.map((b) => b.identity),
        orderedEquals([
          'calendar::$id::0',
          'calendar::$id::1',
          'calendar::$id::2',
        ]),
      );
      expect(seen.map((b) => b.identity).toSet(), hasLength(3));
    },
  );

  testWidgets('real dynamic receiver audience receives only invited persona', (
    tester,
  ) async {
    final local = LocalWorkflowEngineApi(
      db: WorkflowDatabase.memory(),
      communityId: 'a7-audience',
    );
    final machine = _machine('invite', [
      _binding(
        'calendar',
        role: 'receiver',
        audienceMemberField: 'invitedPersonaIds',
      ),
    ]);
    local.registerDefinition(machine);
    await local.createInstance(
      workflowType: 'invite',
      personaId: 'owner',
      initialInstanceData: {
        'title': 'invite',
        'audienceScope': 'selected',
        'invitedPersonaIds': ['invited'],
      },
    );
    Future<List<EngineNativeResolvedBinding>> load(String persona) async {
      late List<EngineNativeResolvedBinding> output;
      await tester.pumpWidget(
        _host(
          EngineNativeBindingDispatcher(
            engine: local,
            definitions: {'invite': machine},
            tabId: 'calendar',
            personaId: persona,
            builder: (_, bindings, __) {
              output = bindings;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      return output;
    }

    expect((await load('invited')).map((b) => b.instance.workflowType), [
      'invite',
    ]);
    expect(await load('uninvited'), isEmpty);
  });

  testWidgets(
    'every disabled tab publishes its keyed empty builder without querying',
    (tester) async {
      for (final tab in ['messages']) {
        final engine = _CountingEngine(
          ({required tabId, required personaId, required limit, cursor}) =>
              Future.value(const InstancePage(items: [])),
        );
        var received = -1;
        await tester.pumpWidget(
          _host(
            EngineNativeBindingDispatcher(
              engine: engine,
              definitions: const {},
              tabId: tab,
              personaId: 'p',
              builder: (_, bindings, __) {
                received = bindings.length;
                return const SizedBox();
              },
            ),
          ),
        );
        await tester.pump();
        expect(received, 0, reason: tab);
        expect(engine.queries, 0, reason: tab);
        expect(
          find.byKey(Key('engine-native-bindings-empty-$tab-p')),
          findsOneWidget,
        );
      }
    },
  );

  testWidgets(
    'missing definitions and invalid cursors are visible hard errors',
    (tester) async {
      Future<void> expectError(_CountingEngine engine, String text) async {
        var successes = 0;
        await tester.pumpWidget(
          _host(
            EngineNativeBindingDispatcher(
              engine: engine,
              definitions: const {},
              tabId: 'calendar',
              personaId: 'p',
              builder: (_, __, ___) {
                successes++;
                return const SizedBox();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('engine-native-bindings-error-calendar-p')),
          findsOneWidget,
        );
        expect(find.textContaining(text), findsOneWidget);
        expect(successes, 0);
      }

      await expectError(
        _CountingEngine(
          ({required tabId, required personaId, required limit, cursor}) =>
              Future.value(
                InstancePage(items: [_instance('missing-id', 'missing-type')]),
              ),
        ),
        'missing-type instance missing-id',
      );
      final blank = _CountingEngine(
        ({required tabId, required personaId, required limit, cursor}) =>
            Future.value(
              const InstancePage(items: [], hasMore: true, nextCursor: '  '),
            ),
      );
      await expectError(blank, 'Invalid pagination cursor');
      expect(blank.queries, 1);
      final nullCursor = _CountingEngine(
        ({required tabId, required personaId, required limit, cursor}) =>
            Future.value(const InstancePage(items: [], hasMore: true)),
      );
      await expectError(nullCursor, 'Invalid pagination cursor');
      expect(nullCursor.queries, 1);
      final repeated = _CountingEngine(
        ({required tabId, required personaId, required limit, cursor}) =>
            Future.value(
              InstancePage(
                items: const [],
                hasMore: true,
                nextCursor: cursor == null ? 'again' : 'again',
              ),
            ),
      );
      await expectError(repeated, 'Invalid pagination cursor');
      expect(repeated.queries, 2);
    },
  );

  testWidgets(
    'Retry re-queries a real engine and publishes only fresh bindings',
    (tester) async {
      final local = LocalWorkflowEngineApi(
        db: WorkflowDatabase.memory(),
        communityId: 'a7-retry',
      );
      final machine = _machine('retry', [_binding('calendar')]);
      local.registerDefinition(machine);
      final id = await local.createInstance(
        workflowType: 'retry',
        personaId: 'owner',
        initialInstanceData: const {'title': 'retry'},
      );
      var first = true;
      final engine = _CountingEngine(({
        required tabId,
        required personaId,
        required limit,
        cursor,
      }) {
        if (first) {
          first = false;
          return Future<InstancePage>.error(StateError('first failure'));
        }
        return local.queryInstances(
          tabId: tabId,
          personaId: personaId,
          limit: limit,
          cursor: cursor,
        );
      });
      var calls = 0;
      late List<EngineNativeResolvedBinding> seen;
      await tester.pumpWidget(
        _host(
          EngineNativeBindingDispatcher(
            engine: engine,
            definitions: {'retry': machine},
            tabId: 'calendar',
            personaId: 'p',
            builder: (_, bindings, __) {
              calls++;
              seen = bindings;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('engine-native-bindings-calendar')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('engine-native-bindings-error-calendar-p')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('engine-native-bindings-retry-calendar-p')),
        findsOneWidget,
      );
      expect(calls, 0);
      await tester.tap(
        find.byKey(const Key('engine-native-bindings-retry-calendar-p')),
      );
      await tester.pumpAndSettle();
      expect(engine.queries, 2);
      expect(calls, 1);
      expect(seen.single.instance.instanceId, id);
      expect(
        find.byKey(const Key('engine-native-bindings-error-calendar-p')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('engine-native-bindings-loading-calendar-p')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'stale loads and unsupported-tab invalidation cannot publish or paginate',
    (tester) async {
      final a = Completer<InstancePage>();
      final b = Completer<InstancePage>();
      final calendar = Completer<InstancePage>();
      final engineA = _CountingEngine(
        ({required tabId, required personaId, required limit, cursor}) =>
            a.future,
      );
      final engineB = _CountingEngine(
        ({required tabId, required personaId, required limit, cursor}) =>
            b.future,
      );
      final machine = _machine('stale', [_binding('calendar')]);
      Widget widget(WorkflowEngineApi engine, String tab, String persona) =>
          _host(
            EngineNativeBindingDispatcher(
              engine: engine,
              definitions: {'stale': machine},
              tabId: tab,
              personaId: persona,
              builder: (_, bindings, __) =>
                  Text('published-$persona-${bindings.length}'),
            ),
          );
      await tester.pumpWidget(widget(engineA, 'calendar', 'A'));
      expect(
        find.byKey(const Key('engine-native-bindings-loading-calendar-A')),
        findsOneWidget,
      );
      await tester.pumpWidget(widget(engineB, 'calendar', 'B'));
      expect(
        find.byKey(const Key('engine-native-bindings-loading-calendar-B')),
        findsOneWidget,
      );
      a.complete(
        InstancePage(
          items: [_instance('a', 'stale')],
          hasMore: true,
          nextCursor: 'next',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('published-A'), findsNothing);
      expect(find.textContaining('error-calendar-A'), findsNothing);
      expect(engineA.queries, 1);
      b.complete(InstancePage(items: [_instance('b', 'stale')]));
      await tester.pumpAndSettle();
      expect(find.text('published-B-1'), findsOneWidget);
      final old = _CountingEngine(
        ({required tabId, required personaId, required limit, cursor}) =>
            calendar.future,
      );
      await tester.pumpWidget(widget(old, 'calendar', 'C'));
      expect(
        find.byKey(const Key('engine-native-bindings-loading-calendar-C')),
        findsOneWidget,
      );
      await tester.pumpWidget(widget(old, 'messages', 'C'));
      await tester.pump();
      expect(
        find.byKey(const Key('engine-native-bindings-empty-messages-C')),
        findsOneWidget,
      );
      expect(old.queries, 1);
      calendar.complete(InstancePage(items: [_instance('old', 'stale')]));
      await tester.pumpAndSettle();
      expect(find.textContaining('published-C-1'), findsNothing);
    },
  );

  testWidgets(
    'authoritative callback refreshes real state and rejects stale callbacks',
    (tester) async {
      final local = LocalWorkflowEngineApi(
        db: WorkflowDatabase.memory(),
        communityId: 'a7-callback',
      );
      final machine = _machine(
        'transition',
        [
          _binding('calendar', states: const ['open']),
          _binding('home', states: const ['done']),
        ],
        transitions: {
          'id': 'finish',
          'from': ['open'],
          'to': 'done',
          'label': 'Finish',
        },
      );
      local.registerDefinition(machine);
      final id = await local.createInstance(
        workflowType: 'transition',
        personaId: 'owner',
        initialInstanceData: const {'title': 'transition'},
      );
      final engine = _DelegatingEngine(local);
      ValueChanged<WorkflowInstance>? callback;
      var publications = 0;
      Widget build(String persona) => _host(
        EngineNativeBindingDispatcher(
          engine: engine,
          definitions: {'transition': machine},
          tabId: 'calendar',
          personaId: persona,
          builder: (_, bindings, changed) {
            publications++;
            callback = changed;
            return Text('count-${bindings.length}');
          },
        ),
      );
      await tester.pumpWidget(build('p'));
      await tester.pumpAndSettle();
      final oldCallback = callback!;
      expect(find.text('count-1'), findsOneWidget);
      await local.applyTransition(
        workflowType: 'transition',
        instanceId: id,
        transitionId: 'finish',
        personaId: 'owner',
      );
      final updated = await _read(local, id);
      oldCallback(_instance('wrong', 'transition'));
      await tester.pumpAndSettle();
      expect(engine.queries, 2);
      expect(find.text('count-0'), findsOneWidget);
      await tester.pumpWidget(build('new-persona'));
      await tester.pumpAndSettle();
      final before = engine.queries;
      oldCallback(updated);
      await tester.pumpAndSettle();
      expect(engine.queries, before);
      expect(find.text('count-0'), findsOneWidget);
      expect(publications, greaterThanOrEqualTo(3));
    },
  );
}
