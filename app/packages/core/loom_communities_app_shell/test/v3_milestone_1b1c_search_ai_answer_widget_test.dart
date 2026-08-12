import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

Future<(LocalWorkflowEngineApi, WorkflowInstance, EngineNativeResolvedBinding)>
_seedSearchAiAnswerFixture({
  required Map<String, dynamic> instanceDataSchema,
  required Map<String, dynamic> initialInstanceData,
  List<Map<String, dynamic>> transitions = const [],
}) async {
  final api = LocalWorkflowEngineApi(
    db: WorkflowDatabase.memory(),
    communityId: 'search-ai-answer-fixture',
  );
  final machine = LoomWorkflowStateMachine.fromJson({
    'initialState': 'open',
    'states': {
      'open': {'label': 'Open'},
    },
    'transitions': transitions,
    'instanceDataSchema': instanceDataSchema,
  }, 'searchAiAnswer');

  api.registerDefinition(machine);
  final id = await api.createInstance(
    workflowType: 'searchAiAnswer',
    personaId: 'member',
    initialInstanceData: initialInstanceData,
  );
  final resolved = RenderBinding(
    tabId: 'search',
    states: const ['open'],
    role: 'member',
    cardSurfaceFamily: 'searchAiAnswer',
    bindingKind: 'primary',
  );
  final instance = (await api.queryInstances(
    tabId: 'search',
    personaId: 'member',
  ))
      .items
      .firstWhere((row) => row.instanceId == id);

  return (
    api,
    instance,
    EngineNativeResolvedBinding(
      instance: instance,
      machine: machine,
      binding: resolved,
      definitionBindingIndex: 0,
    ),
  );
}

