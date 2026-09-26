import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

// SHELL-humanizer-conformance: part18 (WorkflowFactPillRow), part26
// (GenericWorkflowInstanceCard) and part32 (EngineNativeListSurface table
// columns) all fell back to a field's raw schema key -- e.g. "requestId" --
// whenever no `labelTemplate` was declared. They now share one humanizer
// (`_humanizeFieldName` in part08_garden_and_helpers.dart) so the fallback
// reads "Request id" everywhere instead of disagreeing site to site.

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('WorkflowFactPillRow field-label fallback (part18)', () {
    testWidgets(
      'a field with no labelTemplate renders a humanized label, not its raw key',
      (tester) async {
        await tester.pumpWidget(
          _host(
            const WorkflowFactPillRow(
              instanceData: {'requestInstanceId': 'community_x_abc123'},
              instanceDataSchema: {
                'requestInstanceId': WorkflowFactPillFieldSchema(
                  type: 'text',
                  displayIcon: 'tag',
                ),
              },
              displayContext: 'detail',
            ),
          ),
        );

        expect(find.text('requestInstanceId'), findsNothing);
        expect(find.text('Request Instance Id'), findsOneWidget);
      },
    );

    testWidgets(
      'a field with underscores in its key gets word-spaced too, not just camelCase',
      (tester) async {
        await tester.pumpWidget(
          _host(
            const WorkflowFactPillRow(
              instanceData: {'contact_email': 'a@example.com'},
              instanceDataSchema: {
                'contact_email': WorkflowFactPillFieldSchema(
                  type: 'text',
                  displayIcon: 'mail',
                ),
              },
              displayContext: 'detail',
            ),
          ),
        );

        expect(find.text('contact_email'), findsNothing);
        expect(find.text('Contact email'), findsOneWidget);
      },
    );

    testWidgets(
      'displayContexts: [] still means never render, regardless of the label fallback',
      (tester) async {
        await tester.pumpWidget(
          _host(
            const WorkflowFactPillRow(
              instanceData: {'internalCursor': 'opaque-token'},
              instanceDataSchema: {
                'internalCursor': WorkflowFactPillFieldSchema(
                  type: 'text',
                  displayContexts: [],
                ),
              },
              displayContext: 'detail',
            ),
          ),
        );

        expect(find.text('internalCursor'), findsNothing);
        expect(find.text('Internal cursor'), findsNothing);
        expect(find.byType(WorkflowFactPillRow), findsOneWidget);
      },
    );

    testWidgets('an explicit labelTemplate is unaffected by the fallback change', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const WorkflowFactPillRow(
            instanceData: {'requestInstanceId': 'community_x_abc123'},
            instanceDataSchema: {
              'requestInstanceId': WorkflowFactPillFieldSchema(
                type: 'text',
                labelTemplate: 'Related request',
              ),
            },
            displayContext: 'detail',
          ),
        ),
      );

      expect(find.text('Related request'), findsOneWidget);
      expect(find.text('Request Instance Id'), findsNothing);
    });
  });

  group('GenericWorkflowInstanceCard field-label fallback (part26)', () {
    LoomWorkflowStateMachine machine({required Map<String, dynamic> field}) =>
        LoomWorkflowStateMachine.fromJson({
          'initialState': 'open',
          'states': {
            'open': {'label': 'Open'},
          },
          'transitions': <dynamic>[],
          'instanceDataSchema': {'title': field},
        }, 'humanizer-a26-test');

    Future<(WorkflowEngineApi, WorkflowInstance)> seed(
      LoomWorkflowStateMachine machine,
    ) async {
      final api = LocalWorkflowEngineApi(
        db: WorkflowDatabase.memory(),
        communityId: 'humanizer-a26',
      );
      api.registerDefinition(machine);
      final id = await api.createInstance(
        workflowType: machine.workflowType,
        fanId: 'person',
        initialInstanceData: {'title': 'Some value'},
      );
      final row = (await api.queryInstances(
        tabId: 'any',
        fanId: 'person',
      )).items.singleWhere((item) => item.instanceId == id);
      return (api, row);
    }

    testWidgets(
      'a non-editable fact field with no labelTemplate renders a humanized label',
      (tester) async {
        final schema = machine(
          field: {'type': 'text', 'displayIcon': 'title'},
        );
        final (api, instance) = await seed(schema);

        await tester.pumpWidget(
          _host(
            GenericWorkflowInstanceCard(
              instance: instance,
              machine: schema,
              engine: api,
              fanId: 'person',
              roleId: 'person',
              displayContext: 'tile',
            ),
          ),
        );
        await tester.pump();

        expect(find.text('title'), findsNothing);
        expect(find.text('Title'), findsOneWidget);
      },
    );

    testWidgets(
      'displayContexts: [] still means never render on the generic instance card',
      (tester) async {
        final schema = machine(
          field: {
            'type': 'text',
            'displayIcon': 'title',
            'displayContexts': <String>[],
          },
        );
        final (api, instance) = await seed(schema);

        await tester.pumpWidget(
          _host(
            GenericWorkflowInstanceCard(
              instance: instance,
              machine: schema,
              engine: api,
              fanId: 'person',
              roleId: 'person',
              displayContext: 'tile',
            ),
          ),
        );
        await tester.pump();

        expect(find.text('title'), findsNothing);
        expect(find.text('Title'), findsNothing);
        expect(find.byType(GenericWorkflowInstanceCard), findsOneWidget);
      },
    );
  });

  group('EngineNativeListSurface table column fallback (part32)', () {
    LoomWorkflowStateMachine tableMachine() => LoomWorkflowStateMachine.fromJson({
      'initialState': 'open',
      'states': {
        'open': {'label': 'Open'},
      },
      'transitions': <dynamic>[],
      'instanceDataSchema': {
        'playerName': {
          'type': 'text',
          'displayContexts': ['tile'],
          'labelTemplate': 'Player',
        },
        'winStreak': {'type': 'number', 'displayContexts': ['tile']},
        'internalSeed': {
          'type': 'number',
          'displayContexts': <String>[],
        },
      },
      'renderBindings': [
        {
          'tabId': 'home',
          'states': ['open'],
          'audience': 'any',
          'cardSurfaceFamily': 'table',
          'bindingKind': 'primary',
        },
      ],
    }, 'table-rankings-humanizer');

    testWidgets(
      'a table column with no labelTemplate renders a humanized header, and '
      'displayContexts: [] still excludes the column entirely',
      (tester) async {
        final machine = tableMachine();
        final local = LocalWorkflowEngineApi(
          db: WorkflowDatabase.memory(),
          communityId: 'humanizer-a32',
        );
        local.registerDefinition(machine);
        await local.createInstance(
          workflowType: machine.workflowType,
          fanId: 'owner',
          initialInstanceData: {
            'playerName': 'Alice',
            'winStreak': 3,
            'internalSeed': 42,
          },
        );

        final experience = experienceForExtensionId(
          'ext-humanizer-a32',
          specVersion: currentCommunitySpecVersion,
          experienceConfiguration: {
            'workflowDefinitions': {
              machine.workflowType: {
                'workflowId': machine.workflowType,
                'initialState': 'open',
                'states': {
                  'open': {'label': 'Open'},
                },
                'transitions': <dynamic>[],
                'instanceDataSchema': {
                  'playerName': {
                    'type': 'text',
                    'displayContexts': ['tile'],
                    'labelTemplate': 'Player',
                  },
                  'winStreak': {
                    'type': 'number',
                    'displayContexts': ['tile'],
                  },
                  'internalSeed': {
                    'type': 'number',
                    'displayContexts': <String>[],
                  },
                },
                'renderBindings': [
                  {
                    'tabId': 'home',
                    'states': ['open'],
                    'audience': 'any',
                    'cardSurfaceFamily': 'table',
                    'bindingKind': 'primary',
                  },
                ],
              },
            },
          },
        );
        const actorIdentity = LoomActorIdentity(
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
                roleId: actorIdentity.roleId,
              ),
              child: Scaffold(
                body: EngineNativeListSurface(
                  experience: experience,
                  actorIdentity: actorIdentity,
                  tabId: 'home',
                  accent: Colors.teal,
                  modernTheme: null,
                  engine: local,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Player'), findsOneWidget);
        expect(find.text('winStreak'), findsNothing);
        expect(find.text('Win Streak'), findsOneWidget);
        expect(find.text('internalSeed'), findsNothing);
        expect(find.text('Internal Seed'), findsNothing);
      },
    );
  });
}
