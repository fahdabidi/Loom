import 'dart:convert';
import 'dart:io';

import 'package:loom_ux_judges/community_remote_migration.dart';
import 'package:loom_ux_judges/src/community_package_provenance.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Member Social Space derivation', () {
    late File fixture;
    late ParsedCommunityPackage package;
    late CommunityMigrationPlan plan;

    setUpAll(() async {
      fixture = _memberSocialFixture();
      package = await ParsedCommunityPackage.fromFile(fixture);
      plan = const CommunityMigrationDeriver().derive(package);
    });

    test('uses the existing workflow model parser for the real fixture', () {
      expect(package.workflowDefinitions, hasLength(6));
      expect(
        package.workflowDefinitions['platform-message-thread'],
        isA<LoomWorkflowStateMachine>(),
      );
      expect(
        package.workflowDefinitions['platform-message-thread']?.transitions,
        hasLength(7),
      );
    });

    test('parses specVersion 4 roles using roleId', () {
      expect(package.specVersion, currentCommunitySpecVersion);
      expect(
        package.roles
            .map((role) => (role.roleId, role.label, role.roleLabel))
            .toList(),
        [
          ('member', 'Member', 'Member'),
          ('moderator', 'Moderator', 'Moderator'),
        ],
      );
    });

    test('rejects a missing specVersion before parsing legacy shapes', () {
      final root = jsonDecode(jsonEncode(package.root)) as Map<String, dynamic>;
      root.remove('specVersion');
      final experience = root['experience'] as Map<String, dynamic>;
      experience.remove('roles');
      experience['per'
              'sonas'] =
          const <dynamic>[];

      expect(
        () => ParsedCommunityPackage.parse(jsonEncode(root)),
        throwsA(
          isA<FormatException>()
              .having(
                (error) => error.message,
                'message',
                contains('specVersion: $currentCommunitySpecVersion'),
              )
              .having(
                (error) => error.message,
                'guidance',
                contains('docs/references/reference/identity-types.md'),
              ),
        ),
      );
    });

    test('rejects pre-v4 specVersion before parsing its body', () {
      final root = jsonDecode(jsonEncode(package.root)) as Map<String, dynamic>;
      root['specVersion'] = currentCommunitySpecVersion - 1;
      final experience = root['experience'] as Map<String, dynamic>;
      experience.remove('roles');
      experience['per'
              'sonas'] =
          const <dynamic>[];

      expect(
        () => ParsedCommunityPackage.parse(jsonEncode(root)),
        throwsA(
          isA<FormatException>()
              .having(
                (error) => error.message,
                'message',
                contains(
                  'Unsupported specVersion '
                  '"${currentCommunitySpecVersion - 1}"',
                ),
              )
              .having(
                (error) => error.message,
                'guidance',
                contains('docs/references/reference/identity-types.md'),
              ),
        ),
      );
    });

    test('uses specVersion 4 as the install payload grammarVersion', () {
      expect(
        plan.installCommunityPackagePayload,
        containsPair('grammarVersion', currentCommunitySpecVersion),
      );
    });

    test('rejects a package without roles clearly', () {
      final root = jsonDecode(jsonEncode(package.root)) as Map<String, dynamic>;
      final experience = root['experience'] as Map<String, dynamic>;
      experience.remove('roles');

      expect(
        () => ParsedCommunityPackage.parse(jsonEncode(root)),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'experience.roles must not be empty.',
          ),
        ),
      );
    });

    test('derives createRoleIds from create-action byRoleIds', () {
      final workflows = _workflowsByType(plan);

      expect(
        {
          for (final entry in workflows.entries)
            entry.key: entry.value['createRoleIds'],
        },
        {
          'platform-message-thread': ['member'],
          'platform-connection': ['member'],
          'platform-blocked-target': <String>[],
          'platform-in-stream-ad': ['moderator'],
          'platform-top-banner-no-fill': ['moderator'],
          'platform-sensitive-no-fill': ['moderator'],
        },
      );
      expect(plan.cleanCreateActionCount, 0);
      expect(plan.flaggedCreateActionCount, 0);
    });

    test('cardSurfaceFamily matches an independent resolver call', () {
      final independentlyResolved = const ArchetypeResolver().resolveAll(
        package.rawWorkflowDefinitions,
      );
      final workflows = _workflowsByType(plan);

      for (final entry in independentlyResolved.entries) {
        expect(
          workflows[entry.key]?['cardSurfaceFamily'],
          entry.value.family,
          reason: entry.key,
        );
      }
    });

    test('passes through v4 role guards without legacy guard audits', () {
      expect(plan.cleanGuardCount, 0);
      expect(plan.flaggedGuardCount, 0);
      expect(plan.findings, isEmpty);

      final workflows = _workflowsByType(plan);
      final inStreamTransitions = {
        for (final transition
            in workflows['platform-in-stream-ad']?['transitions'] as List)
          (transition as Map)['transitionId']: transition,
      };
      expect(
        inStreamTransitions['record-impression'],
        containsPair('allowedRoleIds', ['member', 'moderator']),
      );
      expect(
        inStreamTransitions['dismiss-ad'],
        containsPair('allowedRoleIds', ['member']),
      );
    });

    test(
      'passes definitions through under specVersion 4 with role guards intact',
      () {
        expect(
          plan.replaceWorkflowDefinitionsPayload['specVersion'],
          currentCommunitySpecVersion,
        );
        final definitions =
            plan.replaceWorkflowDefinitionsPayload['definitions'] as Map;
        final messageThread = definitions['platform-message-thread'] as Map;
        final states = messageThread['states'] as Map;
        final draft = states['draft'] as Map;
        expect(
          draft['editGuard'],
          containsPair('actorEqualsField', {'key': 'participantAFanId'}),
        );
        expect(
          draft['editGuard'],
          isNot(
            contains(
              'allowedPer'
              'sonaIds',
            ),
          ),
        );

        final startThreadGuard =
            ((messageThread['transitions'] as List).first as Map)['guard']
                as Map;
        expect(startThreadGuard, containsPair('allowedRoleIds', ['member']));
        expect(
          startThreadGuard,
          isNot(
            contains(
              'allowedPer'
              'sonaIds',
            ),
          ),
        );

        final inStreamAd = definitions['platform-in-stream-ad'] as Map;
        final fullRosterGuard =
            ((inStreamAd['transitions'] as List).first as Map)['guard'] as Map;
        expect(
          fullRosterGuard,
          containsPair('allowedRoleIds', ['member', 'moderator']),
        );
        expect(
          fullRosterGuard,
          isNot(
            contains(
              'allowedPer'
              'sonaIds',
            ),
          ),
        );
      },
    );

    test(
      'default dry run constructs no live executor and makes no calls',
      () async {
        var factoryCalls = 0;
        final out = StringBuffer();
        final err = StringBuffer();

        final exitCode = await runCommunityRemoteMigration(
          [fixture.path],
          environment: const {},
          stdoutSink: out,
          stderrSink: err,
          liveExecutorFactory: (config) {
            factoryCalls++;
            return _FailIfCalledExecutor();
          },
        );

        expect(exitCode, 0);
        expect(factoryCalls, 0);
        expect(err.toString(), isEmpty);
        expect(out.toString(), contains('"networkCallsMade": 0'));
        expect(out.toString(), contains('=== findings report ==='));
      },
    );
  });

  group('another specVersion 4 package', () {
    late ParsedCommunityPackage package;

    setUpAll(() async {
      package = await ParsedCommunityPackage.fromFile(
        _communityFixture(
          'Loom_Communities_Workflow_Engine_GardenClub_Example.jsonc',
        ),
      );
    });

    test('preserves role and specVersion values', () {
      expect(package.communityId, 'community_garden_club');
      expect(package.communityHandle, 'garden-club');
      expect(package.displayName, 'Garden Club');
      expect(package.extensionId, 'ext_garden_club');
      expect(package.specVersion, currentCommunitySpecVersion);
      expect(
        package.roles
            .map((role) => (role.roleId, role.label, role.roleLabel))
            .toList(),
        [
          ('garden-member', 'Member', 'Member'),
          ('garden-coordinator', 'Coordinator', 'Coordinator'),
        ],
      );
    });
  });
}

Map<String, Map<String, Object?>> _workflowsByType(
  CommunityMigrationPlan plan,
) => {
  for (final workflow
      in plan.installCommunityPackagePayload['workflows'] as List)
    (workflow as Map)['workflowType'] as String: Map<String, Object?>.from(
      workflow,
    ),
};

File _memberSocialFixture() {
  return _communityFixture(
    'Loom_Communities_Workflow_Engine_MemberSocialSpace_Example.jsonc',
  );
}

File _communityFixture(String fileName) {
  final relativePath = 'docs/references/communities/$fileName';
  final candidate = File(
    '${locateCommunityPackageRepositoryRoot().path}/$relativePath',
  );
  if (candidate.existsSync()) return candidate;
  throw StateError('Could not find $relativePath from ${Directory.current}.');
}

class _FailIfCalledExecutor implements LiveMigrationExecutor {
  @override
  Future<MigrationExecutionResult> execute(
    ParsedCommunityPackage package,
    CommunityMigrationPlan plan,
  ) => throw StateError('Dry run must not call a live executor.');
}
