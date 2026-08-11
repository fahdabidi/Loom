import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

LoomWorkflowTransition _recurrenceInputTransition() =>
    LoomWorkflowStateMachine.fromJson({
      'initialState': 'open',
      'states': {
        'open': {'label': 'Open'},
      },
      'transitions': [
        {
          'id': 'make-recurring',
          'label': 'Make recurring',
          'from': ['open'],
          'to': null,
          'inputs': {
            'freq': {'type': 'text', 'required': true},
            'byDayOfWeekWeekly': {
              'type': 'list',
              'options': ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'],
              'visibleWhen': "freq == 'weekly'",
              'writesTo': 'byDayOfWeek',
            },
            'byDayOfWeekMonthly': {
              'type': 'list',
              'options': ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'],
              'maxSelections': 1,
              'visibleWhen': "freq == 'monthly'",
              'modeGroup': 'monthlyPattern',
              'modeValue': 'lastOrNthWeekday',
              'writesTo': 'byDayOfWeek',
            },
            'byMonthDay': {
              'type': 'number',
              'visibleWhen': "freq == 'monthly'",
              'modeGroup': 'monthlyPattern',
              'modeValue': 'dayOfMonth',
            },
            'bySetPos': {
              'type': 'text',
              'options': ['first', 'second', 'third', 'fourth', 'last'],
              'visibleWhen': "freq == 'monthly'",
              'modeGroup': 'monthlyPattern',
              'modeValue': 'lastOrNthWeekday',
            },
          },
        },
      ],
    }, 'recurrence-input-test').transitions.single;

Widget _transitionInputHost(
  LoomWorkflowTransition transition,
  ValueChanged<Map<String, dynamic>?> onResult,
) => MaterialApp(
  home: Scaffold(
    body: Builder(
      builder: (context) => FilledButton(
        key: const ValueKey('open-transition-input-dialog'),
        onPressed: () async => onResult(
          await showDialog<Map<String, dynamic>>(
            context: context,
            builder: (context) => GenericTransitionInputDialog(
              transition: transition,
              instanceData: const {},
            ),
          ),
        ),
        child: const Text('Open'),
      ),
    ),
  ),
);

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
        'allDay',
        'eventTime',
        'locationType',
        'videoLink',
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
      'allDay': false,
      'eventTime': '09:30',
      'locationType': 'in person',
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
    Map<String, dynamic>? inputs,
  }) => delegate.applyTransition(
    workflowType: workflowType,
    instanceId: instanceId,
    transitionId: transitionId,
    personaId: personaId,
    inputs: inputs,
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
  Future<List<String>> createInstances({
    required String workflowType,
    required List<Map<String, dynamic>> initialInstanceDataList,
    required String personaId,
  }) => delegate.createInstances(
    workflowType: workflowType,
    initialInstanceDataList: initialInstanceDataList,
    personaId: personaId,
  );
  @override
  Future<dynamic> aggregate({
    required String workflowType,
    required String column,
    required String op,
    Map<String, dynamic>? filter,
    String? groupBy,
    String? personaId,
  }) => delegate.aggregate(
    workflowType: workflowType,
    column: column,
    op: op,
    filter: filter,
    groupBy: groupBy,
    personaId: personaId,
  );
  @override
  Future<List<WorkflowInstance>> dueNotifications({required DateTime asOf}) =>
      delegate.dueNotifications(asOf: asOf);
}

LoomWorkflowStateMachine _editableListMachine() =>
    LoomWorkflowStateMachine.fromJson({
      'initialState': 'open',
      'states': {
        'open': {
          'label': 'Open',
          'editableFields': ['selectedSchemaIds'],
        },
      },
      'transitions': <dynamic>[],
      'instanceDataSchema': {
        'selectedSchemaIds': {
          'type': 'list',
          'writableBy': 'formEntry',
          'displayContexts': ['tile'],
        },
      },
    }, 'generic-instance-editable-list');

GenericWorkflowInstanceCard _card(
  LocalWorkflowEngineApi api,
  WorkflowInstance instance, {
  String context = 'tile',
  String persona = 'person',
  LoomWorkflowStateMachine? machine,
}) => GenericWorkflowInstanceCard(
  instance: instance,
  machine: machine ?? _machine(),
  engine: api,
  personaId: persona,
  displayContext: context,
);

