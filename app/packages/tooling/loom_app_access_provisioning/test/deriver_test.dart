import 'dart:convert';
import 'dart:io';

import 'package:loom_app_access_provisioning/loom_app_access_provisioning.dart';
import 'package:loom_ux_judges/community_remote_migration.dart';
import 'package:loom_workflow_service/loom_workflow_service.dart';
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
    expect(cedar.groupId, 'loom_communities_cedar_commons_hoa');
    expect(cedar.roles.map((role) => role.roleId), ['hoa-member', 'hoa-board']);
    expect(plan.encode(), isNot(contains('cedar_commons_hoa_admin')));
  });

  test(
    'all 11 packages derive and every declared role appears in its plan',
    () {
      expect(packages, hasLength(11));
      expect(plan.communities, hasLength(11));
      for (final package in packages) {
        final entry = _community(plan, package.communityId);
        expect(
          entry.roles.map((role) => role.roleId).toSet(),
          equals(package.roles.map((role) => role.roleId).toSet()),
          reason: package.sourcePath,
        );
      }
    },
  );

  test('derived role ids are globally unique', () {
    final roleIds = [
      for (final community in plan.communities)
        for (final role in community.roles) role.roleId,
    ];
    expect(roleIds.toSet(), hasLength(roleIds.length));
  });

  test(
    'community-group mapping covers every community and parses in service',
    () {
      expect(
        plan.communityGroupIds.keys.toSet(),
        equals({for (final package in packages) package.communityId}),
      );
      final resolver = MapCommunityGroupIdResolver.fromJson(
        jsonEncode(plan.communityGroupIds),
      );
      for (final community in plan.communities) {
        expect(
          resolver.resolveGroupId(community.communityId),
          community.groupId,
        );
      }
    },
  );

  test('Cedar event-RSVP workflow grants create to its expected roles', () {
    final cedar = _community(plan, 'community_cedar_commons_hoa');
    final reservation = cedar.workflows.singleWhere(
      (workflow) => workflow.workflowType == 'hoa-facility-reservation',
    );
    expect(reservation.family, 'event-rsvp');
    expect(reservation.createRoleIds, ['hoa-board', 'hoa-member']);
    for (final roleId in reservation.createRoleIds) {
      final role = cedar.roles.singleWhere((entry) => entry.roleId == roleId);
      expect(role.permissionIds, contains('event_rsvp.create'));
    }
  });

  test('creation classification keeps the exact provisional stopgap set', () {
    final fallbacks = [
      for (final community in plan.communities)
        for (final workflow in community.workflows)
          if (workflow.creationAuthority == 'unstated')
            '${community.displayName}/${workflow.workflowType}',
    ];
    expect(fallbacks, [
      'Camera Club/critique-submission',
      'Garden Club/plant-exchange-submission',
      'Masjid Nur/mosque-donation-payment',
      'Masjid Nur/mosque-care-request',
    ]);
    expect([
      for (final community in plan.communities)
        for (final workflow in community.workflows)
          if (workflow.creationAuthority == 'initial-state-transition')
            workflow,
    ], hasLength(84));
    expect([
      for (final community in plan.communities)
        for (final workflow in community.workflows)
          if (workflow.creationAuthority == 'system-created') workflow,
    ], hasLength(7));
  });
}

CommunityProvisioningEntry _community(
  AppAccessProvisioningPlan plan,
  String communityId,
) => plan.communities.singleWhere(
  (community) => community.communityId == communityId,
);
