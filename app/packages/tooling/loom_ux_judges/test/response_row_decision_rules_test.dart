// Guards the response-row decisions (D1, D3/D6, D4) so they cannot be quietly
// undone by a later refactor.
//
// These were approved deliberately and written into `archetypes/event-rsvp.md`,
// `archetypes/CONTRACTS.md` and `guide/05-validation.md` -- but until this file
// existed, *nothing failed* if the rules were deleted from the validator. Docs
// drift and code gets reverted; a red test is what makes a decision durable.
//
// D1  a `withdraw_response` must not duplicate a concurrently-offered `respond`
// D6  a terminal transition must sweep every non-terminal response state
// D3  the sweep rule is a WARNING until Phase F, then ratchets to an error
// D4  response tables are exempt from `no_creation_path_for_editable_type`

import 'package:loom_ux_judges/src/validator/community_package_validator.dart';
import 'package:test/test.dart';

Map<String, dynamic> _responseDefinition() => <String, dynamic>{
  'initialState': 'pending',
  'states': <String, dynamic>{
    'pending': <String, dynamic>{'label': 'No response'},
    'going': <String, dynamic>{'label': 'Going'},
    'declined': <String, dynamic>{'label': 'Not going'},
    'cancelled': <String, dynamic>{'label': 'Cancelled', 'isTerminal': true},
  },
  'instanceDataSchema': <String, dynamic>{
    'eventId': <String, dynamic>{'type': 'text', 'writableBy': 'effect'},
  },
  'transitions': <dynamic>[
    <String, dynamic>{
      'id': 'respond-going',
      'label': 'Going',
      'action': 'respond',
      'from': <String>['pending', 'declined'],
      'to': 'going',
      'guard': <String, dynamic>{
        'allowedRoleIds': <String>['member'],
      },
    },
    <String, dynamic>{
      'id': 'respond-declined',
      'label': 'Not going',
      'action': 'respond',
      'from': <String>['pending', 'going'],
      'to': 'declined',
      'guard': <String, dynamic>{
        'allowedRoleIds': <String>['member'],
      },
    },
    <String, dynamic>{
      'id': 'event-cancelled',
      'label': 'Event cancelled',
      'action': 'cancel',
      'from': <String>['pending', 'going', 'declined'],
      'to': 'cancelled',
      'guard': <String, dynamic>{
        'allowedRoleIds': <String>['organizer'],
      },
    },
  ],
};

/// `sweptStates` are the `$state` filters the event's cancel transition
/// cascades over. Empty means it does not sweep at all.
Map<String, dynamic> _eventDefinition({
  required List<String> sweptStates,
  List<Map<String, dynamic>> extraResponseTransitions = const [],
}) => <String, dynamic>{
  'initialState': 'open',
  'states': <String, dynamic>{
    'open': <String, dynamic>{'label': 'Open'},
    'cancelled': <String, dynamic>{'label': 'Cancelled', 'isTerminal': true},
  },
  'instanceDataSchema': const <String, dynamic>{},
  'renderBindings': <dynamic>[
    <String, dynamic>{
      'states': <String>['open'],
      'audience': 'any',
      'tabId': 'calendar',
      'cardSurfaceFamily': 'event-rsvp',
      'bindingKind': 'summary',
      'responseTable': <String, dynamic>{
        'workflowType': 'event-response',
        'eventField': 'eventId',
        'pendingStates': <String>['pending'],
      },
    },
  ],
  'transitions': <dynamic>[
    <String, dynamic>{
      'id': 'cancel-event',
      'label': 'Cancel',
      'action': 'cancel',
      'from': <String>['open'],
      'to': 'cancelled',
      'tone': 'destructive',
      'guard': <String, dynamic>{
        'allowedRoleIds': <String>['organizer'],
      },
      'effects': <dynamic>[
        for (final state in sweptStates)
          <String, dynamic>{
            'op': 'transitionRelated',
            'transitionId': 'event-cancelled',
            'relatedQuery': <String, dynamic>{
              'workflowType': 'event-response',
              'filter': <String, dynamic>{'eventId': '{id}', r'$state': state},
            },
          },
      ],
    },
    ...extraResponseTransitions,
  ],
};

Map<String, dynamic> _package({
  required Map<String, dynamic> event,
  Map<String, dynamic>? response,
}) => <String, dynamic>{
  'specVersion': 4,
  'experience': <String, dynamic>{
    'workflowDefinitions': <String, dynamic>{
      'event-rsvp': event,
      'event-response': response ?? _responseDefinition(),
    },
    'workflowInstances': <dynamic>[],
  },
};

List<String> _types(Map<String, dynamic> package) => CommunityPackageValidator()
    .validate(package)
    .findings
    .map((finding) => finding.type)
    .toList();

String _messageFor(Map<String, dynamic> package, String type) =>
    CommunityPackageValidator()
        .validate(package)
        .findings
        .firstWhere((finding) => finding.type == type)
        .message;