void main() {
  testWidgets(
    'weekly recurrence keeps unbounded weekday selections and writes to byDayOfWeek',
    (tester) async {
      Map<String, dynamic>? result;
      await tester.pumpWidget(
        _transitionInputHost(_recurrenceInputTransition(), (value) {
          result = value;
        }),
      );
      await tester.tap(find.byKey(const ValueKey('open-transition-input-dialog')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('generic-transition-input-freq')),
        'weekly',
      );
      await tester.pump();
      for (final weekday in ['MO', 'WE', 'FR']) {
        await tester.tap(
          find.byKey(
            ValueKey('generic-transition-input-byDayOfWeekWeekly-$weekday'),
          ),
        );
        await tester.pump();
      }
      await tester.tap(
        find.byKey(const ValueKey('generic-transition-input-confirm')),
      );
      await tester.pumpAndSettle();

      expect(result, {'freq': 'weekly', 'byDayOfWeek': ['MO', 'WE', 'FR']});
      expect(result!.containsKey('byDayOfWeekWeekly'), isFalse);
    },
  );

  testWidgets(
    'monthly weekday recurrence caps selections and has only two mode choices',
    (tester) async {
      Map<String, dynamic>? result;
      await tester.pumpWidget(
        _transitionInputHost(_recurrenceInputTransition(), (value) {
          result = value;
        }),
      );
      await tester.tap(find.byKey(const ValueKey('open-transition-input-dialog')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('generic-transition-input-freq')),
        'monthly',
      );
      await tester.pump();

      final modeChoices = find.byType(RadioListTile<String>);
      expect(modeChoices, findsNWidgets(2));
      expect(find.text('By day of week monthly'), findsNothing);
      await tester.tap(
        find.byKey(
          const ValueKey(
            'generic-transition-input-mode-monthlyPattern-lastOrNthWeekday',
          ),
        ),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(
          const ValueKey('generic-transition-input-byDayOfWeekMonthly-MO'),
        ),
      );
      await tester.tap(
        find.byKey(
          const ValueKey('generic-transition-input-byDayOfWeekMonthly-FR'),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('generic-transition-input-confirm')),
      );
      await tester.pumpAndSettle();

      expect(result, {'freq': 'monthly', 'byDayOfWeek': ['FR']});
      expect(result!.containsKey('byDayOfWeekMonthly'), isFalse);
    },
  );

  testWidgets('monthly day-of-month mode remains selected and collected', (
    tester,
  ) async {
    Map<String, dynamic>? result;
    await tester.pumpWidget(
      _transitionInputHost(_recurrenceInputTransition(), (value) {
        result = value;
      }),
    );
    await tester.tap(find.byKey(const ValueKey('open-transition-input-dialog')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('generic-transition-input-freq')),
      'monthly',
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('generic-transition-input-byMonthDay')),
      '15',
    );
    await tester.tap(
      find.byKey(const ValueKey('generic-transition-input-confirm')),
    );
    await tester.pumpAndSettle();

    expect(result, {'freq': 'monthly', 'byMonthDay': 15});
  });

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
      for (final text in ['Nothing:', 'Items: 0', 'Map:']) {
        expect(find.text(text), findsNothing);
      }
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

  testWidgets('re-evaluates editing visibility from unsaved generic edits', (
    tester,
  ) async {
    final (api, instance) = await _seed();
    await tester.pumpWidget(_host(_card(api, instance)));
    await tester.pump();

    final allDay = find.byKey(
      ValueKey('generic-instance-editor-${instance.instanceId}-allDay'),
    );
    final eventTime = find.byKey(
      ValueKey('generic-instance-editor-${instance.instanceId}-eventTime'),
    );
    final locationType = find.byKey(
      ValueKey('generic-instance-editor-${instance.instanceId}-locationType'),
    );
    final videoLink = find.byKey(
      ValueKey('generic-instance-editor-${instance.instanceId}-videoLink'),
    );
    expect(eventTime, findsOneWidget);
    expect(videoLink, findsNothing);

    await tester.ensureVisible(allDay);
    await tester.tap(allDay);
    await tester.pump();
    expect(eventTime, findsNothing);
    await tester.ensureVisible(locationType);
    await tester.enterText(locationType, 'video');
    await tester.pump();
    expect(videoLink, findsOneWidget);
    await tester.enterText(locationType, 'in person');
    await tester.pump();
    expect(videoLink, findsNothing);
  });

  testWidgets(
    'public fact and action seams preserve declared icons and generic tones',
    (tester) async {
      const icons = <String, IconData>{
        'archive': Icons.archive,
        'calendar_today': Icons.calendar_today,
        'campaign': Icons.campaign,
        'cancel': Icons.cancel,
        'casino': Icons.casino,
        'delete_outline': Icons.delete_outline,
        'event_seat': Icons.event_seat,
        'forum': Icons.forum,
        'gavel': Icons.gavel,
        'how_to_vote': Icons.how_to_vote,
        'how_to_vote_outlined': Icons.how_to_vote_outlined,
        'mark_email_read': Icons.mark_email_read,
      };
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              WorkflowFactPillRow(
                instanceData: {for (final name in icons.keys) name: name},
                instanceDataSchema: {
                  for (final name in icons.keys)
                    name: WorkflowFactPillFieldSchema(
                      displayIcon: name,
                      labelTemplate: name,
                    ),
                },
              ),
              const WorkflowActionButtonRow(
                surface: 'a6-actions',
                availableTransitions: [
                  WorkflowActionButtonTransition(
                    id: 'primary',
                    label: 'Primary',
                    iconName: 'check',
                  ),
                  WorkflowActionButtonTransition(
                    id: 'secondary',
                    label: 'Secondary',
                    iconName: 'archive',
                    tone: WorkflowActionTone.secondary,
                  ),
                  WorkflowActionButtonTransition(
                    id: 'destructive',
                    label: 'Destructive',
                    iconName: 'delete_outline',
                    tone: WorkflowActionTone.destructive,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      for (final icon in icons.values) {
        expect(find.byIcon(icon), findsAtLeastNWidgets(1));
      }
      final primary = find.byKey(const ValueKey('a6-actions-action-primary'));
      final secondary = find.byKey(
        const ValueKey('a6-actions-action-secondary'),
      );
      final destructive = find.byKey(
        const ValueKey('a6-actions-action-destructive'),
      );
      expect(primary, findsOneWidget);
      expect(tester.widget(primary), isA<FilledButton>());
      expect(tester.widget(secondary), isA<OutlinedButton>());
      expect(tester.widget(destructive), isA<FilledButton>());
      expect(
        find.descendant(of: primary, matching: find.byIcon(Icons.check)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: secondary, matching: find.byIcon(Icons.archive)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: destructive,
          matching: find.byIcon(Icons.delete_outline),
        ),
        findsOneWidget,
      );
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
      expect(
        find.descendant(of: day, matching: find.text('2026-07-15')),
        findsOneWidget,
      );
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
      expect(
        find.descendant(of: at, matching: find.text('21:30')),
        findsOneWidget,
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
    'generic card renders external url field as tappable url fact',
    (tester) async {
      final api = LocalWorkflowEngineApi(
        db: WorkflowDatabase.memory(),
        communityId: 'url-test',
      );
      final machine = LoomWorkflowStateMachine.fromJson({
        'initialState': 'open',
        'states': {
          'open': {'label': 'Open'},
        },
        'transitions': <dynamic>[],
        'instanceDataSchema': {
          'docsUrl': {
            'type': 'url',
            'openMode': 'external',
            'displayIcon': 'open_in_new',
            'labelTemplate': 'Project docs',
            'displayContexts': ['tile'],
          },
        },
      }, 'url-link');
      api.registerDefinition(machine);
      final id = await api.createInstance(
        workflowType: 'url-link',
        personaId: 'person',
        initialInstanceData: {'docsUrl': 'https://example.org/project'},
      );
      final instance = (await api.queryInstances(
        tabId: 'any',
        personaId: 'person',
      )).items.singleWhere((row) => row.instanceId == id);

      await tester.pumpWidget(
        _host(
          GenericWorkflowInstanceCard(
            instance: instance,
            machine: machine,
            engine: api,
            personaId: 'person',
            displayContext: 'tile',
          ),
        ),
      );
      await tester.pump();

      final urlFact = find.byKey(const ValueKey('workflow-fact-url-docsUrl'));
      expect(urlFact, findsOneWidget);
      expect(tester.widget<InkWell>(urlFact).onTap, isNotNull);
      expect(find.text('Project docs'), findsOneWidget);
    },
  );

  testWidgets(
    'generic card renders citation list with text labels and tappable source urls',
    (tester) async {
      final api = LocalWorkflowEngineApi(
        db: WorkflowDatabase.memory(),
        communityId: 'list-url-test',
      );
      final machine = LoomWorkflowStateMachine.fromJson({
        'initialState': 'open',
        'states': {
          'open': {'label': 'Open'},
        },
        'transitions': <dynamic>[],
        'instanceDataSchema': {
          'citations': {
            'type': 'list',
            'labelTemplate': 'Citations: {value.length}',
            'itemSchema': {
              'label': {'type': 'text', 'labelTemplate': '{value}'},
              'source': {
                'type': 'url',
                'openMode': 'external',
                'displayIcon': 'open_in_new',
                'labelTemplate': '{value}',
              },
            },
          },
        },
      }, 'list-url-link');
      api.registerDefinition(machine);
      final id = await api.createInstance(
        workflowType: 'list-url-link',
        personaId: 'person',
        initialInstanceData: {
          'citations': [
            {
              'label': 'Doc A',
              'source': 'https://example.org/a',
            },
            {
              'label': 'Doc B',
              'source': 'https://example.org/b',
            },
          ],
        },
      );
      final instance = (await api.queryInstances(
        tabId: 'any',
        personaId: 'person',
      )).items.singleWhere((row) => row.instanceId == id);

      await tester.pumpWidget(
        _host(
          GenericWorkflowInstanceCard(
            instance: instance,
            machine: machine,
            engine: api,
            personaId: 'person',
            displayContext: 'tile',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Doc A'), findsOneWidget);
      expect(find.text('Doc B'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('workflow-fact-list-item-citations-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('workflow-fact-list-item-citations-1')),
        findsOneWidget,
      );

      final firstSource = find.byKey(
        const ValueKey('workflow-fact-list-url-citations-0-source'),
      );
      final secondSource = find.byKey(
        const ValueKey('workflow-fact-list-url-citations-1-source'),
      );
      expect(firstSource, findsOneWidget);
      expect(secondSource, findsOneWidget);
      expect(tester.widget<InkWell>(firstSource).onTap, isNotNull);
      expect(tester.widget<InkWell>(secondSource).onTap, isNotNull);
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
    'editable list fields show comma-joined initial text and clear hint when unsaved',
    (tester) async {
      final api = LocalWorkflowEngineApi(
        db: WorkflowDatabase.memory(),
        communityId: 'list-hint',
      );
      final machine = _editableListMachine();
      api.registerDefinition(machine);
      final id = await api.createInstance(
        workflowType: 'generic-instance-editable-list',
        personaId: 'person',
        initialInstanceData: {'selectedSchemaIds': ['a', 'b']},
      );
      final instance = (await api.queryInstances(
        tabId: 'any',
        personaId: 'person',
      )).items.singleWhere((row) => row.instanceId == id);

      await tester.pumpWidget(_host(_card(api, instance, machine: machine)));
      await tester.pump();

      final editor = find.byKey(
        ValueKey('generic-instance-editor-${instance.instanceId}-selectedSchemaIds'),
      );
      final editorText = tester.widget<TextField>(editor).controller!.text;
      expect(editorText, equals('a, b'));
      expect(editorText, isNot(contains('[')));
      expect(editorText, isNot(contains(']')));
      expect(editorText, contains('a'));
      expect(editorText, contains('b'));

      final saveHint = find.byKey(
        ValueKey('generic-instance-save-hint-${instance.instanceId}'),
      );
      final save = find.byKey(
        ValueKey('generic-instance-save-${instance.instanceId}'),
      );
      expect(saveHint, findsOneWidget);
      expect(tester.widget<FilledButton>(save).onPressed, isNull);

      await tester.enterText(editor, 'a, b, c');
      await tester.pump();
      expect(saveHint, findsNothing);
      expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      final updated = (await api.queryInstances(
        tabId: 'any',
        personaId: 'person',
      )).items.singleWhere((row) => row.instanceId == id);
      expect(updated.instanceData['selectedSchemaIds'], ['a', 'b', 'c']);
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
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          ValueKey('generic-instance-progress-${instance.instanceId}'),
        ),
        findsNothing,
      );
      expect(find.text('Cast vote'), findsNothing);
    },
  );

  testWidgets(
    'picker labels and values are separate and non-writable editors are filtered',
    (tester) async {
      final (api, instance) = await _seed();
      await tester.pumpWidget(_host(_card(api, instance)));
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(
            ValueKey('generic-instance-editor-${instance.instanceId}-day'),
          ),
          matching: find.text('Date'),
        ),
        findsOneWidget,
      );
      expect(find.text('2026-07-14'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(
            ValueKey('generic-instance-editor-${instance.instanceId}-at'),
          ),
          matching: find.text('At'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            ValueKey('generic-instance-editor-${instance.instanceId}-at'),
          ),
          matching: find.text('09:30'),
        ),
        findsOneWidget,
      );
      for (final key in ['computed', 'effectOnly']) {
        expect(
          find.byKey(
            ValueKey('generic-instance-editor-${instance.instanceId}-$key'),
          ),
          findsNothing,
        );
      }
    },
  );

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
      final controlledA = _ControlledEngine(api);
      final controlledB = _ControlledEngine(api);
      final machineA = _machine();
      final machineB = _machine();
      Widget card(
        WorkflowInstance row,
        String persona,
        LoomWorkflowStateMachine machine,
        WorkflowEngineApi engine,
      ) => _host(
        GenericWorkflowInstanceCard(
          instance: row,
          machine: machine,
          engine: engine,
          personaId: persona,
        ),
      );
      await tester.pumpWidget(card(a, 'person', machineA, controlledA));
      expect(
        find.byKey(ValueKey('generic-instance-progress-${a.instanceId}')),
        findsOneWidget,
      );
      await tester.pumpWidget(card(b, 'other', machineB, controlledB));
      expect(controlledA.actionCompleters, hasLength(1));
      expect(controlledB.actionCompleters, hasLength(1));
      controlledA.actionCompleters.single.complete([
        const LoomWorkflowTransition(
          id: 'old',
          label: 'Old action',
          from: ['open'],
        ),
      ]);
      await tester.pump();
      expect(find.text('Old action'), findsNothing);
      controlledB.actionCompleters.single.complete([
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
    'stale and current mutations use independent engines and only current B publishes',
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
      final controlledA = _ControlledEngine(api)
        ..updateCompleter = Completer<void>();
      final controlledB = _ControlledEngine(api)
        ..updateCompleter = Completer<void>();
      final machineA = _machine();
      final machineB = _machine();
      final callbacks = <WorkflowInstance>[];
      Widget card(
        WorkflowInstance row,
        String persona,
        LoomWorkflowStateMachine machine,
        WorkflowEngineApi engine,
      ) => _host(
        GenericWorkflowInstanceCard(
          instance: row,
          machine: machine,
          engine: engine,
          personaId: persona,
          onInstanceChanged: callbacks.add,
        ),
      );
      await tester.pumpWidget(card(a, 'person', machineA, controlledA));
      controlledA.actionCompleters.single.complete(const []);
      await tester.pump();
      await tester.enterText(
        find.byKey(ValueKey('generic-instance-editor-${a.instanceId}-text')),
        'A edit',
      );
      await tester.pump();
      final aSave = find.byKey(
        ValueKey('generic-instance-save-${a.instanceId}'),
      );
      await tester.ensureVisible(aSave);
      await tester.tap(aSave);
      await tester.pump();
      expect(controlledA.updateCalls, 1);
      await tester.pumpWidget(card(b, 'other', machineB, controlledB));
      controlledB.actionCompleters.single.complete(const []);
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
      expect(controlledB.updateCalls, 1);
      controlledB.updateCompleter!.complete();
      controlledB.updateCompleter = null;
      await tester.pump();
      expect(controlledB.actionCompleters, hasLength(2));
      controlledB.actionCompleters.last.complete(const []);
      await tester.pumpAndSettle();
      final persistedB = (await api.queryInstances(
        tabId: 'any',
        personaId: 'other',
      )).items.singleWhere((row) => row.instanceId == b.instanceId);
      expect(persistedB.instanceData['text'], 'B edit');
      expect(callbacks.map((row) => row.instanceId), [b.instanceId]);
      expect(
        find.byKey(ValueKey('generic-instance-progress-${b.instanceId}')),
        findsNothing,
      );
      controlledA.updateCompleter!.complete();
      controlledA.updateCompleter = null;
      await tester.pumpAndSettle();
      expect(
        callbacks.map((row) => row.instanceId),
        [b.instanceId],
        reason: 'A completion cannot callback or publish over B',
      );
      expect(
        find.byKey(ValueKey('generic-instance-card-${b.instanceId}')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(
                ValueKey('generic-instance-editor-${b.instanceId}-text'),
              ),
            )
            .controller!
            .text,
        'B edit',
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
