import 'dart:convert';
import 'dart:io';

import 'package:loom_ux_judges/community_remote_migration.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

void main() {
  group('PersonaRoleTranslator', () {
    late PersonaRoleTranslator translator;

    setUp(() {
      translator = PersonaRoleTranslator(const [
        MigrationPersona(
          personaId: 'moderator-dakota',
          label: 'Dakota',
          roleLabel: 'Moderator',
        ),
        MigrationPersona(
          personaId: 'member-alex',
          label: 'Alex',
          roleLabel: 'Community Member',
        ),
        MigrationPersona(
          personaId: 'member-bailey',
          label: 'Bailey',
          roleLabel: 'Community Member',
        ),
      ]);
    });

    test('full persona set for one role translates cleanly', () {
      final audit = translator.translate(
        ['member-alex', 'member-bailey'],
        location: r'$.guard.allowedPersonaIds',
        source: RoleTranslationSource.guard,
      );

      expect(audit.isClean, isTrue);
      expect(audit.roleIds, ['community-member']);
      expect(audit.finding, isNull);
    });

    test('strict subset of one role is flagged instead of widened', () {
      final audit = translator.translate(
        ['member-alex'],
        location: r'$.guard.allowedPersonaIds',
        source: RoleTranslationSource.guard,
      );

      expect(audit.isClean, isFalse);
      expect(audit.roleIds, isNull);
      expect(audit.finding?.code, 'partial_role_persona_set');
      expect(audit.finding?.personaIds, ['member-alex']);
      expect(audit.finding?.roleLabels, ['Community Member']);
      expect(audit.finding?.message, contains('member-bailey'));
    });

    test('partial persona set from two roles is flagged as mixed', () {
      final audit = translator.translate(
        ['member-alex', 'moderator-dakota'],
        location: r'$.guard.allowedPersonaIds',
        source: RoleTranslationSource.guard,
      );

      expect(audit.isClean, isFalse);
      expect(audit.roleIds, isNull);
      expect(audit.finding?.code, 'mixed_role_labels');
      expect(audit.finding?.roleLabels, ['Community Member', 'Moderator']);
    });

    test('full persona roster across roles translates to sorted role ids', () {
      final audit = translator.translate(
        ['member-alex', 'member-bailey', 'moderator-dakota'],
        location: r'$.guard.allowedPersonaIds',
        source: RoleTranslationSource.guard,
      );

      expect(audit.isClean, isTrue);
      expect(audit.roleIds, ['community-member', 'moderator']);
      expect(audit.finding, isNull);
    });
  });

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
      expect(package.workflowGrammarVersion, 4);
      expect(
        package.personas
            .map(
              (persona) =>
                  (persona.personaId, persona.label, persona.roleLabel),
            )
            .toList(),
        [
          ('member', 'Member', 'Member'),
          ('moderator', 'Moderator', 'Moderator'),
        ],
      );
    });

    test('uses specVersion 4 as the install payload grammarVersion', () {
      expect(
        plan.installCommunityPackagePayload,
        containsPair('grammarVersion', 4),
      );
    });

    test('rejects a package with neither roles nor personas clearly', () {
      final root = jsonDecode(jsonEncode(package.root)) as Map<String, dynamic>;
      final experience = root['experience'] as Map<String, dynamic>;
      experience
        ..remove('roles')
        ..remove('personas');

      expect(
        () => ParsedCommunityPackage.parse(jsonEncode(root)),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'experience.roles or experience.personas must not be empty.',
          ),
        ),
      );
    });

    test('derives createRoleIds from create-action byPersonaIds', () {
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
      expect(plan.cleanCreateActionCount, 6);
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
        expect(plan.replaceWorkflowDefinitionsPayload['specVersion'], 4);
        final definitions =
            plan.replaceWorkflowDefinitionsPayload['definitions'] as Map;
        final messageThread = definitions['platform-message-thread'] as Map;
        final states = messageThread['states'] as Map;
        final draft = states['draft'] as Map;
        expect(
          draft['editGuard'],
          containsPair('actorEqualsField', {'key': 'participantAFanId'}),
        );
        expect(draft['editGuard'], isNot(contains('allowedPersonaIds')));

        final startThreadGuard =
            ((messageThread['transitions'] as List).first as Map)['guard']
                as Map;
        expect(startThreadGuard, containsPair('allowedRoleIds', ['member']));
        expect(startThreadGuard, isNot(contains('allowedPersonaIds')));

        final inStreamAd = definitions['platform-in-stream-ad'] as Map;
        final fullRosterGuard =
            ((inStreamAd['transitions'] as List).first as Map)['guard'] as Map;
        expect(
          fullRosterGuard,
          containsPair('allowedRoleIds', ['member', 'moderator']),
        );
        expect(fullRosterGuard, isNot(contains('allowedPersonaIds')));
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

  group('legacy package parsing', () {
    late ParsedCommunityPackage package;

    setUpAll(() async {
      package = await ParsedCommunityPackage.fromFile(
        _communityFixture(
          'Loom_Communities_Workflow_Engine_GardenClub_Example.jsonc',
        ),
      );
    });

    test('preserves persona and workflowGrammarVersion values', () {
      expect(package.communityId, 'community_garden_club');
      expect(package.communityHandle, 'garden-club');
      expect(package.displayName, 'Garden Club');
      expect(package.extensionId, 'ext_garden_club');
      expect(package.workflowGrammarVersion, 1);
      expect(
        package.personas
            .map(
              (persona) =>
                  (persona.personaId, persona.label, persona.roleLabel),
            )
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
  var directory = Directory.current;
  for (var depth = 0; depth < 8; depth++) {
    final candidate = File('${directory.path}/$relativePath');
    if (candidate.existsSync()) return candidate;
    directory = directory.parent;
  }
  throw StateError('Could not find $relativePath from ${Directory.current}.');
}

class _FailIfCalledExecutor implements LiveMigrationExecutor {
  @override
  Future<MigrationExecutionResult> execute(
    ParsedCommunityPackage package,
    CommunityMigrationPlan plan,
  ) => throw StateError('Dry run must not call a live executor.');
}
