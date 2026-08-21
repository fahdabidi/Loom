/// specVersion 4's identity rules — `roleId` / `fanId`, `audience`, and the
/// comparison check that makes the split worth having.
///
/// The last group is the point of the whole migration: `$viewer == 'masjid-admin'`
/// parses, never matches, and produces no diagnostic under the old scheme. Three
/// formulas in the real corpus are broken by exactly that today.
library;

import 'package:loom_ux_judges/src/validator/community_package_validator.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show currentCommunitySpecVersion;
import 'package:test/test.dart';

Map<String, Object?> _v4({
  List<Map<String, Object?>>? roles,
  Map<String, Object?>? workflow,
  Map<String, Object?>? appShell,
  Map<String, Object?>? extraExperience,
}) => {
  'specVersion': currentCommunitySpecVersion,
  'experience': {
    'roles':
        roles ??
        [
          {'roleId': 'member', 'label': 'Member'},
          {'roleId': 'organizer', 'label': 'Organizer'},
        ],
    'workflowDefinitions': {'thing': workflow ?? _workflow()},
    if (extraExperience != null) ...extraExperience,
  },
  if (appShell != null) 'appShell': appShell,
};

Map<String, Object?> _workflow({
  Map<String, Object?>? binding,
  List<Map<String, Object?>>? transitions,
  Map<String, Object?>? schema,
}) => {
  'initialState': 'open',
  'states': {
    'open': {'label': 'Open'},
  },
  'transitions':
      transitions ??
      [
        {
          'id': 'do-thing',
          'label': 'Do',
          'from': ['open'],
          'to': null,
          'guard': {
            'allowedRoleIds': ['organizer'],
          },
        },
      ],
  if (schema != null) 'instanceDataSchema': schema,
  'renderBindings': [
    binding ??
        {
          'states': ['open'],
          'audience': 'any',
          'tabId': 'home',
          'cardSurfaceFamily': 'formEntry',
          'bindingKind': 'primary',
        },
  ],
};

List<String> _errors(Map<String, Object?> package) =>
    CommunityPackageValidator()
        .validate(package)
        .findings
        .where((f) => !f.isWarning)
        .map((f) => f.type)
        .toList();

