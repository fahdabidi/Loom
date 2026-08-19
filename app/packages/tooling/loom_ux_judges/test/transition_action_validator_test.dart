/// Behaviour tests for permissions.md §8's `action` rules.
///
/// The spec-sync test proves the vocabularies match the document; these prove
/// the validator actually rejects what the document says is invalid. A rule
/// that never fires is indistinguishable from no rule at all.
library;

import 'package:loom_ux_judges/src/validator/community_package_validator.dart';
import 'package:loom_workflow_engine/src/archetypes/archetype_resolver.dart';
import 'package:test/test.dart';

/// Minimal package skeleton: enough envelope for the validator to reach the
/// workflow definitions, nothing more.
Map<String, Object?> _package(Map<String, Object?> workflowDefinitions) => {
  'schemaVersion': 1,
  'experience': {
    'experienceSchemaVersion': 2,
    'workflowGrammarVersion': 1,
    'personas': [
      {'personaId': 'member', 'label': 'Member'},
    ],
    'workflowDefinitions': workflowDefinitions,
  },
};

Map<String, Object?> _workflow({
  required String family,
  required List<Map<String, Object?>> transitions,
  Map<String, Object?>? responseTable,
  List<String> extraFamilies = const [],
}) => {
  'initialState': 'open',
  'states': {
    'open': {'label': 'Open'},
  },
  'transitions': transitions,
  'renderBindings': [
    {
      'states': ['open'],
      'role': 'any',
      'tabId': 'home',
      'cardSurfaceFamily': family,
      'bindingKind': 'primary',
      if (responseTable != null) 'responseTable': responseTable,
    },
    for (final extra in extraFamilies)
      {
        'states': ['open'],
        'role': 'any',
        'tabId': 'admin',
        'cardSurfaceFamily': extra,
        'bindingKind': 'summary',
      },
  ],
};

Map<String, Object?> _transition(String id, {String? action}) => {
  'id': id,
  if (action != null) 'action': action,
  'label': id,
  'from': ['open'],
  'to': null,
};

/// The four finding types §8's action rules can produce.
///
/// Deliberately narrowed to these: the skeletons below are minimal enough to
/// trip unrelated rules such as `stuck_state`, and asserting "no errors at all"
/// would make these tests fail for reasons that have nothing to do with the
/// behaviour under test.
const _actionRuleTypes = {
  'missing_transition_action',
  'unknown_transition_action',
  'unexpected_transition_action',
  'ambiguous_workflow_archetype',
};

List<String> _errorTypes(Map<String, Object?> package) =>
    CommunityPackageValidator()
        .validate(package)
        .findings
        .where((f) => !f.isWarning && _actionRuleTypes.contains(f.type))
        .map((f) => f.type)
        .toList();