void main() {
  group('D6 - the cancellation cascade must cover every live response state', () {
    test('no sweep at all is reported', () {
      final package = _package(event: _eventDefinition(sweptStates: const []));
      expect(_types(package), contains('orphaned_response_rows'));
      expect(
        _messageFor(package, 'orphaned_response_rows'),
        contains('does not sweep'),
      );
    });

    test('a partial sweep names exactly the states it missed', () {
      // Sweeps `going` only, leaving `pending` and `declined` live -- the shape
      // the original three-state worked example would have produced.
      final package = _package(
        event: _eventDefinition(sweptStates: const ['going']),
      );
      final message = _messageFor(package, 'orphaned_response_rows');
      expect(message, contains('"declined"'));
      expect(message, contains('"pending"'));
      // `cancelled` is terminal, so sweeping it is neither required nor missed.
      expect(message, isNot(contains('"cancelled"')));
    });

    test('sweeping every non-terminal state is clean', () {
      final package = _package(
        event: _eventDefinition(
          sweptStates: const ['pending', 'going', 'declined'],
        ),
      );
      expect(_types(package), isNot(contains('orphaned_response_rows')));
    });
  });

  group('D3 - the sweep rule stays a warning until Phase F', () {
    test('it is reported as a warning, not an error', () {
      final report = CommunityPackageValidator().validate(
        _package(event: _eventDefinition(sweptStates: const [])),
      );
      expect(
        report.warnings.any((f) => f.type == 'orphaned_response_rows'),
        isTrue,
        reason:
            'six shipped communities trip this; erroring makes the corpus '
            'undeliverable before Phase F regenerates it',
      );
      expect(
        report.errors.any((f) => f.type == 'orphaned_response_rows'),
        isFalse,
      );
    });
  });

  group('D1 - a withdraw must not duplicate a respond offered alongside it', () {
    Map<String, dynamic> withdrawTo(
      String target, {
      Map<String, dynamic>? guard,
      List<dynamic>? effects,
    }) {
      final response = _responseDefinition();
      (response['transitions'] as List).add(<String, dynamic>{
        'id': 'withdraw-rsvp',
        'label': 'Cancel RSVP',
        'action': 'withdraw_response',
        'from': <String>['going'],
        'to': target,
        'guard':
            guard ??
            <String, dynamic>{
              'allowedRoleIds': <String>['member'],
            },
        if (effects != null) 'effects': effects,
      });
      return response;
    }

    test('landing where a concurrently-offered respond lands is reported', () {
      // Riverside's exact shape: withdraw -> declined, from a state
      // respond-declined also serves, with the same guard.
      final package = _package(
        event: _eventDefinition(sweptStates: const []),
        response: withdrawTo('declined'),
      );
      expect(_types(package), contains('redundant_transition'));
    });

    test('an audit-only effect difference does not excuse it', () {
      // The reason effects are not compared: Riverside's two transitions differ
      // only by the string appended to responseHistory, which is invisible to
      // the member choosing between two identical-looking buttons.
      final package = _package(
        event: _eventDefinition(sweptStates: const []),
        response: withdrawTo(
          'declined',
          effects: <dynamic>[
            <String, dynamic>{
              'op': 'append',
              'key': 'responseHistory',
              'value': 'cancelled',
            },
          ],
        ),
      );
      expect(_types(package), contains('redundant_transition'));
    });

    test('landing on a pendingStates member is clean', () {
      final package = _package(
        event: _eventDefinition(sweptStates: const []),
        response: withdrawTo('pending'),
      );
      expect(_types(package), isNot(contains('redundant_transition')));
    });

    test('a different guard means the two are never offered together', () {
      // `cancel` vs `board-cancel`: same target, but no one sees both.
      final package = _package(
        event: _eventDefinition(sweptStates: const []),
        response: withdrawTo(
          'declined',
          guard: <String, dynamic>{
            'allowedRoleIds': <String>['organizer'],
          },
        ),
      );
      expect(_types(package), isNot(contains('redundant_transition')));
    });
  });

  group('D4 - response tables are exempt from the creation-path warning', () {
    test('a workflow reached through responseTable is not reported', () {
      // The response type has an effect-writable field and no create action
      // anywhere, which is precisely what the rule fires on -- except that
      // provisioning is archetype-owned, so there is deliberately nothing in
      // JSON to find (CONTRACTS.md, event-rsvp §4).
      final package = _package(
        event: _eventDefinition(
          sweptStates: const ['pending', 'going', 'declined'],
        ),
      );
      expect(
        _types(package),
        isNot(contains('no_creation_path_for_editable_type')),
      );
    });

    test('the exemption is scoped -- an unrelated type is still reported', () {
      final package = _package(
        event: _eventDefinition(
          sweptStates: const ['pending', 'going', 'declined'],
        ),
      );
      final experience = package['experience'] as Map<String, dynamic>;
      final definitions =
          experience['workflowDefinitions'] as Map<String, dynamic>;
      definitions['unrelated'] = <String, dynamic>{
        'initialState': 'open',
        'states': <String, dynamic>{
          'open': <String, dynamic>{'label': 'Open'},
        },
        'transitions': <dynamic>[],
        'instanceDataSchema': <String, dynamic>{
          'note': <String, dynamic>{'type': 'text', 'writableBy': 'formEntry'},
        },
      };
      expect(
        _types(package),
        contains('no_creation_path_for_editable_type'),
        reason: 'exempting every type would hide the real AP-13 defect',
      );
    });
  });
}