void main() {
  group('version stamps', () {
    test('a specVersion 4 package is accepted', () {
      expect(_errors(_v4()), isNot(contains('unsupported_schema_version')));
    });

    test('an unsupported specVersion fails rather than best-effort-parses', () {
      final types = _errors(
        _v4()..['specVersion'] = currentCommunitySpecVersion + 1,
      );
      expect(types, contains('unsupported_schema_version'));
    });

    test('a leftover legacy stamp alongside specVersion is an error', () {
      // A package declaring two versions of itself is exactly the drift the
      // collapse removed.
      final package = _v4()..['schemaVersion'] = 1;
      expect(_errors(package), contains('legacy_version_stamp'));
    });

    test('legacy packages fail fast with v4 re-authoring guidance', () {
      final legacy = {
        'schemaVersion': 1,
        'experience': {
          'experienceSchemaVersion': 2,
          'workflowGrammarVersion': 1,
          'personas': [
            {'personaId': 'member', 'label': 'Member'},
          ],
          'workflowDefinitions': {
            'thing': {
              'initialState': 'open',
              'states': {
                'open': {'label': 'Open'},
              },
              'transitions': [
                {
                  'id': 'do-thing',
                  'label': 'Do',
                  'from': ['open'],
                  'to': null,
                  'guard': {
                    'allowedPersonaIds': ['member'],
                  },
                },
              ],
              'renderBindings': [
                {
                  'states': ['open'],
                  'role': 'any',
                  'tabId': 'home',
                  'cardSurfaceFamily': 'formEntry',
                  'bindingKind': 'primary',
                },
              ],
            },
          },
        },
      };
      final report = CommunityPackageValidator().validate(legacy);
      expect(
        report.errors.map((finding) => finding.type),
        everyElement('legacy_version_stamp'),
      );
      expect(report.errors, hasLength(3));
      expect(
        report.errors.map((finding) => finding.message),
        everyElement(
          allOf(
            contains('specVersion: $currentCommunitySpecVersion'),
            contains('docs/references/reference/identity-types.md'),
          ),
        ),
      );
    });
  });

  group('renamed identity keys', () {
    test('allowedPersonaIds is rejected', () {
      final types = _errors(
        _v4(
          workflow: _workflow(
            transitions: [
              {
                'id': 'do-thing',
                'label': 'Do',
                'from': ['open'],
                'to': null,
                'guard': {
                  'allowedPersonaIds': ['organizer'],
                },
              },
            ],
          ),
        ),
      );
      expect(types, contains('legacy_identity_key'));
    });

    test('renderBindings[].role is rejected in favour of audience', () {
      final types = _errors(
        _v4(
          workflow: _workflow(
            binding: {
              'states': ['open'],
              'role': 'any',
              'tabId': 'home',
              'cardSurfaceFamily': 'formEntry',
              'bindingKind': 'primary',
            },
          ),
        ),
      );
      expect(types, contains('legacy_identity_key'));
    });

    test(
      'person-shaped instance keys with a PersonaId suffix are rejected',
      () {
        final types = _errors(
          _v4(
            workflow: _workflow(
              schema: {
                'recipientPersonaId': {'type': 'fanId'},
              },
            ),
          ),
        );
        expect(types, contains('legacy_identity_key'));
      },
    );

    test('legacy personaId field types are rejected with v4 guidance', () {
      final report = CommunityPackageValidator().validate(
        _v4(
          workflow: _workflow(
            schema: {
              'recipientFanId': {'type': 'personaId'},
            },
          ),
        ),
      );
      final findings = report.errors
          .where((finding) => finding.type == 'legacy_identity_type')
          .toList();
      expect(findings, hasLength(1));
      expect(
        findings.single.message,
        contains('specVersion: $currentCommunitySpecVersion'),
      );
      expect(
        findings.single.message,
        contains('docs/references/reference/identity-types.md'),
      );
    });

    test(
      'appShell visiblePersonaIds is rejected — it is outside experience',
      () {
        // The key that made the three-number scheme fail: appShell is a root
        // sibling of experience, governed by neither the experience nor the
        // grammar stamp.
        final types = _errors(
          _v4(
            appShell: {
              'tabs': [
                {
                  'tabId': 'home',
                  'label': 'Home',
                  'visiblePersonaIds': ['member'],
                },
              ],
            },
          ),
        );
        expect(types, contains('legacy_identity_key'));
      },
    );

    test('a clean v4 package trips none of these', () {
      final types = _errors(
        _v4(
          appShell: {
            'tabs': [
              {
                'tabId': 'home',
                'label': 'Home',
                'visibleRoleIds': ['member'],
              },
            ],
          },
        ),
      );
      expect(types, isNot(contains('legacy_identity_key')));
    });
  });

  group('comparing an identity to a role', () {
    Map<String, Object?> withFormula(String formula) => _v4(
      workflow: _workflow(
        schema: {
          'payerFanId': {'type': 'fanId'},
          'visible': {'type': 'bool', 'formula': formula},
        },
      ),
    );

    test('the real Masjid Nur shape is caught', () {
      expect(
        _errors(
          withFormula(r"$viewer == payerFanId || $viewer == 'organizer'"),
        ),
        contains('identity_compared_to_role'),
      );
    });

    test('the reversed operand order is caught too', () {
      expect(
        _errors(withFormula(r"'organizer' == $actor")),
        contains('identity_compared_to_role'),
      );
    });

    test('comparing against a fanId field is fine', () {
      expect(
        _errors(withFormula(r'$viewer == payerFanId')),
        isNot(contains('identity_compared_to_role')),
      );
    });

    test('a literal that is not a declared role is not flagged', () {
      // Only a declared roleId is provably unsatisfiable. An arbitrary string
      // may be a legitimate fanId comparison.
      expect(
        _errors(withFormula(r"$viewer == 'fan_01H8XYZ'")),
        isNot(contains('identity_compared_to_role')),
      );
    });
  });
}
