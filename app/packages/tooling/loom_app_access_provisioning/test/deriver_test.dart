import 'dart:io';

import 'package:loom_app_access_provisioning/loom_app_access_provisioning.dart';
import 'package:loom_ux_judges/community_remote_migration.dart';
import 'package:test/test.dart';

void main() {
  late List<ParsedCommunityPackage> packages;
  late AppAccessProvisioningPlan plan;

  setUpAll(() async {
    packages = await const ShippedCommunityPackageLoader().loadDirectory(
      Directory('../../../../docs/references/communities'),
    );
    plan = const AppAccessProvisioningDeriver().deriveAll(packages);
  });

  test('Cedar uses package role ids exactly and never the stale admin id', () {
    final cedar = _community(plan, 'community_cedar_commons_hoa');
    expect(
      cedar.request.roles.map((role) => (role.roleId, role.label)).toList(),
      [('hoa-member', 'Homeowner'), ('hoa-board', 'Board')],
    );
    expect(plan.encode(), isNot(contains('cedar_commons_hoa_admin')));
  });

  test(
    'all 11 packages build one installation request with every declared role',
    () {
      expect(packages, hasLength(11));
      expect(plan.communities, hasLength(11));
      for (final package in packages) {
        final entry = _community(plan, package.communityId);
        expect(entry.request.communityHandle, package.communityHandle);
        expect(entry.request.grammarVersion, package.specVersion);
        expect(
          entry.request.roles.map((role) => role.roleId).toSet(),
          equals(package.roles.map((role) => role.roleId).toSet()),
          reason: package.sourcePath,
        );
      }
    },
  );

  test('shipped role ids remain globally unique', () {
    final roleIds = [
      for (final community in plan.communities)
        for (final role in community.request.roles) role.roleId,
    ];
    expect(roleIds.toSet(), hasLength(roleIds.length));
  });

  test('Cedar facility reservation uses the union of create byRoleIds', () {
    final cedar = _community(plan, 'community_cedar_commons_hoa');
    final reservation = cedar.request.workflows.singleWhere(
      (workflow) => workflow.workflowType == 'hoa-facility-reservation',
    );
    expect(reservation.cardSurfaceFamily, 'event-rsvp');
    expect(reservation.createRoleIds, ['hoa-board', 'hoa-member']);
  });

  test('no generated installation request contains permissionIds', () {
    expect(_containsKey(plan.toJson(), 'permissionIds'), isFalse);
  });

  test(
    'a transition with no declared action serializes without an action key',
    () {
      final transition = plan.communities
          .expand((community) => community.request.workflows)
          .expand((workflow) => workflow.transitions)
          .firstWhere((transition) => transition.action == null);

      final json = transition.toJson();
      expect(json, isNot(contains('action')));
      expect(json['tone'], transition.tone);
      expect(json['isTerminal'], transition.isTerminal);
    },
  );
}

CommunityInstallationPlanEntry _community(
  AppAccessProvisioningPlan plan,
  String communityId,
) => plan.communities.singleWhere(
  (community) => community.communityId == communityId,
);

bool _containsKey(Object? value, String key) {
  if (value is Map) {
    return value.containsKey(key) ||
        value.values.any((child) => _containsKey(child, key));
  }
  if (value is List) return value.any((child) => _containsKey(child, key));
  return false;
}
