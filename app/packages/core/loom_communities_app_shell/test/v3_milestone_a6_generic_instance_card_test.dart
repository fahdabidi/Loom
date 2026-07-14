import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

LoomWorkflowStateMachine _machine() => LoomWorkflowStateMachine.fromJson({
  'initialState': 'open',
  'states': {
    'open': {
      'label': 'Open',
      'editableFields': [
        'text',
        'notes',
        'day',
        'at',
        'enabled',
        'amount',
        'computed',
        'effectOnly',
      ],
    },
    'done': {
      'label': 'Done',
      'isTerminal': true,
      'editableFields': ['text', 'amount'],
    },
  },
  'transitions': [
    {
      'id': 'finish',
      'label': 'Finish',
      'icon': 'check',
      'from': ['open'],
      'to': 'done',
      'effects': [
        {'op': 'set', 'key': 'receipt', 'value': 'saved'},
        {'op': 'set', 'key': 'text', 'value': 'transition text'},
        {'op': 'set', 'key': 'amount', 'value': 9},
      ],
    },
  ],
  'instanceDataSchema': {
    'title': {
      'type': 'text',
      'displayIcon': 'title',
      'labelTemplate': '{value}',
      'displayContexts': ['tile'],
    },
    'members': {
      'type': 'list',
      'displayIcon': 'groups_outlined',
      'labelTemplate': 'Members: {value.length}',
      'displayContexts': ['detail'],
    },
    'blank': {
      'type': 'text',
      'labelTemplate': '{value}',
      'hideWhenEmpty': true,
    },
    'nothing': {
      'type': 'text',
      'labelTemplate': 'Nothing: {value}',
      'hideWhenEmpty': true,
    },
    'noItems': {
      'type': 'list',
      'labelTemplate': 'Items: {value.length}',
      'hideWhenEmpty': true,
    },
    'noMap': {
      'type': 'map',
      'labelTemplate': 'Map: {value}',
      'hideWhenEmpty': true,
    },
    'enabledDisplay': {'type': 'bool', 'labelTemplate': 'Enabled: {value}'},
    'zero': {'type': 'number', 'labelTemplate': 'Zero: {value}'},
    'text': {'type': 'text'},
    'notes': {'type': 'textarea'},
    'day': {'type': 'date', 'labelTemplate': 'Date: {value}'},
    'at': {'type': 'time'},
    'enabled': {'type': 'bool'},
    'amount': {'type': 'number'},
    'computed': {'type': 'text', 'formula': 'text'},
    'effectOnly': {'type': 'text', 'writableBy': 'effect'},
    'receipt': {'type': 'text'},
  },
}, 'generic-test');

Future<(LocalWorkflowEngineApi, WorkflowInstance)> _seed() async {
  final api = LocalWorkflowEngineApi(
    db: WorkflowDatabase.memory(),
    communityId: 'a6',
  );
  api.registerDefinition(_machine());
  final id = await api.createInstance(
    workflowType: 'generic-test',
    personaId: 'person',
    initialInstanceData: {
      'title': 'One card',
      'members': ['a', 'b'],
      'blank': ' ',
      'nothing': null,
      'noItems': <String>[],
      'noMap': <String, dynamic>{},
      'enabledDisplay': false,
      'zero': 0,
      'text': 'old',
      'notes': 'old notes',
      'day': '2026-07-14',
      'at': '09:30',
      'enabled': false,
      'amount': 2,
    },
  );
  final row = (await api.queryInstances(
    tabId: 'any',
    personaId: 'person',
  )).items.singleWhere((item) => item.instanceId == id);
  return (api, row);
}

/// Delegates real persistence while allowing individual asynchronous seams to
/// be held by lifecycle tests.
class _ControlledEngine implements WorkflowEngineApi {
  _ControlledEngine(this.delegate);
  final WorkflowEngineApi delegate;
  final List<Completer<List<LoomWorkflowTransition>>> actionCompleters = [];
  Completer<void>? updateCompleter;
  int updateCalls = 0;
  bool failNextActions = false;

