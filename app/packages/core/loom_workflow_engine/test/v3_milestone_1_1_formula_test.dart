import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

dynamic _eval(String formula, Map<String, dynamic> data) => evaluateFormula(
  formula,
  instanceData: data,
  viewerId: 'viewer-1',
  actorId: 'actor-1',
  clock: () => DateTime.utc(2026, 7, 12),
);

void main() {
  final rows = [
    {'choice': 'Catan', 'score': 5, 'member': 'a'},
    {'choice': 'Azul', 'score': 8, 'member': 'b'},
    {'choice': 'Catan', 'score': 3, 'member': 'a'},
  ];
  final data = <String, dynamic>{
    'rows': rows,
    'items': ['a', 'b', 'c'],
    'n': 4,
    'denominator': 2,
  };

  group('V3 Milestone 1.1 formula vocabulary', () {
    test('count', () => expect(_eval('count(rows)', data), 3));
    test('sum', () => expect(_eval('sum(rows, score)', data), 16));
    test('avg', () => expect(_eval('avg(rows, score)', data), 16 / 3));
    test('min', () => expect(_eval('min(rows, score)', data), 3));
    test('max', () => expect(_eval('max(rows, score)', data), 8));
    test(
      'countDistinct',
      () => expect(_eval('countDistinct(rows, member)', data), 2),
    );
    test(
      'groupCount',
      () => expect(_eval('groupCount(rows, choice)', data), {
        'Catan': 2,
        'Azul': 1,
      }),
    );
    test(
      'sortBy',
      () => expect(
        ((_eval('sortBy(rows, score, "desc")', data) as List).first
            as Map)['choice'],
        'Azul',
      ),
    );
    test(
      'argMaxKey',
      () => expect(
        _eval('argMaxKey(counts)', {
          'counts': {'Catan': 3, 'Azul': 2},
        }),
        'Catan',
      ),
    );
    test(
      'topKeys',
      () => expect(
        _eval('topKeys(counts)', {
          'counts': {'Catan': 3, 'Azul': 3},
        }),
        ['Catan', 'Azul'],
      ),
    );
    test('size', () => expect(_eval('size(items)', data), 3));
    test('contains', () => expect(_eval('contains(items, "b")', data), isTrue));
    test('indexOf', () => expect(_eval('indexOf(items, "b")', data), 1));
    test(
      'arithmetic',
      () => expect(_eval('n * 3 + denominator / 2 - 1', data), 12),
    );
    test('comparison', () => expect(_eval('n >= denominator', data), isTrue));
    test(
      'if',
      () =>
          expect(_eval('if(n > denominator, "open", "closed")', data), 'open'),
    );
    test('now', () => expect(_eval('now()', data), DateTime.utc(2026, 7, 12)));
    test(
      'daysBetween',
      () => expect(_eval('daysBetween("2026-07-10", "2026-07-12")', data), 2),
    );
    test('daysUntil', () => expect(_eval('daysUntil("2026-07-15")', data), 3));
    test(
      'isBefore',
      () => expect(_eval('isBefore("2026-07-10", "2026-07-12")', data), isTrue),
    );
    test(
      'isAfter',
      () => expect(_eval('isAfter("2026-07-12", "2026-07-10")', data), isTrue),
    );
    test('isPast', () => expect(_eval('isPast("2026-07-11")', data), isTrue));
    test('combineDateAndTime combines a date and valid time', () {
      expect(
        _eval('combineDateAndTime(eventDate, eventTime)', {
          'eventDate': '2026-07-20',
          'eventTime': '19:30',
        }),
        DateTime(2026, 7, 20, 19, 30),
      );
    });
    test('combineDateAndTime defaults an absent time to midnight', () {
      expect(
        _eval('combineDateAndTime(eventDate, eventTime)', {
          'eventDate': '2026-07-20',
        }),
        DateTime(2026, 7, 20),
      );
      expect(
        _eval('combineDateAndTime(eventDate)', {'eventDate': '2026-07-20'}),
        DateTime(2026, 7, 20),
      );
    });
    test('combineDateAndTime fails closed for invalid time values', () {
      for (final time in const ['7:0', '24:00', '23:60']) {
        expect(
          _eval('combineDateAndTime(eventDate, eventTime)', {
            'eventDate': '2026-07-20',
            'eventTime': time,
          }),
          isNull,
        );
      }
      expect(
        _eval('combineDateAndTime(eventDate, eventTime)', {
          'eventDate': 'not-a-date',
          'eventTime': '19:30',
        }),
        isNull,
      );
    });
    test('combineDateAndTime propagates a null or missing date', () {
      expect(
        _eval('combineDateAndTime(eventDate, eventTime)', {
          'eventTime': '19:30',
        }),
        isNull,
      );
      expect(
        _eval('combineDateAndTime(null, eventTime)', {'eventTime': '19:30'}),
        isNull,
      );
    });
    test(r'$viewer and $actor resolve as runtime values', () {
      expect(
        _eval(
          r'if($viewer == "viewer-1" && $actor == "actor-1", "yes", "no")',
          data,
        ),
        'yes',
      );
    });
  });

  test(
    'computed chain reads computed dependencies and re-evaluates changed input',
    () {
      const formulas = <String, String?>{
        'voteCounts': 'groupCount(ballots, choice)',
        'winner': 'argMaxKey(voteCounts)',
        'tiedCandidates': 'topKeys(voteCounts)',
        'isTie': 'size(tiedCandidates) > 1',
      };
      final first = evaluateComputedFields(
        instanceData: {
          'ballots': [
            {'choice': 'Catan'},
            {'choice': 'Azul'},
            {'choice': 'Catan'},
          ],
        },
        formulas: formulas,
      );
      expect(first['winner'], 'Catan');
      expect(first['isTie'], isFalse);
      final changed = evaluateComputedFields(
        instanceData: {
          'ballots': [
            {'choice': 'Catan'},
            {'choice': 'Azul'},
          ],
        },
        formulas: formulas,
      );
      expect(changed['tiedCandidates'], ['Catan', 'Azul']);
      expect(changed['isTie'], isTrue);
    },
  );

  test(
    'LocalWorkflowEngine computes reminderAt from combined event date and time',
    () async {
      final machine = LoomWorkflowStateMachine.fromJson({
        'initialState': 'open',
        'states': {
          'open': {'label': 'Open'},
        },
        'transitions': <Map<String, dynamic>>[],
        'renderBindings': [
          {
            'states': ['open'],
            'audience': 'any',
            'tabId': 'calendar',
            'cardSurfaceFamily': 'event-rsvp',
            'bindingKind': 'primary',
          },
        ],
        'instanceDataSchema': {
          'title': {'type': 'text', 'required': true},
          'eventDate': {'type': 'date', 'required': true},
          'eventTime': {'type': 'time', 'required': true},
          'reminderOffsetHours': {'type': 'number'},
          'reminderAt': {
            'type': 'date',
            'formula':
                'subtractHours(combineDateAndTime(eventDate, eventTime), reminderOffsetHours)',
          },
        },
      }, 'synthetic-event');
      final database = WorkflowDatabase.memory();
      final api = LocalWorkflowEngineApi(
        db: database,
        communityId: 'combine-date-time-formula',
      )..registerDefinition(machine);

      await api.createInstance(
        workflowType: 'synthetic-event',
        personaId: 'organizer',
        initialInstanceData: {
          'title': 'Evening game',
          'eventDate': '2026-07-20',
          'eventTime': '19:30',
          'reminderOffsetHours': 24,
        },
      );

      final page = await api.queryInstances(
        tabId: 'calendar',
        personaId: 'member',
        limit: 10,
      );
      expect(
        page.items.single.instanceData['reminderAt'],
        DateTime(2026, 7, 19, 19, 30),
      );
      database.close();
    },
  );

  test('date-dependent computed fields preserve an absent optional date', () {
    final computed = evaluateComputedFields(
      instanceData: <String, dynamic>{'reminderOffset': 'one-week'},
      formulas: const <String, String?>{
        'dueAt':
            "subtractHours(deadline, if(reminderOffset == 'one-week', 168, 0))",
        'isExpiringSoon': 'isPast(dueAt)',
      },
      clock: () => DateTime.utc(2026, 7, 12),
    );

    expect(computed, containsPair('dueAt', isNull));
    expect(computed, containsPair('isExpiringSoon', isNull));
  });

  test('date functions remain strict for non-null invalid values', () {
    expect(
      () => _eval('subtractHours(42, 1)', const <String, dynamic>{}),
      throwsA(isA<FormulaEvaluationException>()),
    );
    expect(
      () => _eval('isPast(42)', const <String, dynamic>{}),
      throwsA(isA<FormulaEvaluationException>()),
    );
  });

  test(
    'LocalWorkflowEngineApi exposes computed values on reads and blocks writes',
    () async {
      final machine = LoomWorkflowStateMachine.fromJson({
        'initialState': 'open',
        'states': {
          'open': {
            'label': 'Open',
            'editableFields': ['ballots'],
          },
        },
        'transitions': <Map<String, dynamic>>[],
        'instanceDataSchema': {
          'ballots': {'type': 'list', 'writableBy': 'formEntry'},
          'voteCounts': {
            'type': 'map',
            'formula': 'groupCount(ballots, choice)',
          },
          'winner': {'type': 'string', 'formula': 'argMaxKey(voteCounts)'},
        },
      }, 'vote');
      final api = LocalWorkflowEngineApi(
        db: WorkflowDatabase.memory(),
        communityId: 'test',
      );
      api.registerDefinition(machine);
      final id = await api.createInstance(
        workflowType: 'vote',
        personaId: 'organizer',
        initialInstanceData: {
          'ballots': [
            {'choice': 'Catan'},
            {'choice': 'Azul'},
            {'choice': 'Catan'},
          ],
        },
      );
      final page = await api.queryInstances(tabId: 'home', personaId: 'viewer');
      expect(page.items.single.instanceData['winner'], 'Catan');
      await expectLater(
        api.updateInstanceFields(
          workflowType: 'vote',
          instanceId: id,
          personaId: 'organizer',
          fieldUpdates: {'winner': 'Azul'},
        ),
        throwsA(isA<WorkflowAuthorizationError>()),
      );
    },
  );
}
