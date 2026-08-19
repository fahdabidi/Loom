/// Decision D9 (`444c6a90`) visibility.fields authoring-time validation.
///
/// The resolver owns archetype selection; these tests exercise the validator's
/// mapping checks through the same raw package shape an author submits.
library;

import 'package:loom_ux_judges/src/validator/community_package_validator.dart';
import 'package:loom_ux_judges/src/validator/workflow_validator.dart';
import 'package:test/test.dart';

const _visibilityFindingTypes = {
  'unknown_key',
  'missing_visibility_fields',
  'dangling_visibility_field',
  'dangling_visibility_role',
  'invalid_visibility_principal',
  'invalid_parties_arity',
};

Map<String, Object?> _package(
  Map<String, Object?> workflow, {
  List<Map<String, Object?>> roles = const [],
}) => {
  'specVersion': 4,
  'experience': {
    'roles': roles,
    'workflowDefinitions': {'subject': workflow},
  },
};

Map<String, Object?> _workflow({
  required String family,
  Map<String, Object?> schema = const {},
  Map<String, Object?>? fields,
  String? visibilityDefault = 'membersOnly',
  Map<String, Object?>? visibilityReadGuard,
  Map<String, Object?>? stateReadGuard,
  bool includeVisibility = true,
}) => {
  'initialState': 'done',
  'states': {
    'done': {
      'label': 'Done',
      'isTerminal': true,
      if (stateReadGuard != null) 'readGuard': stateReadGuard,
    },
  },
  'transitions': <Object?>[],
  'instanceDataSchema': schema,
  if (includeVisibility)
    'visibility': {
      if (visibilityDefault != null) 'default': visibilityDefault,
      if (visibilityReadGuard != null) 'readGuard': visibilityReadGuard,
      if (fields != null) 'fields': fields,
    },
  'renderBindings': [
    {
      'states': ['done'],
      'audience': 'any',
      'tabId': 'home',
      'cardSurfaceFamily': family,
      'bindingKind': 'primary',
    },
  ],
};

List<ValidationFinding> _visibilityFindings(
  Map<String, Object?> workflow, {
  List<Map<String, Object?>> roles = const [],
}) =>
    CommunityPackageValidator()
        .validate(_package(workflow, roles: roles))
        .findings
        .where((finding) => _visibilityFindingTypes.contains(finding.type))
        .toList();

List<ValidationFinding> _ofType(
  Map<String, Object?> workflow,
  String type, {
  List<Map<String, Object?>> roles = const [],
}) =>
    _visibilityFindings(
      workflow,
      roles: roles,
    ).where((finding) => finding.type == type).toList();

