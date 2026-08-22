import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

const _customTabId = 'nonexistent-tab';

LoomWorkflowStateMachine _machine(
  String type,
  List<Map<String, dynamic>> bindings, {
  Map<String, dynamic>? transitions,
  Map<String, dynamic>? instanceDataSchema,
}) => LoomWorkflowStateMachine.fromJson({
  'initialState': 'open',
  'states': {
    'open': {'label': 'Open'},
    'done': {'label': 'Done'},
  },
  'transitions': transitions == null ? <dynamic>[] : [transitions],
  if (instanceDataSchema != null) 'instanceDataSchema': instanceDataSchema,
  'renderBindings': bindings,
}, type);

Map<String, dynamic> _binding(
  String tabId, {
  String role = 'any',
  List<String> states = const ['open'],
  String cardSurfaceFamily = 'event',
  String? audienceMemberField,
}) => {
  'tabId': tabId,
  'states': states,
  'audience': role,
  'cardSurfaceFamily': cardSurfaceFamily,
  'bindingKind': 'primary',
  if (audienceMemberField != null) 'audienceMemberField': audienceMemberField,
};

class _CountingEngine implements WorkflowEngineApi {
  _CountingEngine(this.query);
  final Future<InstancePage> Function({
    required String tabId,
    required String fanId,
    required int limit,
    String? cursor,
  })
  query;
  int queries = 0;