void main() {
  testWidgets('searchAiAnswer chooses one answer field for formula-first case', (
    tester,
  ) async {
    final (
      api,
      instance,
      resolved,
    ) = await _seedSearchAiAnswerFixture(
      instanceDataSchema: {
        'query': {
          'type': 'text',
          'required': true,
          'displayContexts': ['tile', 'detail'],
          'labelTemplate': 'Query: {value}',
        },
        'aiAnswerBody': {
          'type': 'textarea?',
          'writableBy': 'effect',
          'labelTemplate': 'AI answer: {value}',
          'displayContexts': ['detail'],
          'hideWhenEmpty': true,
        },
        'curatedAnswerBody': {
          'type': 'textarea?',
          'writableBy': 'effect',
          'labelTemplate': 'Curated answer: {value}',
          'displayContexts': ['tile', 'detail'],
          'hideWhenEmpty': true,
        },
        'displayAnswer': {
          'type': 'textarea?',
          'formula':
              'if(curatedAnswerBody == null, aiAnswerBody, curatedAnswerBody)',
          'labelTemplate': 'Answer: {value}',
          'displayContexts': ['tile', 'detail'],
          'hideWhenEmpty': true,
        },
        'citations': {
          'type': 'list',
          'writableBy': 'effect',
          'itemSchema': {
            'label': {'type': 'text', 'labelTemplate': '{value}'},
            'source': {'type': 'url', 'openMode': 'external'},
          },
          'displayContexts': ['tile', 'detail'],
          'labelTemplate': 'Sources: {value.length}',
        },
      },
      initialInstanceData: {
        'query': 'What is the best prayer time in 2026?',
        'aiAnswerBody': 'Draft from model',
        'curatedAnswerBody': 'Admin curated',
        // displayAnswer is a formula field ("Computed fields cannot be
        // seeded" -- confirmed via LocalWorkflowEngineApi._validateSeedData)
        // -- the engine computes it from curatedAnswerBody/aiAnswerBody.
        'citations': [
          {'label': 'Mosque site', 'source': 'https://example.org/mosque'},
        ],
      },
    );

    await tester.pumpWidget(
      _host(
        EngineNativeArchetypeCard(
          contentKey: ValueKey('search-ai-answer-test-${instance.instanceId}'),
          resolved: resolved,
          engine: api,
          communityExtensionId: 'search-ai-answer',
          personaId: 'member',
          accent: Colors.green,
          onInstanceChanged: (_) {},
          displayContext: 'tile',
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.byKey(ValueKey('search-ai-answer-query-${instance.instanceId}-tile')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('search-ai-answer-answer-${instance.instanceId}-tile')),
      findsOneWidget,
    );
    // displayAnswer's formula (if(curatedAnswerBody == null, aiAnswerBody,
    // curatedAnswerBody)) resolves to curatedAnswerBody since it is non-null.
    expect(find.text('Answer: Admin curated'), findsOneWidget);
    expect(find.text('AI answer: Draft from model'), findsNothing);
    expect(find.text('Curated answer: Admin curated'), findsNothing);
    expect(
      find.byKey(ValueKey('workflow-fact-list-url-citations-0-source')),
      findsOneWidget,
    );
  });

  testWidgets(
    'searchAiAnswer prefers curatedSummary over empty platform answer field',
    (tester) async {
      final (
        api,
        instance,
        resolved,
      ) = await _seedSearchAiAnswerFixture(
        instanceDataSchema: {
          'query': {
            'type': 'text',
            'required': true,
            'displayContexts': ['tile', 'detail'],
            'labelTemplate': 'Query: {value}',
          },
          'answer': {
            'type': 'textarea?',
            'writableBy': 'platform-service',
            'labelTemplate': 'answer: {value}',
            'displayContexts': ['detail'],
            'hideWhenEmpty': true,
          },
          'curatedSummary': {
            'type': 'textarea',
            'writableBy': 'formEntry',
            'labelTemplate': 'curated: {value}',
            'displayContexts': ['tile', 'detail'],
            'hideWhenEmpty': true,
          },
          'citations': {
            'type': 'list',
            'writableBy': 'effect',
            'itemSchema': {
              'label': {'type': 'text', 'labelTemplate': '{value}'},
              'source': {'type': 'url', 'openMode': 'external'},
            },
            'displayContexts': ['tile', 'detail'],
            'labelTemplate': 'Sources: {value.length}',
          },
        },
        initialInstanceData: {
          'query': 'Book club digest title',
          'answer': '',
          'curatedSummary': 'Curated digest summary',
          'citations': <dynamic>[],
        },
      );

      await tester.pumpWidget(
        _host(
          EngineNativeArchetypeCard(
            contentKey: ValueKey('search-ai-answer-book-${instance.instanceId}'),
            resolved: resolved,
            engine: api,
            communityExtensionId: 'search-ai-answer',
            personaId: 'member',
            accent: Colors.green,
            onInstanceChanged: (_) {},
            displayContext: 'tile',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(
          ValueKey('search-ai-answer-answer-${instance.instanceId}-tile'),
        ),
        findsOneWidget,
      );
      expect(find.text('answer:'), findsNothing);
      expect(find.text('Answer: Curated digest summary'), findsOneWidget);
    });

  testWidgets('searchAiAnswer shows waiting state when answer field is unset', (
    tester,
  ) async {
    final (
      api,
      instance,
      resolved,
    ) = await _seedSearchAiAnswerFixture(
      instanceDataSchema: {
        'query': {
          'type': 'text',
          'required': true,
          'displayContexts': ['tile', 'detail'],
          'labelTemplate': 'Query: {value}',
        },
        'answer': {
          'type': 'textarea?',
          'writableBy': 'platform-service',
          'labelTemplate': 'answer: {value}',
          'displayContexts': ['detail'],
          'hideWhenEmpty': true,
        },
        'curatedSummary': {
          'type': 'textarea',
          'writableBy': 'formEntry',
          'labelTemplate': 'curated: {value}',
          'displayContexts': ['tile', 'detail'],
          'hideWhenEmpty': true,
        },
      },
      initialInstanceData: {'query': 'Pending digest'},
    );

    await tester.pumpWidget(
      _host(
        EngineNativeArchetypeCard(
          contentKey: ValueKey('search-ai-answer-empty-${instance.instanceId}'),
          resolved: resolved,
          engine: api,
          communityExtensionId: 'search-ai-answer',
          personaId: 'member',
          accent: Colors.green,
          onInstanceChanged: (_) {},
          displayContext: 'tile',
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.byKey(
        ValueKey('search-ai-answer-waiting-${instance.instanceId}-tile'),
      ),
      findsOneWidget,
    );
    expect(find.text('Waiting for an answer'), findsOneWidget);
    expect(
      find.byKey(
        ValueKey('search-ai-answer-answer-${instance.instanceId}-tile'),
      ),
      findsNothing,
    );
  });
}
