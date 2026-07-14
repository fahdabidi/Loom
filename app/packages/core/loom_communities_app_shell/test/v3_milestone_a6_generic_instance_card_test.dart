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
      'editableFields': ['text', 'notes', 'day', 'at', 'enabled', 'amount'],
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
    'day': {'type': 'date'},
    'at': {'type': 'time'},
    'enabled': {'type': 'bool'},
    'amount': {'type': 'number'},
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
}