  @override
  Future<InstancePage> queryInstances({
    required String tabId,
    required String fanId,
    SurfaceQuery query = const SurfaceQuery.empty(),
    int limit = 25,
    String? cursor,
  }) {
    queries++;
    return this.query(tabId: tabId, fanId: fanId, limit: limit, cursor: cursor);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DelegatingEngine extends _CountingEngine {
  _DelegatingEngine(this.delegate)
    : super(
        ({required tabId, required fanId, required limit, cursor}) =>
            delegate.queryInstances(
              tabId: tabId,
              fanId: fanId,
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
      createdByFanId: 'owner',
    );

Future<WorkflowInstance> _read(
  LocalWorkflowEngineApi engine,
  String id,
) async => (await engine.queryInstances(
  tabId: 'read',
  fanId: 'reader',
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
            fanId: 'owner',
            initialInstanceData: {'title': title},
          ),
        );
      }
      final hiddenId = await local.createInstance(
        workflowType: 'home-only',
        fanId: 'owner',
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
            fanId: 'viewer',
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
        fanId: 'owner',
        initialInstanceData: const {'title': 'roles'},
      );
      late List<EngineNativeResolvedBinding> seen;
      await tester.pumpWidget(
        _host(
          EngineNativeBindingDispatcher(
            engine: local,
            definitions: {'roles': machine},
            tabId: 'calendar',
            fanId: 'viewer',
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
        audienceMemberField: 'invitedFanIds',
      ),
    ]);
    local.registerDefinition(machine);
    await local.createInstance(
      workflowType: 'invite',
      fanId: 'owner',
      initialInstanceData: {
        'title': 'invite',
        'audienceScope': 'selected',
        'invitedFanIds': ['invited'],
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
            fanId: persona,
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
    'every arbitrary tab queries engine and publishes keyed empty builder when no bindings exist',
    (tester) async {
      for (final tab in [_customTabId]) {
        final engine = _CountingEngine(
          ({required tabId, required fanId, required limit, cursor}) =>
              Future.value(const InstancePage(items: [])),
        );
        var received = -1;
        await tester.pumpWidget(
          _host(
            EngineNativeBindingDispatcher(
              engine: engine,
              definitions: const {},
              tabId: tab,
              fanId: 'p',
              builder: (_, bindings, __) {
                received = bindings.length;
                return const SizedBox();
              },
            ),
          ),
        );
        await tester.pump();
        expect(received, 0, reason: tab);
        expect(engine.queries, 1, reason: tab);
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
              fanId: 'p',
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
          ({required tabId, required fanId, required limit, cursor}) =>
              Future.value(
                InstancePage(items: [_instance('missing-id', 'missing-type')]),
              ),
        ),
        'missing-type instance missing-id',
      );
      final blank = _CountingEngine(
        ({required tabId, required fanId, required limit, cursor}) =>
            Future.value(
              const InstancePage(items: [], hasMore: true, nextCursor: '  '),
            ),
      );
      await expectError(blank, 'Invalid pagination cursor');
      expect(blank.queries, 1);
      final nullCursor = _CountingEngine(
        ({required tabId, required fanId, required limit, cursor}) =>
            Future.value(const InstancePage(items: [], hasMore: true)),
      );
      await expectError(nullCursor, 'Invalid pagination cursor');
      expect(nullCursor.queries, 1);
      final repeated = _CountingEngine(
        ({required tabId, required fanId, required limit, cursor}) =>
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
        fanId: 'owner',
        initialInstanceData: const {'title': 'retry'},
      );
      var first = true;
      final engine = _CountingEngine(({
        required tabId,
        required fanId,
        required limit,
        cursor,
      }) {
        if (first) {
          first = false;
          return Future<InstancePage>.error(StateError('first failure'));
        }
        return local.queryInstances(
          tabId: tabId,
          fanId: fanId,
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
            fanId: 'p',
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
    'stale loads and real-tab switching cannot publish stale callback data',
    (tester) async {
      final a = Completer<InstancePage>();
      final b = Completer<InstancePage>();
      final engineA = _CountingEngine(
        ({required tabId, required fanId, required limit, cursor}) => a.future,
      );
      final engineB = _CountingEngine(
        ({required tabId, required fanId, required limit, cursor}) => b.future,
      );
      final machine = _machine('stale', [
        _binding('calendar'),
        _binding('giving'),
      ]);
      Widget widget(
        WorkflowEngineApi engine,
        String tab,
        String persona,
      ) => _host(
        EngineNativeBindingDispatcher(
          engine: engine,
          definitions: {'stale': machine},
          tabId: tab,
          fanId: persona,
          builder: (_, bindings, __) => Text(
            'published-$persona-${bindings.map((b) => b.instance.instanceId).join(",")}',
          ),
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
      expect(find.text('published-B-b'), findsOneWidget);

      final staleCalendar = Completer<InstancePage>();
      final staleGiving = Completer<InstancePage>();
      final oldWithTwoTabCompletions = _CountingEngine(({
        required tabId,
        required fanId,
        required limit,
        cursor,
      }) {
        if (tabId == 'calendar') return staleCalendar.future;
        if (tabId == 'giving') return staleGiving.future;
        return Future.value(const InstancePage(items: []));
      });
      await tester.pumpWidget(
        widget(oldWithTwoTabCompletions, 'calendar', 'C'),
      );
      expect(
        find.byKey(const Key('engine-native-bindings-loading-calendar-C')),
        findsOneWidget,
      );
      await tester.pumpWidget(widget(oldWithTwoTabCompletions, 'giving', 'C'));
      await tester.pump();
      expect(
        find.byKey(const Key('engine-native-bindings-loading-giving-C')),
        findsOneWidget,
      );
      staleGiving.complete(
        InstancePage(
          items: [_instance('fresh-giving', 'stale')],
          hasMore: false,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('published-C-fresh-giving'), findsOneWidget);
      staleCalendar.complete(
        InstancePage(items: [_instance('stale-calendar', 'stale')]),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('published-C-stale-calendar'), findsNothing);
      expect(find.textContaining('published-C-fresh-giving'), findsOneWidget);
      await tester.pumpWidget(
        widget(oldWithTwoTabCompletions, 'calendar', 'C'),
      );
      expect(
        find.byKey(const Key('engine-native-bindings-loading-calendar-C')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'custom arbitrary tabId uses generic list dispatch from appShell metadata',
    (tester) async {
      const tabId = 'custom-schedule';
      const tabInstanceId = 'custom-instance-1';
      const extensionId = 'ext-a7-generic-tab-test';
      const experienceConfiguration = {
        'workflowDefinitions': {
          'schedule': {
            'workflowId': 'schedule',
            'initialState': 'open',
            'states': {
              'open': {'label': 'Open'},
            },
            'transitions': [
              {
                'id': 'complete',
                'label': 'Complete',
                'from': ['open'],
                'to': 'open',
                'guard': {
                  'allowedRoleIds': ['local-member'],
                },
              },
            ],
            'renderBindings': [
              {
                'tabId': tabId,
                'states': ['open'],
                'audience': 'any',
                'cardSurfaceFamily': 'event',
                'bindingKind': 'primary',
              },
            ],
          },
        },
        'workflowInstances': [
          {
            'instanceId': tabInstanceId,
            'workflowType': 'schedule',
            'currentState': 'open',
            'instanceData': {'title': 'Sprint planning'},
            'createdByFanId': 'owner',
          },
        ],
      };

      final experience = experienceForExtensionId(
        extensionId,
        specVersion: currentCommunitySpecVersion,
        experienceConfiguration: experienceConfiguration,
      );
      await workflowEngineForExtensionId(extensionId);
      final tabs = appShellTabsFor(
        experience: experience,
        roleId: 'local-member',
        appShellConfiguration: const {
          'tabs': [
            {'tabId': tabId, 'label': 'Custom schedule'},
          ],
        },
      );
      final customTab = tabs.singleWhere((tab) => tab.tabId == tabId);
      expect(customTab.rendererContractId, 'engine-native-generic-list');
      final persona = const LoomPersonaDefinition(
        fanId: 'local-member',
        roleId: 'local-member',
        label: 'Member',
        roleLabel: 'Member',
        description: 'Engine-native test member',
      );
      // _TabNativeRenderer is library-private to loom_communities_app_shell
      // (defined in a `part of` file) and unreachable from this test file,
      // which only imports the public barrel. Its
      // 'EngineNativeGenericListSurface' case is a direct, unconditional
      // pass-through to EngineNativeListSurface(tabId: selectedTab.tabId,
      // ...) -- see part02_tab_shell.dart -- so exercising that public
      // widget directly, with the exact same arguments the switch case
      // constructs, proves the same behavior: an arbitrary community-
      // declared tabId with no rendererContractId override renders its own
      // real instance data, not Home's content or an empty state.
      await tester.pumpWidget(
        MaterialApp(
          home: ActiveIdentityScope(
            identity: ActiveIdentityContext(
              accountId: null,
              authApi: LocalAuthApi(),
              roleId: persona.roleId,
            ),
            child: Scaffold(
              body: EngineNativeListSurface(
                experience: experience,
                persona: persona,
                tabId: customTab.tabId,
                accent: Colors.teal,
                modernTheme: null,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const Key('engine-native-list-item-$tabId-$tabInstanceId-0'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('engine-native-list-empty-$tabId')),
        findsNothing,
      );
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
        fanId: 'owner',
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
          fanId: persona,
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
        fanId: 'owner',
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

  testWidgets(
    '3+ table-bound instances with same workflow type render as one table grid',
    (tester) async {
      const tabId = 'home';
      const workflowType = 'table-rankings';
      final local = LocalWorkflowEngineApi(
        db: WorkflowDatabase.memory(),
        communityId: 'a7-table-bulk',
      );
      final tableMachine = _machine(
        workflowType,
        [_binding(tabId, cardSurfaceFamily: 'table')],
        instanceDataSchema: {
          'rank': {
            'type': 'number',
            'sortable': true,
            'searchable': true,
            'displayContexts': ['tile'],
          },
          'playerName': {
            'type': 'text',
            'sortable': true,
            'searchable': true,
            'displayContexts': ['tile'],
            'labelTemplate': 'Player',
          },
          'score': {
            'type': 'number',
            'sortable': true,
            'searchable': true,
            'displayContexts': ['tile'],
          },
          'delta': {
            'type': 'number',
            'sortable': true,
            'searchable': true,
            'displayContexts': ['tile'],
          },
        },
      );
      local.registerDefinition(tableMachine);
      final a = await local.createInstance(
        workflowType: workflowType,
        fanId: 'owner',
        initialInstanceData: {
          'rank': 1,
          'playerName': 'Alice',
          'score': 100,
          'delta': 1,
        },
      );
      final b = await local.createInstance(
        workflowType: workflowType,
        fanId: 'owner',
        initialInstanceData: {
          'rank': 2,
          'playerName': 'Bob',
          'score': 95,
          'delta': 0,
        },
      );
      final c = await local.createInstance(
        workflowType: workflowType,
        fanId: 'owner',
        initialInstanceData: {
          'rank': 3,
          'playerName': 'Cara',
          'score': 80,
          'delta': -1,
        },
      );
      local.registerDefinition(tableMachine);

      final experience = experienceForExtensionId(
        'ext-a7-table-bulk',
        specVersion: currentCommunitySpecVersion,
        experienceConfiguration: {
          'workflowDefinitions': {
            workflowType: {
              'workflowId': workflowType,
              'initialState': 'open',
              'states': {
                'open': {'label': 'Open'},
              },
              'transitions': <dynamic>[],
              'instanceDataSchema': {
                'rank': {
                  'type': 'number',
                  'sortable': true,
                  'searchable': true,
                  'displayContexts': ['tile'],
                },
                'playerName': {
                  'type': 'text',
                  'sortable': true,
                  'searchable': true,
                  'displayContexts': ['tile'],
                  'labelTemplate': 'Player',
                },
                'score': {
                  'type': 'number',
                  'sortable': true,
                  'searchable': true,
                  'displayContexts': ['tile'],
                },
                'delta': {
                  'type': 'number',
                  'sortable': true,
                  'searchable': true,
                  'displayContexts': ['tile'],
                },
              },
              'renderBindings': [_binding(tabId, cardSurfaceFamily: 'table')],
            },
          },
          'workflowInstances': [
            {
              'instanceId': a,
              'workflowType': workflowType,
              'currentState': 'open',
              'instanceData': {
                'rank': 1,
                'playerName': 'Alice',
                'score': 100,
                'delta': 1,
              },
              'createdByFanId': 'owner',
            },
            {
              'instanceId': b,
              'workflowType': workflowType,
              'currentState': 'open',
              'instanceData': {
                'rank': 2,
                'playerName': 'Bob',
                'score': 95,
                'delta': 0,
              },
              'createdByFanId': 'owner',
            },
            {
              'instanceId': c,
              'workflowType': workflowType,
              'currentState': 'open',
              'instanceData': {
                'rank': 3,
                'playerName': 'Cara',
                'score': 80,
                'delta': -1,
              },
              'createdByFanId': 'owner',
            },
          ],
        },
      );
      const persona = LoomPersonaDefinition(
        fanId: 'local-member',
        roleId: 'local-member',
        label: 'Member',
        roleLabel: 'Member',
        description: 'Test member',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ActiveIdentityScope(
            identity: ActiveIdentityContext(
              accountId: null,
              authApi: LocalAuthApi(),
              roleId: persona.roleId,
            ),
            child: Scaffold(
              body: EngineNativeListSurface(
                experience: experience,
                persona: persona,
                tabId: tabId,
                accent: Colors.teal,
                modernTheme: null,
                engine: local,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(ValueKey('engine-native-table-$tabId-$workflowType')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('workflow-table-row-$tabId-$workflowType-$a-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('workflow-table-row-$tabId-$workflowType-$b-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('workflow-table-row-$tabId-$workflowType-$c-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('engine-native-list-item-$tabId-$a-0')),
        findsNothing,
      );
      expect(find.byType(WorkflowTableArchetypeCard), findsOneWidget);
    },
  );

  testWidgets(
    'mixed table and non-table bindings on same tab render both table grid and cards',
    (tester) async {
      const tabId = 'home';
      const tableType = 'table-rankings';
      const eventType = 'calendar-announcement';
      final local = LocalWorkflowEngineApi(
        db: WorkflowDatabase.memory(),
        communityId: 'a7-table-mixed',
      );
      final tableMachine = _machine(
        tableType,
        [_binding(tabId, cardSurfaceFamily: 'table')],
        instanceDataSchema: {
          'rank': {
            'type': 'number',
            'sortable': true,
            'searchable': true,
            'displayContexts': ['tile'],
          },
          'title': {
            'type': 'text',
            'searchable': true,
            'displayContexts': ['tile'],
          },
        },
      );
      final eventMachine = _machine(
        eventType,
        [_binding(tabId)],
        instanceDataSchema: {
          'title': {
            'type': 'text',
            'labelTemplate': 'Announcement',
            'displayContexts': ['tile'],
          },
        },
      );
      local.registerDefinition(tableMachine);
      local.registerDefinition(eventMachine);
      await local.createInstance(
        workflowType: tableType,
        fanId: 'owner',
        initialInstanceData: {'rank': 1, 'title': 'East'},
      );
      final nonTable = await local.createInstance(
        workflowType: eventType,
        fanId: 'owner',
        initialInstanceData: {'title': 'General meeting'},
      );
      await local.createInstance(
        workflowType: tableType,
        fanId: 'owner',
        initialInstanceData: {'rank': 2, 'title': 'West'},
      );

      final experience = experienceForExtensionId(
        'ext-a7-table-mixed',
        specVersion: currentCommunitySpecVersion,
        experienceConfiguration: {
          'workflowDefinitions': {
            tableType: {
              'workflowId': tableType,
              'initialState': 'open',
              'states': {
                'open': {'label': 'Open'},
              },
              'transitions': <dynamic>[],
              'instanceDataSchema': {
                'rank': {
                  'type': 'number',
                  'sortable': true,
                  'searchable': true,
                  'displayContexts': ['tile'],
                },
                'title': {
                  'type': 'text',
                  'searchable': true,
                  'displayContexts': ['tile'],
                },
              },
              'renderBindings': [_binding(tabId, cardSurfaceFamily: 'table')],
            },
            eventType: {
              'workflowId': eventType,
              'initialState': 'open',
              'states': {
                'open': {'label': 'Open'},
              },
              'transitions': <dynamic>[],
              'instanceDataSchema': {
                'title': {
                  'type': 'text',
                  'labelTemplate': 'Announcement',
                  'displayContexts': ['tile'],
                },
              },
              'renderBindings': [_binding(tabId)],
            },
          },
        },
      );
      const persona = LoomPersonaDefinition(
        fanId: 'local-member',
        roleId: 'local-member',
        label: 'Member',
        roleLabel: 'Member',
        description: 'Test member',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ActiveIdentityScope(
            identity: ActiveIdentityContext(
              accountId: null,
              authApi: LocalAuthApi(),
              roleId: persona.roleId,
            ),
            child: Scaffold(
              body: EngineNativeListSurface(
                experience: experience,
                persona: persona,
                tabId: tabId,
                accent: Colors.teal,
                modernTheme: null,
                engine: local,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(ValueKey('engine-native-table-$tabId-$tableType')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('engine-native-list-item-$tabId-$nonTable-0')),
        findsOneWidget,
      );
      expect(find.byType(WorkflowTableArchetypeCard), findsNWidgets(1));
      expect(find.byType(EngineNativeArchetypeCard), findsOneWidget);
    },
  );
}