void main() {
  group('bespoke workflows require an action', () {
    test('a missing action is an error', () {
      final types = _errorTypes(
        _package({
          'club-event': _workflow(
            family: 'event-rsvp',
            transitions: [_transition('cancel-event')],
          ),
        }),
      );
      expect(types, contains('missing_transition_action'));
    });

    test('a missing action reports silent bookkeeping loss', () {
      final report = CommunityPackageValidator().validate(
        _package({
          'club-event': _workflow(
            family: 'event-rsvp',
            transitions: [_transition('cancel-event')],
          ),
        }),
      );
      final finding = report.findings.singleWhere(
        (finding) => finding.type == 'missing_transition_action',
      );

      expect(finding.message, contains('bookkeeping'));
      expect(finding.message, contains('silently'));
      expect(finding.message, isNot(contains('fail at runtime')));
      expect(finding.message, isNot(contains('runtime failure')));
    });

    test('an action outside the closed vocabulary is an error', () {
      final types = _errorTypes(
        _package({
          'club-event': _workflow(
            family: 'event-rsvp',
            transitions: [
              _transition('cancel-event', action: 'obliterate'),
            ],
          ),
        }),
      );
      expect(types, contains('unknown_transition_action'));
    });

    test('withdraw_vote is now rejected on votePoll', () {
      // Pinned: this action existed briefly on a premise the fixtures
      // disprove. cancel-vote calls the poll off for everyone, so it is
      // `close`.
      final types = _errorTypes(
        _package({
          'book-vote': _workflow(
            family: 'votePoll',
            transitions: [
              _transition('cancel-vote', action: 'withdraw_vote'),
            ],
          ),
        }),
      );
      expect(types, contains('unknown_transition_action'));
    });

    test('a valid action passes', () {
      final types = _errorTypes(
        _package({
          'club-event': _workflow(
            family: 'event-rsvp',
            transitions: [_transition('cancel-event', action: 'cancel')],
          ),
        }),
      );
      expect(types, isEmpty);
    });
  });

  group('generic workflows must not declare an action', () {
    test('an action on a generic family is an error', () {
      final types = _errorTypes(
        _package({
          'intake': _workflow(
            family: 'formEntry',
            transitions: [_transition('submit', action: 'create')],
          ),
        }),
      );
      expect(types, contains('unexpected_transition_action'));
    });

    test('`table` counts as generic, grid rendering notwithstanding', () {
      final types = _errorTypes(
        _package({
          'rankings': _workflow(
            family: 'table',
            transitions: [
              _transition('publish-ranking', action: 'publish'),
            ],
          ),
        }),
      );
      expect(types, contains('unexpected_transition_action'));
    });

    test('a bare generic transition passes', () {
      final types = _errorTypes(
        _package({
          'intake': _workflow(
            family: 'formEntry',
            transitions: [_transition('submit')],
          ),
        }),
      );
      expect(types, isEmpty);
    });
  });

  group('responseTable targets inherit their owner\'s archetype', () {
    Map<String, Object?> rsvpPair({String? responseAction}) => _package({
      'club-event': _workflow(
        family: 'event-rsvp',
        transitions: [_transition('cancel-event', action: 'cancel')],
        responseTable: {'workflowType': 'club-event-response'},
      ),
      'club-event-response': {
        'initialState': 'pending',
        'states': {
          'pending': {'label': 'Pending'},
        },
        'transitions': [
          _transition('respond-going', action: responseAction),
        ],
        // The shape that caused the bug: no bindings at all.
        'renderBindings': <Object?>[],
      },
    });

    test('a response workflow with no action is an error, not ignored', () {
      // Before §6 step 3b these derived nothing and passed silently, leaving
      // 26 real member actions ungated across five communities.
      expect(
        _errorTypes(rsvpPair()),
        contains('missing_transition_action'),
      );
    });

    test('it resolves against the inherited family\'s vocabulary', () {
      expect(_errorTypes(rsvpPair(responseAction: 'respond')), isEmpty);
      expect(
        _errorTypes(rsvpPair(responseAction: 'vote')),
        contains('unknown_transition_action'),
      );
    });

    test('an unbound workflow with no owner derives nothing', () {
      final types = _errorTypes(
        _package({
          'notification': {
            'initialState': 'unread',
            'states': {
              'unread': {'label': 'Unread'},
            },
            'transitions': [_transition('mark-read')],
            'renderBindings': <Object?>[],
          },
        }),
      );
      expect(types, isEmpty);
    });
  });

  group('mixed cardSurfaceFamily bindings', () {
    test('one bespoke family plus generic bindings is allowed', () {
      // The normal shape: a primary bespoke surface plus a summary elsewhere.
      // Data Portability alone has eight workflows like this.
      final types = _errorTypes(
        _package({
          'export': _workflow(
            family: 'exportWizard',
            extraFamilies: ['statusTimeline'],
            transitions: [_transition('cancel-export', action: 'cancel')],
          ),
        }),
      );
      expect(types, isEmpty);
    });

    test('two bespoke families are fine when the actions disambiguate', () {
      // Tabletop's tournament-event: an event-rsvp card plus a votePoll
      // attendance summary. `respond` exists only in event-rsvp, so the
      // archetype is decidable and the dispatcher special-cases it by name.
      final types = _errorTypes(
        _package({
          'tournament-event': _workflow(
            family: 'event-rsvp',
            extraFamilies: ['votePoll'],
            transitions: [_transition('rsvp-going', action: 'respond')],
          ),
        }),
      );
      expect(types, isEmpty);
    });

    test('two bespoke families are an error when actions fit both', () {
      // `view` and `create` exist in both vocabularies, so nothing decides it.
      final types = _errorTypes(
        _package({
          'ambiguous': _workflow(
            family: 'event-rsvp',
            extraFamilies: ['votePoll'],
            transitions: [_transition('open-thing', action: 'create')],
          ),
        }),
      );
      expect(types, contains('ambiguous_workflow_archetype'));
    });
  });

  group('permission ids', () {
    test('are <archetype_snake_case>.<action>', () {
      const resolver = ArchetypeResolver();
      expect(resolver.permissionId('event-rsvp', 'respond'),
          equals('event_rsvp.respond'));
      expect(resolver.permissionId('searchAiAnswer', 'moderate'),
          equals('search_ai_answer.moderate'));
      expect(resolver.permissionId('table', 'view'), equals('table.view'));
    });
  });
}
