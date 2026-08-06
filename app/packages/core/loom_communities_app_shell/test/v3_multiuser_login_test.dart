import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

const _fixtureRelative =
    'docs/references/communities/Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc';

File _fixtureFile() {
  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidate = File('${directory.path}/$_fixtureRelative');
    if (candidate.existsSync()) return candidate;
    directory = directory.parent;
  }
  throw StateError('Could not find the frozen Tabletop fixture.');
}

void main() {
  group('v3 multiuser login', () {
    late LocalAuthApi authApi;
    late LocalWorkflowEngineApi engine;
    late String communityExtensionId;

    setUp(() async {
      authApi = LocalAuthApi();

      // Install a real Tabletop engine from the frozen JSON
      final fixture = _fixtureFile();
      final initialization =
          jsonDecode(stripJsonComments(fixture.readAsStringSync()))
              as Map<String, dynamic>;
      communityExtensionId = initialization['extensionId'] as String;

      final temp = await Directory.systemTemp.createTemp('loom-login-test-');
      final initFile = File('${temp.path}/tabletop.loom-init.zip');
      final extensionFile = File('${temp.path}/tabletop.loom-extension.zip');
      await initFile.writeAsString(jsonEncode(initialization));
      await extensionFile.writeAsString(
        jsonEncode(<String, Object?>{
          'schemaVersion': 1,
          'extensionId': communityExtensionId,
          'displayName': initialization['displayName'],
          'version': '1.0.0',
          'mode': 'local-demo',
          'permissions': <String>[],
        }),
      );

      final backend = LocalInAppBackend();
      final result = backend.installLocalPackagePairFromFiles(
        extensionPackagePath: extensionFile.path,
        initializationPackagePath: initFile.path,
      );
      final community = result.community;

      // Register the engine-native experience first (same pattern as a5).
      experienceForExtensionId(
        community.extensionId,
        displayName: community.displayName,
        experienceConfiguration: community.experienceConfiguration,
      );

      engine =
          (await workflowEngineForExtensionId(community.extensionId))
              as LocalWorkflowEngineApi;

      // Register all seeded account persona types with the engine
      final accounts = await authApi.listAccounts(
        communityExtensionId: communityExtensionId,
      );
      for (final account in accounts) {
        engine.setPersonaType(account.accountId, account.personaTypeId);
      }

      addTearDown(() async => temp.delete(recursive: true));
    });

    // ── Test 1 ────────────────────────────────────────────────────────
    test('LocalAuthApi.listAccounts() returns seeded demo accounts', () async {
      final accounts = await authApi.listAccounts(
        communityExtensionId: communityExtensionId,
      );

      expect(accounts, isNotEmpty);
      // Each account must have a distinct individual personaId
      final ids = accounts.map((a) => a.accountId).toSet();
      expect(ids.length, accounts.length);

      // Every account must have a personaTypeId matching a declared persona
      for (final account in accounts) {
        expect(
          account.personaTypeId,
          anyOf('tabletop-organizer', 'tabletop-member'),
        );
        expect(account.displayName, isNotEmpty);
      }

      // Verify specific seeded accounts exist
      final priyaId = 'tabletop-member-05';
      final priya = accounts.firstWhere((a) => a.accountId == priyaId);
      expect(priya.displayName, 'Priya N.');
      expect(priya.personaTypeId, 'tabletop-member');
    });

    // ── Test 2 ────────────────────────────────────────────────────────
    test('signIn / signUp / signOut / currentSession round-trip', () async {
      // Start with no session
      expect(authApi.currentSession, isNull);

      // Sign in
      final session = await authApi.signIn(accountId: 'tabletop-member-05');
      expect(authApi.currentSession, same(session));
      expect(session.account.accountId, 'tabletop-member-05');
      expect(session.account.personaTypeId, 'tabletop-member');

      // Sign out
      await authApi.signOut();
      expect(authApi.currentSession, isNull);

      // Sign up with a new account
      final newSession = await authApi.signUp(
        communityExtensionId: communityExtensionId,
        displayName: 'Test User',
        personaTypeId: 'tabletop-member',
      );
      expect(authApi.currentSession, same(newSession));
      expect(newSession.account.personaTypeId, 'tabletop-member');
      expect(newSession.account.displayName, 'Test User');
      // New account should not collide with seeded ids
      expect(newSession.account.accountId, isNot('tabletop-member-05'));

      // The new account should now appear in listAccounts
      final accounts = await authApi.listAccounts(
        communityExtensionId: communityExtensionId,
      );
      expect(
        accounts.any((a) => a.accountId == newSession.account.accountId),
        isTrue,
      );
    });

    test('persona resolver rejects an undeclared persona type', () async {
      const communityId = 'authz-p1-apartment-events';
      final resolver = LocalAuthApi(
        personaResolver: (communityExtensionId) {
          expect(communityExtensionId, communityId);
          return const [
            LoomPersonaDefinition(
              personaId: 'apartment-event-manager',
              label: 'Event manager',
              roleLabel: 'Manager',
              description: 'Manages apartment events.',
            ),
          ];
        },
      );

      await expectLater(
        resolver.signUp(
          communityExtensionId: communityId,
          displayName: 'Wrong Persona',
          personaTypeId: 'tabletop-member',
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            allOf(contains('tabletop-member'), contains(communityId)),
          ),
        ),
      );
      expect(
        await resolver.listAccounts(communityExtensionId: communityId),
        isEmpty,
      );
    });

    test(
      'null persona resolver preserves unchecked sign-up behavior',
      () async {
        final api = LocalAuthApi();

        final session = await api.signUp(
          communityExtensionId: 'community-without-a-resolver',
          displayName: 'Legacy User',
          personaTypeId: 'undeclared-legacy-persona',
        );

        expect(session.account.personaTypeId, 'undeclared-legacy-persona');
        expect(session.account.displayName, 'Legacy User');
      },
    );

    // ── Test 3: Owner-gated guard distinguishes individuals ───────────
    test('owner-gated guard distinguishes individuals', () async {
      // Sign in as tabletop-member-05 (owner of share-azul)
      await authApi.signIn(accountId: 'tabletop-member-05');

      // Load the share-azul instance
      final page = await engine.queryInstances(
        tabId: 'home',
        personaId: 'tabletop-member-05',
        limit: 50,
      );
      final azul = page.items.firstWhere((i) => i.instanceId == 'share-azul');

      // As the owner, approve-request should be available
      final ownerTransitions = await engine.availableTransitionsAsync(
        workflowType: azul.workflowType,
        instanceId: azul.instanceId,
        currentState: azul.currentState,
        instanceData: azul.instanceData,
        personaId: 'tabletop-member-05',
      );
      final ownerTransitionIds = ownerTransitions.map((t) => t.id).toSet();
      expect(ownerTransitionIds, contains('approve-request'));
      expect(ownerTransitionIds, contains('decline-request'));

      // Sign in as a different member (not the owner)
      await authApi.signOut();
      await authApi.signIn(accountId: 'tabletop-member-06');

      // Re-register type mapping
      engine.setPersonaType('tabletop-member-06', 'tabletop-member');

      // As non-owner, approve-request should NOT be available
      final nonOwnerTransitions = await engine.availableTransitionsAsync(
        workflowType: azul.workflowType,
        instanceId: azul.instanceId,
        currentState: azul.currentState,
        instanceData: azul.instanceData,
        personaId: 'tabletop-member-06',
      );
      final nonOwnerTransitionIds = nonOwnerTransitions
          .map((t) => t.id)
          .toSet();
      expect(nonOwnerTransitionIds, isNot(contains('approve-request')));
      expect(nonOwnerTransitionIds, isNot(contains('decline-request')));
    });

    // ── Test 4: Switch-user picker renders correct list ─────────────
    test('account list groups by persona type', () async {
      final accounts = await authApi.listAccounts(
        communityExtensionId: communityExtensionId,
      );

      final grouped = <String, List<LoomAccount>>{};
      for (final account in accounts) {
        grouped.putIfAbsent(account.personaTypeId, () => []).add(account);
      }

      // Should have both organizer and member groups
      expect(grouped.keys, contains('tabletop-organizer'));
      expect(grouped.keys, contains('tabletop-member'));

      // Organizer group has exactly one account
      expect(grouped['tabletop-organizer']!.length, 1);

      // Member group has multiple accounts
      expect(grouped['tabletop-member']!.length, greaterThan(1));

      // All accounts in a group share the same personaTypeId
      for (final entry in grouped.entries) {
        for (final account in entry.value) {
          expect(account.personaTypeId, entry.key);
        }
      }
    });

    // ── Test 5: Full suite still passes (pre-existing count check) ──
    test(
      'engine-native store initializes correctly with auth bridge',
      () async {
        // Verify engine is functional
        final page = await engine.queryInstances(
          tabId: 'home',
          personaId: 'tabletop-member',
          limit: 50,
        );
        expect(page.items, hasLength(33));

        // Verify that the persona type mapping is in place:
        // query the real share-azul instance (same pattern as Test 3 above)
        final azul = page.items.firstWhere((i) => i.instanceId == 'share-azul');
        final ownerTransitions = await engine.availableTransitionsAsync(
          workflowType: azul.workflowType,
          instanceId: azul.instanceId,
          currentState: azul.currentState,
          instanceData: azul.instanceData,
          personaId: 'tabletop-member-05',
        );
        expect(ownerTransitions, isNotEmpty);
        // The owner-gated transitions must be present
        final ids = ownerTransitions.map((t) => t.id).toSet();
        expect(ids, contains('approve-request'));
        expect(ids, contains('decline-request'));
      },
    );
  });
}
