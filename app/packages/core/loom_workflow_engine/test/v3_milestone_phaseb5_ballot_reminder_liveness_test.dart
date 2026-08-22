import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

LoomWorkflowStateMachine
_tournamentBallotMachine() => LoomWorkflowStateMachine.fromJson({
  'initialState': 'open',
  'states': {
    'open': {'label': 'Voting open'},
    'closed': {'label': 'Closed', 'isTerminal': true},
  },
  'transitions': <Map<String, dynamic>>[],
  'instanceDataSchema': {
    'candidates': {
      'type': 'list',
      'required': true,
      'writableBy': 'formEntry',
      'storage': 'inline',
    },
    'deadline': {
      'type': 'date',
      'writableBy': 'formEntry',
      'storage': 'inline',
    },
    'reminderOffset': {
      'type': 'text',
      'writableBy': 'formEntry',
      'storage': 'inline',
    },
    'notificationsEnabled': {
      'type': 'bool',
      'writableBy': 'formEntry',
      'storage': 'inline',
    },
    'dueAt': {
      'type': 'date',
      'formula':
          "subtractHours(deadline, if(reminderOffset == 'one-week', 168, if(reminderOffset == 'one-day', 24, if(reminderOffset == 'one-hour', 1, 0))))",
    },
    'isExpiringSoon': {'type': 'bool', 'formula': 'isPast(dueAt)'},
  },
}, 'tournament-ballot');

void main() {
  test(
    'tournament-ballot reminder recomputes from the injected clock',
    () async {
      var now = DateTime.utc(2026, 7, 19, 17, 59, 59);
      final database = WorkflowDatabase.memory();
      addTearDown(database.close);
      final engine = LocalWorkflowEngineApi(
        db: database,
        communityId: 'phaseb5-reminder',
        clock: () => now,
      );
      engine.registerDefinition(_tournamentBallotMachine());

      final ballotId = await engine.createInstance(
        workflowType: 'tournament-ballot',
        fanId: 'tabletop-organizer',
        initialInstanceData: {
          'candidates': [
            {
              'id': 'catan',
              'name': 'Catan',
              'description': 'Classic trading and building game.',
            },
          ],
          'deadline': '2026-07-20T18:00:00.000Z',
          'reminderOffset': 'one-day',
          'notificationsEnabled': true,
        },
      );

      Future<WorkflowInstance> readBallot() async {
        final page = await engine.queryInstances(
          tabId: 'home',
          fanId: 'tabletop-member',
          limit: 10,
        );
        return page.items.singleWhere((item) => item.instanceId == ballotId);
      }

      final beforeDueAt = await readBallot();
      expect(beforeDueAt.instanceData['dueAt'], DateTime.utc(2026, 7, 19, 18));
      expect(beforeDueAt.instanceData['isExpiringSoon'], isFalse);

      // isPast is deliberately strict, so advance just beyond the computed
      // dueAt rather than relying on equality at the boundary.
      now = DateTime.utc(2026, 7, 19, 18, 0, 1);
      final afterDueAt = await readBallot();
      expect(afterDueAt.instanceId, ballotId);
      expect(
        afterDueAt.instanceData['dueAt'],
        beforeDueAt.instanceData['dueAt'],
      );
      expect(afterDueAt.instanceData['isExpiringSoon'], isTrue);
    },
  );
}
