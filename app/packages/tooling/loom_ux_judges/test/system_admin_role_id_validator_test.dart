/// P6 — a package may not declare the governance role's id.
///
/// `installCommunityPackage` merges a package role whose `roleId` equals the
/// generated `<handle>-admin` id without a conflict: the domain loops create
/// and grant it, the governance loop overwrites with the five `community.*`
/// ids, and the deletion sweep spares it. Existing holders of that domain role
/// silently become community administrators. The validator surfaces it at
/// authoring time; the backend (P3) stays authoritative.
///
/// The rule is deliberately scoped to the exact resolved admin id, never to
/// name shape — see `permissions.md` §7 and the P6 ticket.
library;

import 'package:loom_ux_judges/src/validator/community_package_validator.dart';
import 'package:loom_ux_judges/src/validator/generated_skill_version.dart';
import 'package:loom_ux_judges/src/validator/workflow_validator.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show currentCommunitySpecVersion;
import 'package:test/test.dart';

const findingType = 'declared_role_shadows_system_admin';

Map<String, dynamic> _package({
  required String communityHandle,
  required List<Map<String, dynamic>> roles,
}) => <String, dynamic>{
  'specVersion': currentCommunitySpecVersion,
  'skillVersion': currentSkillVersion,
  'communityHandle': communityHandle,
  'experience': <String, dynamic>{
    'roles': roles,
    'workflowDefinitions': <String, dynamic>{
      'thing': <String, dynamic>{
        'initialState': 'open',
        'states': <String, dynamic>{
          'open': <String, dynamic>{'label': 'Open'},
          'done': <String, dynamic>{'label': 'Done', 'isTerminal': true},
        },
        'transitions': <dynamic>[
          <String, dynamic>{
            'id': 'finish',
            'label': 'Finish',
            'from': <String>['open'],
            'to': 'done',
          },
        ],
        'instanceDataSchema': <String, dynamic>{},
      },
    },
    'workflowInstances': <dynamic>[],
  },
};

List<ValidationFinding> _findings(Map<String, dynamic> package) =>
    CommunityPackageValidator()
        .validate(package)
        .findings
        .where((finding) => finding.type == findingType)
        .toList();

void main() {
  test('fires when a declared roleId equals the resolved system-admin id', () {
    final findings = _findings(
      _package(
        communityHandle: 'garden-club',
        roles: <Map<String, dynamic>>[
          <String, dynamic>{'roleId': 'garden-club-admin', 'label': 'Admin'},
          <String, dynamic>{'roleId': 'garden-member', 'label': 'Member'},
        ],
      ),
    );

    expect(findings, hasLength(1));
    final finding = findings.single;
    expect(finding.isWarning, isFalse);
    expect(finding.location, 'experience/roles[0]/roleId');
    expect(finding.message, contains('"garden-club-admin"'));
    expect(finding.message, contains('communityHandle "garden-club"'));
    expect(finding.message, contains('P3'));
  });

  test(
    'resolves the id from the vocabulary template, not a hardcoded suffix',
    () {
      // A handle whose admin id is not simply "<handle>_admin" or "<handle>-adm"
      // still resolves through `governance.adminRole.idTemplate`.
      final findings = _findings(
        _package(
          communityHandle: 'cedar-commons-hoa',
          roles: <Map<String, dynamic>>[
            <String, dynamic>{
              'roleId': 'cedar-commons-hoa-admin',
              'label': 'Board',
            },
          ],
        ),
      );

      expect(findings, hasLength(1));
      expect(findings.single.location, 'experience/roles[0]/roleId');
    },
  );

  test('does not fire on a label containing "Admin"', () {
    // Masjid Nur's domain role is legitimately labelled "Masjid Admin".
    final findings = _findings(
      _package(
        communityHandle: 'masjid-nur',
        roles: <Map<String, dynamic>>[
          <String, dynamic>{'roleId': 'owner', 'label': 'Masjid Admin'},
        ],
      ),
    );

    expect(findings, isEmpty);
  });

  test('does not fire on a domain roleId that merely ends in _admin', () {
    // Cedar Commons HOA's precedent role id was `cedar_commons_hoa_admin` — a
    // legitimate domain role, not the generated `cedar-commons-hoa-admin`.
    final findings = _findings(
      _package(
        communityHandle: 'cedar-commons-hoa',
        roles: <Map<String, dynamic>>[
          <String, dynamic>{
            'roleId': 'cedar_commons_hoa_admin',
            'label': 'Board',
          },
        ],
      ),
    );

    expect(findings, isEmpty);
  });

  test('does not fire when communityHandle is absent or blank', () {
    for (final handle in <String?>[null, '', '   ']) {
      final package = _package(
        communityHandle: 'placeholder',
        roles: <Map<String, dynamic>>[
          <String, dynamic>{'roleId': 'placeholder-admin', 'label': 'Admin'},
        ],
      );
      if (handle == null) {
        package.remove('communityHandle');
      } else {
        package['communityHandle'] = handle;
      }
      expect(
        _findings(package),
        isEmpty,
        reason: 'A blank handle resolves no admin id, so nothing can collide.',
      );
    }
  });
}
