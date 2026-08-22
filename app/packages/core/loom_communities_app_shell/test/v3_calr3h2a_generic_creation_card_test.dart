import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

LoomWorkflowStateMachine _machine() => LoomWorkflowStateMachine.fromJson({
  'initialState': 'draft',
  'states': {
    'draft': {
      'label': 'Draft',
      'editableFields': ['title', 'published', 'eventDate', 'capacity'],
    },
  },
  'transitions': const <Map<String, dynamic>>[],
  'instanceDataSchema': {
    'title': {
      'type': 'text',
      'required': true,
      'labelTemplate': 'Title: {value}',
    },
    'published': {'type': 'bool'},
    'eventDate': {'type': 'date'},
    'capacity': {'type': 'number', 'labelTemplate': 'Capacity'},
  },
}, 'test-creation');

LoomWorkflowStateMachine _conditionalMachine() =>
    LoomWorkflowStateMachine.fromJson({
      'initialState': 'draft',
      'states': {
        'draft': {
          'label': 'Draft',
          'editableFields': [
            'allDay',
            'eventTime',
            'locationType',
            'videoLink',
          ],
        },
      },
      'transitions': const <Map<String, dynamic>>[],
      'instanceDataSchema': {
        'allDay': {'type': 'bool'},
        'eventTime': {
          'type': 'time',
          'visibleWhenEditing': '!(allDay == true)',
        },
        'locationType': {'type': 'text'},
        'videoLink': {
          'type': 'text',
          'visibleWhenEditing': "locationType == 'video'",
        },
      },
    }, 'conditional-creation');

Future<LocalWorkflowEngineApi> _engine() async {
  final engine = LocalWorkflowEngineApi(
    db: WorkflowDatabase.memory(),
    communityId: 'creation-card-test',
  );
  engine.registerDefinition(_machine());
  return engine;
}

Widget _host(GenericWorkflowCreationCard card) =>
    MaterialApp(home: Scaffold(body: card));

void main() {
  testWidgets('creates an instance and calls onCreated', (tester) async {
    final engine = await _engine();
    String? createdId;
    await tester.pumpWidget(
      _host(
        GenericWorkflowCreationCard(
          workflowType: 'test-creation',
          machine: _machine(),
          engine: engine,
          fanId: 'member',
          keyPrefix: 'new-item',
          onCreated: (instanceId) async => createdId = instanceId,
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('new-item-editor-published')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('new-item-editor-eventDate')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('new-item-editor-title')),
      'Board meeting',
    );
    await tester.tap(find.byKey(const ValueKey('new-item-submit')));
    await tester.pumpAndSettle();

    final instances = await engine.queryInstances(
      tabId: 'test',
      fanId: 'member',
    );
    expect(instances.items, hasLength(1));
    expect(instances.items.single.instanceData['title'], 'Board meeting');
    expect(instances.items.single.instanceData, isNot(contains('published')));
    expect(instances.items.single.instanceData, isNot(contains('eventDate')));
    expect(instances.items.single.instanceData, isNot(contains('capacity')));
    expect(createdId, instances.items.single.instanceId);
  });

  testWidgets('shows required-field validation without creating', (
    tester,
  ) async {
    final engine = await _engine();
    await tester.pumpWidget(
      _host(
        GenericWorkflowCreationCard(
          workflowType: 'test-creation',
          machine: _machine(),
          engine: engine,
          fanId: 'member',
          keyPrefix: 'new-item',
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('new-item-submit')));
    await tester.pump();

    expect(find.byKey(const ValueKey('new-item-error')), findsOneWidget);
    expect(find.text('Title is required.'), findsOneWidget);
    final instances = await engine.queryInstances(
      tabId: 'test',
      fanId: 'member',
    );
    expect(instances.items, isEmpty);
  });

  testWidgets('does not mangle plain labels without trailing punctuation', (
    tester,
  ) async {
    final engine = await _engine();
    await tester.pumpWidget(
      _host(
        GenericWorkflowCreationCard(
          workflowType: 'test-creation',
          machine: _machine(),
          engine: engine,
          fanId: 'member',
          keyPrefix: 'new-item',
        ),
      ),
    );

    // The 'Capacity' labelTemplate has no trailing colon/dash, so the
    // label must appear exactly as-is — not stripped or range-mangled.
    expect(find.text('Capacity'), findsOneWidget);
  });

  testWidgets('re-evaluates editing visibility from the creation values', (
    tester,
  ) async {
    final engine = LocalWorkflowEngineApi(
      db: WorkflowDatabase.memory(),
      communityId: 'conditional-creation-card-test',
    );
    final machine = _conditionalMachine();
    engine.registerDefinition(machine);
    await tester.pumpWidget(
      _host(
        GenericWorkflowCreationCard(
          workflowType: 'conditional-creation',
          machine: machine,
          engine: engine,
          fanId: 'member',
          keyPrefix: 'conditional',
        ),
      ),
    );

    final allDay = find.byKey(const ValueKey('conditional-editor-allDay'));
    final eventTime = find.byKey(
      const ValueKey('conditional-editor-eventTime'),
    );
    final locationType = find.byKey(
      const ValueKey('conditional-editor-locationType'),
    );
    final videoLink = find.byKey(
      const ValueKey('conditional-editor-videoLink'),
    );
    expect(eventTime, findsOneWidget);
    expect(videoLink, findsNothing);

    await tester.tap(allDay);
    await tester.pump();
    expect(eventTime, findsNothing);
    await tester.tap(allDay);
    await tester.pump();
    expect(eventTime, findsOneWidget);

    await tester.enterText(locationType, 'video');
    await tester.pump();
    expect(videoLink, findsOneWidget);
    await tester.enterText(locationType, 'in person');
    await tester.pump();
    expect(videoLink, findsNothing);
  });
}