void main() {
  group('unknown_key in visibility.fields', () {
    test(
      'owner model key on documentLibrary also leaves sharedWith missing',
      () {
        final findings = _visibilityFindings(
          _workflow(
            family: 'documentLibrary',
            visibilityDefault: 'guarded',
            visibilityReadGuard: const {},
            fields: const {'owner': 'documentOwnerFanId'},
          ),
        );
        final unknown = findings
            .where((finding) => finding.type == 'unknown_key')
            .toList();

        expect(unknown, hasLength(1));
        expect(unknown.single.isWarning, isFalse);
        expect(
          unknown.single.location,
          'experience/workflowDefinitions/subject/visibility/fields/owner',
        );
        expect(
          unknown.single.message,
          'Unknown key `owner` in visibility.fields. The parser ignores it. '
          'Legal keys for this position: `sharedWith`, `participants`, '
          '`parties`, `recipient`. `owner` is a visibility model value, not '
          'a `visibility.fields` key. This '
          "workflow's archetype requires the `sharedWith` key for its "
          'visibility model.',
        );
        expect(
          findings.where(
            (finding) => finding.type == 'missing_visibility_fields',
          ),
          hasLength(1),
        );
      },
    );

    const legalCases = <String, Object>{
      'sharedWith': 'sharedFanIds',
      'participants': ['participantFanId'],
      'parties': ['payerFanId', 'payeeFanId'],
      'recipient': 'recipientFanId',
    };

    for (final entry in legalCases.entries) {
      test('accepts the legal ${entry.key} key', () {
        expect(
          _ofType(
            _workflow(
              family: 'documentLibrary',
              schema: {
                'sharedFanIds': {'type': 'fanId[]'},
                'participantFanId': {'type': 'fanId'},
                'payerFanId': {'type': 'fanId'},
                'payeeFanId': {'type': 'fanId'},
                'recipientFanId': {'type': 'fanId'},
              },
              fields: {entry.key: entry.value},
            ),
            'unknown_key',
          ),
          isEmpty,
        );
      });
    }

    test('fires once for each of two unrecognised keys', () {
      final findings = _ofType(
        _workflow(
          family: 'documentLibrary',
          fields: const {'roles': 'boardRoleId', 'viewer': 'viewerFanId'},
        ),
        'unknown_key',
      );

      expect(findings, hasLength(2));
      expect(
        findings.map((finding) => finding.location),
        containsAll([
          'experience/workflowDefinitions/subject/visibility/fields/roles',
          'experience/workflowDefinitions/subject/visibility/fields/viewer',
        ]),
      );
      expect(
        findings
            .singleWhere((finding) => finding.location.endsWith('/roles'))
            .message,
        contains(
          '`roles` is a visibility model value, not a '
          '`visibility.fields` key.',
        ),
      );
    });

    test('fires only for an unrecognised key beside a legal key', () {
      final findings = _ofType(
        _workflow(
          family: 'documentLibrary',
          schema: {
            'sharedFanIds': {'type': 'fanId[]'},
          },
          fields: const {
            'sharedWith': 'sharedFanIds',
            'owner': 'documentOwnerFanId',
          },
        ),
        'unknown_key',
      );

      expect(findings, hasLength(1));
      expect(
        findings.single.location,
        'experience/workflowDefinitions/subject/visibility/fields/owner',
      );
    });

    test('does not fire when visibility.fields is absent', () {
      expect(
        _ofType(
          _workflow(family: 'documentLibrary'),
          'unknown_key',
        ),
        isEmpty,
      );
    });
  });

  group('missing_visibility_fields', () {
    const cases = {
      'owner_and_shared': ('documentLibrary', 'sharedWith', 'sharedFanIds'),
      'participants': ('discussionThread', 'participants', 'participantFanIds'),
      'parties': ('paymentCheckout', 'parties', 'payerFanId'),
    };

    for (final entry in cases.entries) {
      final (family, key, field) = entry.value;

      test('fires for ${entry.key} under guarded default without mapping', () {
        final findings = _ofType(
          _workflow(
            family: family,
            visibilityDefault: 'guarded',
            visibilityReadGuard: const {},
          ),
          'missing_visibility_fields',
        );

        expect(findings, hasLength(1));
        expect(findings.single.isWarning, isFalse);
        expect(
          findings.single.message,
          "The workflow's archetype uses a visibility model that reads "
          'instance-data identities (`owner_and_shared`, `participants`, '
          '`parties`, `recipient`) but declares no `visibility.fields` '
          'mapping. The engine cannot guess which field is a party rather '
          'than an audit actor.',
        );
      });

      test('does not fire for ${entry.key} when its mapping is present', () {
        final value = switch (key) {
          'sharedWith' => field,
          'participants' => [field],
          'parties' => [field, 'otherFanId'],
          _ => throw StateError('Unhandled visibility field $key'),
        };
        final schema = {
          field: {'type': key == 'sharedWith' ? 'fanId[]' : 'fanId'},
          if (key == 'parties') 'otherFanId': {'type': 'fanId'},
        };

        expect(
          _ofType(
            _workflow(family: family, schema: schema, fields: {key: value}),
            'missing_visibility_fields',
          ),
          isEmpty,
        );
      });
    }

    test('fires for workflow readGuard under membersOnly without mapping', () {
      final findings = _ofType(
        _workflow(family: 'discussionThread', visibilityReadGuard: const {}),
        'missing_visibility_fields',
      );

      expect(findings, hasLength(1));
    });

    test('fires for one state readGuard under membersOnly without mapping', () {
      final findings = _ofType(
        _workflow(family: 'discussionThread', stateReadGuard: const {}),
        'missing_visibility_fields',
      );

      expect(findings, hasLength(1));
    });

    test('does not fire for membersOnly without any readGuard', () {
      expect(
        _ofType(
          _workflow(family: 'discussionThread'),
          'missing_visibility_fields',
        ),
        isEmpty,
      );
    });

    test('does not fire for public without any readGuard', () {
      expect(
        _ofType(
          _workflow(family: 'discussionThread', visibilityDefault: 'public'),
          'missing_visibility_fields',
        ),
        isEmpty,
      );
    });

    test('does not fire when visibility is absent or default is unset', () {
      expect(
        _ofType(
          _workflow(family: 'discussionThread', includeVisibility: false),
          'missing_visibility_fields',
        ),
        isEmpty,
      );
      expect(
        _ofType(
          _workflow(family: 'discussionThread', visibilityDefault: null),
          'missing_visibility_fields',
        ),
        isEmpty,
      );
    });

    test('recipient omission is legal broadcast and does not fire', () {
      expect(
        _ofType(
          _workflow(family: 'notificationInbox'),
          'missing_visibility_fields',
        ),
        isEmpty,
      );
    });
  });

  group('dangling_visibility_field', () {
    final cases = <String, (String, Map<String, Object?>, String)>{
      'sharedWith': (
        'documentLibrary',
        {'sharedWith': 'missingFanIds'},
        'experience/workflowDefinitions/subject/visibility/fields/sharedWith',
      ),
      'participants entry': (
        'discussionThread',
        {
          'participants': ['declaredFanId', 'missingFanIds'],
        },
        'experience/workflowDefinitions/subject/visibility/fields/'
            'participants[1]',
      ),
      'parties entry': (
        'paymentCheckout',
        {
          'parties': ['declaredFanId', 'missingFanId'],
        },
        'experience/workflowDefinitions/subject/visibility/fields/parties[1]',
      ),
      'recipient': (
        'notificationInbox',
        {'recipient': 'missingFanId'},
        'experience/workflowDefinitions/subject/visibility/fields/recipient',
      ),
    };

    for (final entry in cases.entries) {
      test('fires for a dangling ${entry.key}', () {
        final (family, fields, location) = entry.value;
        final findings = _ofType(
          _workflow(
            family: family,
            schema: {
              'declaredFanId': {'type': 'fanId'},
            },
            fields: fields,
          ),
          'dangling_visibility_field',
        );

        expect(findings, hasLength(1));
        expect(findings.single.isWarning, isFalse);
        expect(findings.single.location, location);
        expect(
          findings.single.message,
          'A field named in `visibility.fields` is not declared in this '
          "workflow's `instanceDataSchema`.",
        );
      });
    }

    test('does not fire when every named field is declared', () {
      final schema = {
        'sharedFanIds': {'type': 'fanId[]'},
        'participantFanId': {'type': 'fanId'},
        'requesterFanId': {'type': 'fanId'},
        'reviewerFanId': {'type': 'fanId'},
        'recipientFanId': {'type': 'fanId'},
      };

      expect(
        _ofType(
          _workflow(
            family: 'documentLibrary',
            schema: schema,
            fields: {
              'sharedWith': 'sharedFanIds',
              'participants': ['participantFanId'],
              'parties': ['requesterFanId', 'reviewerFanId'],
              'recipient': 'recipientFanId',
            },
          ),
          'dangling_visibility_field',
        ),
        isEmpty,
      );
    });

    test('still fires outside identity layer when mapping is declared', () {
      final findings = _ofType(
        _workflow(
          family: 'documentLibrary',
          fields: {'sharedWith': 'missingFanIds'},
        ),
        'dangling_visibility_field',
      );

      expect(findings, hasLength(1));
    });
  });

  group('visibility party role principals', () {
    test('declared role passes without a dangling finding', () {
      final findings = _visibilityFindings(
        _workflow(
          family: 'paymentCheckout',
          schema: {
            'payerFanId': {'type': 'fanId'},
          },
          fields: {
            'parties': [
              'payerFanId',
              {'role': 'finance-admin'},
            ],
          },
        ),
        roles: const [
          {'roleId': 'finance-admin', 'label': 'Finance admin'},
        ],
      );

      expect(findings, isEmpty);
    });

    test('undeclared role emits dangling_visibility_role', () {
      final findings = _ofType(
        _workflow(
          family: 'paymentCheckout',
          schema: {
            'payerFanId': {'type': 'fanId'},
          },
          fields: {
            'parties': [
              'payerFanId',
              {'role': 'missing-role'},
            ],
          },
        ),
        'dangling_visibility_role',
      );

      expect(findings, hasLength(1));
      expect(findings.single.isWarning, isFalse);
      expect(
        findings.single.location,
        'experience/workflowDefinitions/subject/visibility/fields/parties[1]',
      );
      expect(
        findings.single.message,
        'A role named in `visibility.fields.parties` is not declared in '
        '`experience.roles[]`.',
      );
    });

    final malformedPrincipals = <String, Object?>{
      'empty string': '',
      'non-string non-map entry': 7,
      'map missing role': {'fanId': 'payerFanId'},
      'empty role': {'role': ''},
      'non-string role': {'role': 7},
      'role map with an unknown key': {
        'role': 'finance-admin',
        'fanId': 'payerFanId',
      },
    };
    for (final entry in malformedPrincipals.entries) {
      test('malformed ${entry.key} emits invalid_visibility_principal', () {
        final findings = _ofType(
          _workflow(
            family: 'paymentCheckout',
            schema: {
              'payerFanId': {'type': 'fanId'},
            },
            fields: {
              'parties': ['payerFanId', entry.value],
            },
          ),
          'invalid_visibility_principal',
          roles: const [
            {'roleId': 'finance-admin', 'label': 'Finance admin'},
          ],
        );

        expect(findings, hasLength(1));
        expect(findings.single.isWarning, isFalse);
        expect(
          findings.single.location,
          'experience/workflowDefinitions/subject/visibility/fields/parties[1]',
        );
      });
    }

    test('role objects do not emit dangling_visibility_field', () {
      expect(
        _ofType(
          _workflow(
            family: 'paymentCheckout',
            schema: {
              'payerFanId': {'type': 'fanId'},
            },
            fields: {
              'parties': [
                'payerFanId',
                {'role': 'finance-admin'},
              ],
            },
          ),
          'dangling_visibility_field',
        ),
        isEmpty,
      );
    });
  });

  group('invalid_parties_arity', () {
    for (final fields in const <List<String>>[
      [],
      ['one'],
      ['one', 'two', 'three'],
    ]) {
      test('fires when parties names ${fields.length} fields', () {
        final findings = _ofType(
          _workflow(
            family: 'paymentCheckout',
            schema: {
              for (final field in fields) field: {'type': 'fanId'},
            },
            fields: {'parties': fields},
          ),
          'invalid_parties_arity',
        );

        expect(findings, hasLength(1));
        expect(findings.single.isWarning, isFalse);
        expect(
          findings.single.message,
          '`visibility.fields.parties` does not name exactly two fields.',
        );
      });
    }

    test('does not fire when parties names exactly two fields', () {
      expect(
        _ofType(
          _workflow(
            family: 'paymentCheckout',
            schema: {
              'requesterFanId': {'type': 'fanId'},
              'reviewerFanId': {'type': 'fanId'},
            },
            fields: {
              'parties': ['requesterFanId', 'reviewerFanId'],
            },
          ),
          'invalid_parties_arity',
        ),
        isEmpty,
      );
    });

    test('counts a role principal as one of exactly two entries', () {
      expect(
        _ofType(
          _workflow(
            family: 'paymentCheckout',
            schema: {
              'payerFanId': {'type': 'fanId'},
            },
            fields: {
              'parties': [
                'payerFanId',
                {'role': 'finance-admin'},
              ],
            },
          ),
          'invalid_parties_arity',
          roles: const [
            {'roleId': 'finance-admin', 'label': 'Finance admin'},
          ],
        ),
        isEmpty,
      );
    });

    test('still fires outside identity layer when parties is declared', () {
      final findings = _ofType(
        _workflow(
          family: 'paymentCheckout',
          schema: {
            'payerFanId': {'type': 'fanId'},
          },
          fields: {
            'parties': ['payerFanId'],
          },
        ),
        'invalid_parties_arity',
      );

      expect(findings, hasLength(1));
    });
  });
}
