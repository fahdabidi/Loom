import 'dart:async';

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

LoomWorkflowStateMachine _labelRegressionMachine() =>
    LoomWorkflowStateMachine.fromJson({
      'initialState': 'draft',
      'states': {
        'draft': {
          'label': 'Draft',
          'editableFields': [
            'reminderOffsetHours',
            'durationMinutes',
            'amount',
            'status',
            'wholeTokenField',
            'plainPunctuated',
          ],
        },
      },
      'transitions': const <Map<String, dynamic>>[],
      'instanceDataSchema': {
        'reminderOffsetHours': {
          'type': 'number',
          'labelTemplate': 'Default reminder: {value} hours before',
        },
        'durationMinutes': {
          'type': 'number',
          'labelTemplate': '{value} minutes',
        },
        'amount': {'type': 'number', 'labelTemplate': 'Amount: {value}'},
        'status': {'type': 'text', 'labelTemplate': 'Status: {value.length}'},
        'wholeTokenField': {'type': 'text', 'labelTemplate': '{value.length}'},
        'plainPunctuated': {'type': 'text', 'labelTemplate': 'Plain label:'},
      },
    }, 'label-regression');

LoomWorkflowStateMachine _fanIdMachine() => LoomWorkflowStateMachine.fromJson({
  'initialState': 'draft',
  'states': {
    'draft': {
      'label': 'Draft',
      'editableFields': ['participantFanIds'],
    },
  },
  'transitions': const <Map<String, dynamic>>[],
  'instanceDataSchema': {
    'participantFanIds': {'type': 'fanId[]', 'required': true},
  },
}, 'fan-id-creation');

const _directoryMembers = <LoomCommunityMember>[
  LoomCommunityMember(
    fanId: 'fan-x',
    roleIds: ['x-member', 'x-moderator'],
    status: MembershipStatus.active,
    displayLabel: 'Xavier Fan',
  ),
  LoomCommunityMember(
    fanId: 'fan-pending',
    roleIds: ['x-member'],
    status: MembershipStatus.pendingApproval,
    displayLabel: 'Pending Fan',
  ),
];

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
  testWidgets(
    'fanId[] creation stores fan ids, retains unknown ids, and never stores roles',
    (tester) async {
      final machine = _fanIdMachine();
      final engine = LocalWorkflowEngineApi(
        db: WorkflowDatabase.memory(),
        communityId: 'fan-id-creation-test',
      )..registerDefinition(machine);
      await tester.pumpWidget(
        _host(
          GenericWorkflowCreationCard(
            workflowType: 'fan-id-creation',
            machine: machine,
            engine: engine,
            fanId: 'fan-author',
            keyPrefix: 'fan-create',
            resolvedInitialValues: const {
              'participantFanIds': ['fan-departed'],
            },
            // Deliberately distinct identifier spaces. This is the role data
            // the pre-fix builder incorrectly persisted.
            audienceCandidates: const [
              AudienceMultiSelectCandidate(
                roleId: 'x-member',
                label: 'Member role',
              ),
            ],
            communityMembers: Future.value(_directoryMembers),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fanChoice = find.byKey(
        const ValueKey('fan-id-picker-member-fan-x'),
      );
      if (fanChoice.evaluate().isNotEmpty) {
        expect(
          find.byKey(const ValueKey('fan-id-picker-unknown-fan-departed')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('audience-picker-member-x-member')),
          findsNothing,
        );
        await tester.tap(fanChoice);
      } else {
        // This branch makes the test a discriminating regression oracle for
        // the pre-fix builder: it can drive that role picker, then the fan-id
        // assertion below proves that the wrong identifier space was stored.
        await tester.tap(
          find.byKey(const ValueKey('audience-picker-member-x-member')),
        );
      }
      await tester.tap(find.byKey(const ValueKey('fan-create-submit')));
      await tester.pumpAndSettle();

      final created = (await engine.queryInstances(
        tabId: 'unused',
        fanId: 'fan-author',
      )).items.single;
      expect(created.instanceData['participantFanIds'], [
        'fan-departed',
        'fan-x',
      ]);
      expect(
        created.instanceData['participantFanIds'],
        isNot(contains('x-member')),
      );
    },
  );

  testWidgets('fan directory renders loading, empty, and failed distinctly', (
    tester,
  ) async {
    final machine = _fanIdMachine();
    final engine = LocalWorkflowEngineApi(
      db: WorkflowDatabase.memory(),
      communityId: 'fan-directory-states-test',
    )..registerDefinition(machine);
    final loading = Completer<List<LoomCommunityMember>>();

    GenericWorkflowCreationCard card(
      Future<List<LoomCommunityMember>> members,
    ) => GenericWorkflowCreationCard(
      workflowType: 'fan-id-creation',
      machine: machine,
      engine: engine,
      fanId: 'fan-author',
      keyPrefix: 'fan-states',
      communityMembers: members,
    );

    await tester.pumpWidget(_host(card(loading.future)));
    expect(find.byKey(const ValueKey('fan-id-picker-loading')), findsOneWidget);

    loading.complete(const []);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('fan-id-picker-empty')), findsOneWidget);
    expect(find.byKey(const ValueKey('fan-id-picker-failed')), findsNothing);

    final failed = Completer<List<LoomCommunityMember>>();
    await tester.pumpWidget(_host(card(failed.future)));
    failed.completeError(StateError('directory unavailable'));
    await tester.pump();
    expect(find.byKey(const ValueKey('fan-id-picker-failed')), findsOneWidget);
    expect(find.byKey(const ValueKey('fan-id-picker-empty')), findsNothing);
  });

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
    expect(find.text('Title'), findsOneWidget);
  });

  testWidgets(
    'falls back to humanized keys for non-trailing value label tokens',
    (tester) async {
      final engine = await _engine();
      final machine = _labelRegressionMachine();
      await tester.pumpWidget(
        _host(
          GenericWorkflowCreationCard(
            workflowType: 'label-regression',
            machine: machine,
            engine: engine,
            fanId: 'member',
            keyPrefix: 'label-regression',
          ),
        ),
      );

      expect(find.text('Reminder Offset Hours'), findsOneWidget);
      expect(find.text('Duration Minutes'), findsOneWidget);
      expect(find.text('Whole Token Field'), findsOneWidget);
      expect(find.text('Amount'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Plain label'), findsOneWidget);
      expect(find.text('Default reminder:  hours before'), findsNothing);
      expect(find.text('minutes'), findsNothing);
    },
  );

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
