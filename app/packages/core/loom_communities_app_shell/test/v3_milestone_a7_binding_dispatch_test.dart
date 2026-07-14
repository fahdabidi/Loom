import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

LoomWorkflowStateMachine _machine() => LoomWorkflowStateMachine.fromJson({
  'initialState': 'open',
  'states': {
    'open': {'label': 'Open'},
    'closed': {'label': 'Closed'},
  },
  'transitions': [],
  'renderBindings': [
    {
      'tabId': 'calendar',
      'states': ['open'],
      'role': 'member',
      'cardSurfaceFamily': 'event',
      'bindingKind': 'primary',
    },
    {
      'tabId': 'calendar',
      'states': ['open'],
      'role': 'organizer',
      'cardSurfaceFamily': 'event',
      'bindingKind': 'summary',
    },
    {
      'tabId': 'home',
      'states': ['open'],
      'role': 'any',
      'cardSurfaceFamily': 'event',
      'bindingKind': 'primary',
    },
  ],
}, 'event');

class _CountingEngine implements WorkflowEngineApi {
  _CountingEngine(this.delegate);
  final WorkflowEngineApi delegate;
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
    return delegate.queryInstances(
      tabId: tabId,
      personaId: personaId,
      query: query,
      limit: limit,
      cursor: cursor,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('Calendar resolves every matching binding across real pages', (
    tester,
  ) async {
    final engine = LocalWorkflowEngineApi(
      db: WorkflowDatabase.memory(),
      communityId: 'a7',
    );
    final machine = _machine();
    engine.registerDefinition(machine);
    for (final title in ['A', 'B', 'C']) {
      await engine.createInstance(
        workflowType: 'event',
        personaId: 'owner',
        initialInstanceData: {'title': title},
      );
    }
    final counting = _CountingEngine(engine);
    List<String> identities = [];
    await tester.pumpWidget(
      _host(
        EngineNativeBindingDispatcher(
          engine: counting,
          definitions: {'event': machine},
          tabId: 'calendar',
          personaId: 'p',
          pageSize: 1,
          rolesForInstance: (_, __) => ['member', 'organizer'],
          builder: (_, bindings, __) {
            identities = bindings.map((binding) => binding.identity).toList();
            return Text(identities.join('|'));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(counting.queries, greaterThan(1));
    expect(identities, hasLength(6));
    expect(identities, everyElement(contains('calendar::')));
    expect(identities.toSet(), hasLength(6));
  });

  testWidgets('unsupported tabs succeed empty without an engine query', (
    tester,
  ) async {
    final engine = LocalWorkflowEngineApi(
      db: WorkflowDatabase.memory(),
      communityId: 'a7-disabled',
    );
    final counting = _CountingEngine(engine);
    var received = -1;
    await tester.pumpWidget(
      _host(
        EngineNativeBindingDispatcher(
          engine: counting,
          definitions: const {},
          tabId: 'home',
          personaId: 'p',
          builder: (_, bindings, __) {
            received = bindings.length;
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pump();

    expect(received, 0);
    expect(counting.queries, 0);
    expect(
      find.byKey(const Key('engine-native-bindings-empty-home-p')),
      findsOneWidget,
    );
  });
}