  @override
  Future<List<LoomWorkflowTransition>> availableTransitionsAsync({
    required String workflowType,
    required String instanceId,
    required String currentState,
    required Map<String, dynamic> instanceData,
    required String personaId,
  }) {
    if (failNextActions) {
      failNextActions = false;
      return Future<List<LoomWorkflowTransition>>.error(
        StateError('load failed'),
      );
    }
    final completer = Completer<List<LoomWorkflowTransition>>();
    actionCompleters.add(completer);
    return completer.future;
  }

  @override
  Future<void> updateInstanceFields({
    required String workflowType,
    required String instanceId,
    required Map<String, dynamic> fieldUpdates,
    required String personaId,
  }) async {
    updateCalls++;
    final held = updateCompleter;
    if (held != null) await held.future;
    await delegate.updateInstanceFields(
      workflowType: workflowType,
      instanceId: instanceId,
      fieldUpdates: fieldUpdates,
      personaId: personaId,
    );
  }

  @override
  Future<InstancePage> queryInstances({
    required String tabId,
    required String personaId,
    SurfaceQuery query = const SurfaceQuery.empty(),
    int limit = 25,
    String? cursor,
  }) => delegate.queryInstances(
    tabId: tabId,
    personaId: personaId,
    query: query,
    limit: limit,
    cursor: cursor,
  );
  @override
  List<LoomWorkflowTransition> availableTransitions({
    required String workflowType,
    required String instanceId,
    required String currentState,
    required Map<String, dynamic> instanceData,
    required String personaId,
  }) => delegate.availableTransitions(
    workflowType: workflowType,
    instanceId: instanceId,
    currentState: currentState,
    instanceData: instanceData,
    personaId: personaId,
  );
  @override
  Future<WorkflowTransitionResult> applyTransition({
    required String workflowType,
    required String instanceId,
    required String transitionId,
    required String personaId,
  }) => delegate.applyTransition(
    workflowType: workflowType,
    instanceId: instanceId,
    transitionId: transitionId,
    personaId: personaId,
  );
  @override
  Future<String> createInstance({
    required String workflowType,
    required Map<String, dynamic> initialInstanceData,
    required String personaId,
  }) => delegate.createInstance(
    workflowType: workflowType,
    initialInstanceData: initialInstanceData,
    personaId: personaId,
  );
  @override
  Future<dynamic> aggregate({
    required String workflowType,
    required String column,
    required String op,
    Map<String, dynamic>? filter,
    String? groupBy,
  }) => delegate.aggregate(
    workflowType: workflowType,
    column: column,
    op: op,
    filter: filter,
    groupBy: groupBy,
  );
  @override
  Future<List<WorkflowInstance>> dueNotifications({required DateTime asOf}) =>
      delegate.dueNotifications(asOf: asOf);
}

GenericWorkflowInstanceCard _card(
  LocalWorkflowEngineApi api,
  WorkflowInstance instance, {
  String context = 'tile',
  String persona = 'person',
}) => GenericWorkflowInstanceCard(
  instance: instance,
  machine: _machine(),
  engine: api,
  personaId: persona,
  displayContext: context,
);

