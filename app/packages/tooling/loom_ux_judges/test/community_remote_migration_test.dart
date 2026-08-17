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
          personaId: 'member-alex',
          label: 'Alex',
          roleLabel: 'Community Member',
        ),
        MigrationPersona(
          personaId: 'member-bailey',
          label: 'Bailey',
          roleLabel: 'Community Member',
        ),
        MigrationPersona(
          personaId: 'moderator-dakota',
          label: 'Dakota',
          roleLabel: 'Moderator',
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

    test('personas from two roles are flagged instead of merged', () {
      final audit = translator.translate(
        ['member-alex', 'member-bailey', 'moderator-dakota'],
        location: r'$.guard.allowedPersonaIds',
        source: RoleTranslationSource.guard,
      );

      expect(audit.isClean, isFalse);
      expect(audit.roleIds, isNull);
      expect(audit.finding?.code, 'mixed_role_labels');
      expect(audit.finding?.roleLabels, ['Community Member', 'Moderator']);
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

    test('derives createRoleIds from create-action byPersonaIds', () {
      final workflows = _workflowsByType(plan);

      expect(workflows['platform-message-thread']?['createRoleIds'], [
        'member',
      ]);
      expect(workflows['platform-connection']?['createRoleIds'], ['member']);
      expect(workflows['platform-blocked-target']?['createRoleIds'], isEmpty);
      expect(plan.cleanCreateActionCount, 2);
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

    test('audits every real legacy guard and omits unsafe role guesses', () {
      expect(plan.cleanGuardCount, 14);
      expect(plan.flaggedGuardCount, 7);
      expect(
        plan.findings.map((finding) => finding.location),
        contains(
          r'$.experience.workflowDefinitions.platform-in-stream-ad.transitions[id=record-impression].guard.allowedPersonaIds',
        ),
      );

      final workflows = _workflowsByType(plan);
      final inStreamTransitions = {
        for (final transition
            in workflows['platform-in-stream-ad']?['transitions'] as List)
          (transition as Map)['transitionId']: transition,
      };
      expect(
        inStreamTransitions['record-impression'],
        isNot(contains('allowedRoleIds')),
      );
      expect(
        inStreamTransitions['dismiss-ad'],
        containsPair('allowedRoleIds', ['member']),
      );
    });

    test(
      'passes definitions through under specVersion 4 with clean guards translated',
      () {
        expect(plan.replaceWorkflowDefinitionsPayload['specVersion'], 4);
        final definitions =
            plan.replaceWorkflowDefinitionsPayload['definitions'] as Map;
        final messageThread = definitions['platform-message-thread'] as Map;
        final states = messageThread['states'] as Map;
        final draft = states['draft'] as Map;
        expect(draft['editGuard'], containsPair('allowedRoleIds', ['member']));
        expect(draft['editGuard'], isNot(contains('allowedPersonaIds')));

        final inStreamAd = definitions['platform-in-stream-ad'] as Map;
        final mixedGuard =
            ((inStreamAd['transitions'] as List).first as Map)['guard'] as Map;
        expect(mixedGuard, contains('allowedPersonaIds'));
        expect(mixedGuard, isNot(contains('allowedRoleIds')));
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
  const relativePath =
      'docs/references/communities/'
      'Loom_Communities_Workflow_Engine_MemberSocialSpace_Example.jsonc';
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