void main() {
  testWidgets(
    'renders display schema across contexts without empty false or zero loss',
    (tester) async {
      final (api, instance) = await _seed();
      await tester.pumpWidget(_host(_card(api, instance)));
      await tester.pump();
      expect(find.text('One card'), findsOneWidget);
      expect(find.text('Enabled: false'), findsOneWidget);
      expect(find.text('Zero: 0'), findsOneWidget);
      expect(find.text('Members: 2'), findsNothing);
      expect(find.byIcon(Icons.title), findsOneWidget);
      for (final key in ['blank', 'nothing', 'noItems', 'noMap', 'members']) {
        expect(
          find.byKey(
            ValueKey('generic-instance-field-${instance.instanceId}-$key'),
          ),
          findsNothing,
        );
      }

      await tester.pumpWidget(_host(_card(api, instance, context: 'detail')));
      await tester.pump();
      expect(find.text('Members: 2'), findsOneWidget);
      expect(find.text('One card'), findsNothing);
      for (final key in ['blank', 'nothing', 'noItems', 'noMap', 'title']) {
        expect(
          find.byKey(
            ValueKey('generic-instance-field-${instance.instanceId}-$key'),
          ),
          findsNothing,
        );
      }
    },
  );

  testWidgets(
    'typed editors write through the real engine and reject invalid numbers',
    (tester) async {
      final (api, instance) = await _seed();
      await tester.pumpWidget(_host(_card(api, instance)));
      await tester.pump();
      for (final key in ['text', 'notes', 'day', 'at', 'enabled', 'amount']) {
        expect(
          find.byKey(
            ValueKey('generic-instance-editor-${instance.instanceId}-$key'),
          ),
          findsOneWidget,
        );
      }
      await tester.enterText(
        find.byKey(
          ValueKey('generic-instance-editor-${instance.instanceId}-text'),
        ),
        'new text',
      );
      await tester.enterText(
        find.byKey(
          ValueKey('generic-instance-editor-${instance.instanceId}-notes'),
        ),
        'new notes',
      );
      await tester.enterText(
        find.byKey(
          ValueKey('generic-instance-editor-${instance.instanceId}-amount'),
        ),
        '7.5',
      );
      final day = find.byKey(
        ValueKey('generic-instance-editor-${instance.instanceId}-day'),
      );
      await tester.ensureVisible(day);
      await tester.tap(day);
      await tester.pumpAndSettle();
      await tester.tap(find.text('15').last);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      final at = find.byKey(
        ValueKey('generic-instance-editor-${instance.instanceId}-at'),
      );
      await tester.ensureVisible(at);
      await tester.tap(at);
      await tester.pumpAndSettle();
      // Select 10:45 on the real Material clock face.  Clock labels are
      // locale/layout dependent in the test environment, so use its stable
      // dial positions rather than synthetic picker state.
      await tester.tapAt(const Offset(320, 270));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(270, 330));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      final enabled = find.byKey(
        ValueKey('generic-instance-editor-${instance.instanceId}-enabled'),
      );
      await tester.ensureVisible(enabled);
      await tester.tap(enabled);
      final save = find.byKey(
        ValueKey('generic-instance-save-${instance.instanceId}'),
      );
      await tester.ensureVisible(save);
      expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
      await tester.tap(save);
      await tester.pump();
      final after = (await api.queryInstances(
        tabId: 'any',
        personaId: 'person',
      )).items.single;
      expect(after.instanceData['text'], 'new text');
      expect(after.instanceData['notes'], 'new notes');
      expect(after.instanceData['amount'], 7.5);
      expect(after.instanceData['enabled'], isTrue);
      expect(after.instanceData['day'], '2026-07-15');
      expect(after.instanceData['at'], '21:30');
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(
          ValueKey('generic-instance-editor-${instance.instanceId}-amount'),
        ),
        'not-a-number',
      );
      await tester.pump();
      await tester.ensureVisible(save);
      expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
      await tester.tap(save);
      await tester.pump();
      expect(find.text('Enter a valid number.'), findsOneWidget);
      expect(
        (await api.queryInstances(
          tabId: 'any',
          personaId: 'person',
        )).items.single.instanceData['amount'],
        7.5,
      );
    },
  );

  testWidgets(
    'text-only edits enable Save immediately and transition resyncs editors',
    (tester) async {
      final (api, instance) = await _seed();
      await tester.pumpWidget(_host(_card(api, instance)));
      await tester.pump();
      final text = find.byKey(
        ValueKey('generic-instance-editor-${instance.instanceId}-text'),
      );
      final save = find.byKey(
        ValueKey('generic-instance-save-${instance.instanceId}'),
      );
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      await tester.enterText(text, 'text only');
      await tester.pump();
      expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(
        (await api.queryInstances(
          tabId: 'any',
          personaId: 'person',
        )).items.single.instanceData['text'],
        'text only',
      );

      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();
      expect(find.text('transition text'), findsOneWidget);
      expect(
        tester.widget<TextField>(text).controller!.text,
        'transition text',
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(
                ValueKey(
                  'generic-instance-editor-${instance.instanceId}-amount',
                ),
              ),
            )
            .controller!
            .text,
        '9',
      );
    },
  );

  testWidgets(
    'related-list guarded asynchronous action persists and refreshes',
    (tester) async {
      final api = LocalWorkflowEngineApi(
        db: WorkflowDatabase.memory(),
        communityId: 'guard',
      );
      final event = LoomWorkflowStateMachine.fromJson({
        'initialState': 'open',
        'states': {
          'open': {'label': 'Open'},
        },
        'transitions': <dynamic>[],
        'instanceDataSchema': {
          'allowed': {'type': 'list'},
        },
      }, 'event');
      final vote = LoomWorkflowStateMachine.fromJson({
        'initialState': 'open',
        'states': {
          'open': {'label': 'Open'},
          'cast': {'label': 'Cast', 'isTerminal': true},
        },
        'transitions': [
          {
            'id': 'cast',
            'label': 'Cast vote',
            'from': ['open'],
            'to': 'cast',
            'effects': [
              {'op': 'set', 'key': 'result', 'value': 'cast'},
            ],
            'guard': {
              'relatedInstanceField': 'eventId',
              'relatedListField': 'allowed',
            },
          },
        ],
        'instanceDataSchema': {
          'eventId': {'type': 'text'},
          'result': {'type': 'text'},
        },
      }, 'vote');
      api
        ..registerDefinition(event)
        ..registerDefinition(vote);
      final eventId = await api.createInstance(
        workflowType: 'event',
        personaId: 'host',
        initialInstanceData: {
          'allowed': ['allowed'],
        },
      );
      final voteId = await api.createInstance(
        workflowType: 'vote',
        personaId: 'host',
        initialInstanceData: {'eventId': eventId},
      );
      final instance = (await api.queryInstances(
        tabId: 'any',
        personaId: 'allowed',
      )).items.singleWhere((row) => row.instanceId == voteId);
      await tester.pumpWidget(
        _host(
          GenericWorkflowInstanceCard(
            instance: instance,
            machine: vote,
            engine: api,
            personaId: 'denied',
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Cast vote'), findsNothing);
      await tester.pumpWidget(
        _host(
          GenericWorkflowInstanceCard(
            instance: instance,
            machine: vote,
            engine: api,
            personaId: 'allowed',
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Cast vote'), findsOneWidget);
      await tester.tap(find.text('Cast vote'));
      await tester.pump();
      final after = (await api.queryInstances(
        tabId: 'any',
        personaId: 'allowed',
      )).items.singleWhere((row) => row.instanceId == voteId);
      expect(after.currentState, 'cast');
      expect(after.instanceData['result'], 'cast');
      expect(find.text('Cast vote'), findsNothing);
    },
  );

  testWidgets('stable picker labels and non-writable editor filtering', (
    tester,
  ) async {
    final (api, instance) = await _seed();
    await tester.pumpWidget(_host(_card(api, instance)));
    await tester.pump();
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(
              ValueKey('generic-instance-editor-${instance.instanceId}-day'),
            ),
          )
          .child,
      isA<Text>().having((text) => text.data, 'stable label', 'Date'),
    );
    for (final key in ['computed', 'effectOnly']) {
      expect(
        find.byKey(
          ValueKey('generic-instance-editor-${instance.instanceId}-$key'),
        ),
        findsNothing,
      );
    }
  });

  testWidgets('fresh malformed number cannot write through the real engine', (
    tester,
  ) async {
    final (api, instance) = await _seed();
    await tester.pumpWidget(_host(_card(api, instance)));
    await tester.pump();
    final amount = find.byKey(
      ValueKey('generic-instance-editor-${instance.instanceId}-amount'),
    );
    await tester.enterText(amount, 'not-a-number');
    await tester.pump();
    final save = find.byKey(
      ValueKey('generic-instance-save-${instance.instanceId}'),
    );
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();
    expect(find.text('Enter a valid number.'), findsOneWidget);
    expect(
      (await api.queryInstances(
        tabId: 'any',
        personaId: 'person',
      )).items.single.instanceData['amount'],
      2,
    );
  });

  testWidgets(
    'initial progress is instance qualified and stale action loads cannot publish',
    (tester) async {
      final (api, a) = await _seed();
      final bId = await api.createInstance(
        workflowType: 'generic-test',
        personaId: 'person',
        initialInstanceData: (Map.of(a.instanceData)
          ..remove('computed')
          ..remove('effectOnly')
          ..['title'] = 'B'),
      );
      final b = (await api.queryInstances(
        tabId: 'any',
        personaId: 'person',
      )).items.singleWhere((row) => row.instanceId == bId);
      final controlled = _ControlledEngine(api);
      final machine = _machine();
      Widget card(WorkflowInstance row, String persona) => _host(
        GenericWorkflowInstanceCard(
          instance: row,
          machine: machine,
          engine: controlled,
          personaId: persona,
        ),
      );
      await tester.pumpWidget(card(a, 'person'));
      expect(
        find.byKey(ValueKey('generic-instance-progress-${a.instanceId}')),
        findsOneWidget,
      );
      await tester.pumpWidget(card(b, 'other'));
      expect(controlled.actionCompleters, hasLength(2));
      controlled.actionCompleters[0].complete([
        const LoomWorkflowTransition(
          id: 'old',
          label: 'Old action',
          from: ['open'],
        ),
      ]);
      await tester.pump();
      expect(find.text('Old action'), findsNothing);
      controlled.actionCompleters[1].complete([
        const LoomWorkflowTransition(
          id: 'new',
          label: 'New action',
          from: ['open'],
        ),
      ]);
      await tester.pump();
      expect(find.text('New action'), findsOneWidget);
    },
  );

  testWidgets(
    'replacement releases a held mutation, rejects stale callback, and deduplicates current writes',
    (tester) async {
      final (api, a) = await _seed();
      final bId = await api.createInstance(
        workflowType: 'generic-test',
        personaId: 'person',
        initialInstanceData: (Map.of(a.instanceData)
          ..remove('computed')
          ..remove('effectOnly')
          ..['title'] = 'B'),
      );
      final b = (await api.queryInstances(
        tabId: 'any',
        personaId: 'person',
      )).items.singleWhere((row) => row.instanceId == bId);
      final controlled = _ControlledEngine(api);
      final machine = _machine();
      final callbacks = <WorkflowInstance>[];
      Widget card(WorkflowInstance row, String persona) => _host(
        GenericWorkflowInstanceCard(
          instance: row,
          machine: machine,
          engine: controlled,
          personaId: persona,
          onInstanceChanged: callbacks.add,
        ),
      );
      await tester.pumpWidget(card(a, 'person'));
      controlled.actionCompleters.single.complete(const []);
      await tester.pump();
      await tester.enterText(
        find.byKey(ValueKey('generic-instance-editor-${a.instanceId}-text')),
        'A edit',
      );
      await tester.pump();
      controlled.updateCompleter = Completer<void>();
      final aSave = find.byKey(
        ValueKey('generic-instance-save-${a.instanceId}'),
      );
      await tester.ensureVisible(aSave);
      await tester.tap(aSave);
      await tester.pump();
      expect(controlled.updateCalls, 1);
      await tester.pumpWidget(card(b, 'other'));
      controlled.actionCompleters.last.complete(const []);
      await tester.pump();
      final bSave = find.byKey(
        ValueKey('generic-instance-save-${b.instanceId}'),
      );
      await tester.enterText(
        find.byKey(ValueKey('generic-instance-editor-${b.instanceId}-text')),
        'B edit',
      );
      await tester.pump();
      expect(tester.widget<FilledButton>(bSave).onPressed, isNotNull);
      await tester.ensureVisible(bSave);
      await tester.tap(bSave);
      await tester.tap(bSave);
      expect(controlled.updateCalls, 2);
      controlled.updateCompleter!.complete();
      controlled.updateCompleter = null;
      await tester.pumpAndSettle();
      expect(
        callbacks.where((row) => row.instanceId == a.instanceId),
        isEmpty,
        reason: 'A completion cannot callback over B',
      );
      expect(
        find.byKey(ValueKey('generic-instance-card-${b.instanceId}')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'failed post-mutation refresh clears prior actions and retry replaces them',
    (tester) async {
      final (api, instance) = await _seed();
      final controlled = _ControlledEngine(api);
      final machine = _machine();
      await tester.pumpWidget(
        _host(
          GenericWorkflowInstanceCard(
            instance: instance,
            machine: machine,
            engine: controlled,
            personaId: 'person',
          ),
        ),
      );
      controlled.actionCompleters.single.complete([
        const LoomWorkflowTransition(
          id: 'old',
          label: 'Old action',
          from: ['open'],
        ),
      ]);
      await tester.pump();
      expect(find.text('Old action'), findsOneWidget);
      await tester.enterText(
        find.byKey(
          ValueKey('generic-instance-editor-${instance.instanceId}-text'),
        ),
        'saved',
      );
      await tester.pump();
      controlled.failNextActions = true;
      final save = find.byKey(
        ValueKey('generic-instance-save-${instance.instanceId}'),
      );
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('generic-instance-error-${instance.instanceId}')),
        findsOneWidget,
      );
      expect(find.text('Old action'), findsNothing);
      await tester.tap(
        find.byKey(ValueKey('generic-instance-retry-${instance.instanceId}')),
      );
      controlled.actionCompleters.last.complete([
        const LoomWorkflowTransition(
          id: 'fresh',
          label: 'Fresh action',
          from: ['open'],
        ),
      ]);
      await tester.pump();
      expect(find.text('Fresh action'), findsOneWidget);
      expect(find.text('Old action'), findsNothing);
    },
  );

  testWidgets('an invalidated real date picker cannot edit or write B', (
    tester,
  ) async {
    final (api, a) = await _seed();
    final bId = await api.createInstance(
      workflowType: 'generic-test',
      personaId: 'person',
      initialInstanceData: (Map.of(a.instanceData)
        ..remove('computed')
        ..remove('effectOnly')
        ..['title'] = 'B'),
    );
    final b = (await api.queryInstances(
      tabId: 'any',
      personaId: 'person',
    )).items.singleWhere((row) => row.instanceId == bId);
    final controlled = _ControlledEngine(api);
    final machine = _machine();
    Widget card(WorkflowInstance row, String persona) => _host(
      GenericWorkflowInstanceCard(
        instance: row,
        machine: machine,
        engine: controlled,
        personaId: persona,
      ),
    );
    await tester.pumpWidget(card(a, 'person'));
    controlled.actionCompleters.single.complete(const []);
    await tester.pump();
    final day = find.byKey(
      ValueKey('generic-instance-editor-${a.instanceId}-day'),
    );
    await tester.ensureVisible(day);
    await tester.tap(day);
    await tester.pumpAndSettle();
    await tester.pumpWidget(card(b, 'other'));
    controlled.actionCompleters.last.complete(const []);
    await tester.pump();
    await tester.tap(find.text('15').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(controlled.updateCalls, 0);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(ValueKey('generic-instance-save-${b.instanceId}')),
          )
          .onPressed,
      isNull,
    );
    expect(
      find.byKey(ValueKey('generic-instance-card-${b.instanceId}')),
      findsOneWidget,
    );
  });
}
