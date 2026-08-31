import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:loom_auth_session/loom_auth_session.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

final class _MemoryStorage implements LoomAuthSecureStorageBackend {
  @override
  Future<void> delete({required String key}) async {}

  @override
  Future<String?> read({required String key}) async => null;

  @override
  Future<void> write({required String key, required String value}) async {}
}

final class _Session extends LoomAuthSession {
  _Session()
    : super(
        tokenEndpoint: Uri.parse('https://identity.test/token'),
        clientId: 'offline-coordinator-test',
        secureStorage: _MemoryStorage(),
      );

  @override
  Future<String> currentAccessToken() async => 'offline-coordinator-token';
}

LoomVisibleChangesClient _changesClient(http.Client client) =>
    LoomVisibleChangesClient(
      workflowServiceBaseUri: Uri.parse('https://workflow.test/api/'),
      session: _Session(),
      httpClient: client,
    );

RemoteWorkflowEngineApi _remoteEngine(http.Client client) =>
    RemoteWorkflowEngineApi(
      baseUri: Uri.parse('https://workflow.test/api/'),
      communityId: 'garden',
      bearerTokenProvider: () async => 'offline-coordinator-token',
      httpClient: client,
    );

Map<String, Object?> _snapshot(String instanceId, {int updatedAt = 5000}) =>
    <String, Object?>{
      'instanceId': instanceId,
      'workflowType': 'notice',
      'currentState': 'published',
      'instanceData': <String, Object?>{'title': instanceId},
      'createdAt': 1,
      'updatedAt': updatedAt,
      'createdByFanId': 'author',
    };

http.Response _changePage({
  required List<Map<String, Object?>> changed,
  required List<String> visibleInstanceIds,
  String communityId = 'garden',
  int nextUpdatedSince = 5000,
  String nextAfterInstanceId = 'notice-1',
  String nextRoleCursor = 'role-cursor',
}) => http.Response(
  jsonEncode(<String, Object?>{
    'communityId': communityId,
    'changed': changed,
    'visibleInstanceIds': visibleInstanceIds,
    'nextUpdatedSince': nextUpdatedSince,
    'nextAfterInstanceId': nextAfterInstanceId,
    'nextRoleCursor': nextRoleCursor,
    'hasMore': false,
    'resyncRequired': false,
  }),
  200,
  headers: const {'content-type': 'application/json'},
);

const _statusMachine = LoomWorkflowStateMachine(
  workflowType: 'notice',
  initialState: 'published',
  states: <String, LoomWorkflowState>{
    'published': LoomWorkflowState(label: 'Published'),
  },
  transitions: <LoomWorkflowTransition>[],
  renderBindings: <RenderBinding>[
    RenderBinding(
      states: <String>['published'],
      role: 'any',
      tabId: 'home',
      cardSurfaceFamily: 'workflow-status',
      bindingKind: 'primary',
    ),
  ],
);

Widget _readStatusHost(WorkflowEngineApi engine) => MaterialApp(
  home: Scaffold(
    body: EngineNativeBindingDispatcher(
      engine: engine,
      definitions: const <String, LoomWorkflowStateMachine>{
        'notice': _statusMachine,
      },
      tabId: 'home',
      fanId: 'alice',
      builder: (context, bindings, _) =>
          Text('Loaded ${bindings.length} saved item'),
    ),
  ),
);

http.Response _remotePage({String instanceId = 'notice-1'}) => http.Response(
  jsonEncode(<String, Object?>{
    'items': <Map<String, Object?>>[
      <String, Object?>{
        'instanceId': instanceId,
        'workflowType': 'notice',
        'currentState': 'published',
        'instanceData': <String, Object?>{'title': instanceId},
      },
    ],
    'pageInfo': <String, Object?>{'hasMore': false},
  }),
  200,
  headers: const {'content-type': 'application/json'},
);

LocalInstalledCommunity _mountedCommunity(String extensionId) =>
    LocalInstalledCommunity(
      communityId: 'offline-screen',
      displayName: 'Offline screen fixture',
      extensionId: extensionId,
      logoAssetId: null,
      cardImageAssetId: null,
      heroImageAssetId: null,
      accentColor: '#246B62',
      specVersion: currentCommunitySpecVersion,
      experienceConfiguration: const <String, Object?>{
        'tagline': 'A mounted offline replica test fixture.',
        'roles': <Map<String, Object?>>[
          <String, Object?>{
            'roleId': 'member',
            'label': 'Member',
            'roleLabel': 'Member',
            'description': 'Can read the community.',
            'accessMode': 'open',
          },
        ],
        'workflowDefinitions': <String, Object?>{
          'notice': <String, Object?>{
            'initialState': 'published',
            'states': <String, Object?>{
              'published': <String, Object?>{'label': 'Published'},
            },
            'transitions': <Object?>[],
            'renderBindings': <Object?>[
              <String, Object?>{
                'states': <String>['published'],
                'audience': 'any',
                'tabId': 'home',
                'cardSurfaceFamily': 'workflow-status',
                'bindingKind': 'primary',
              },
            ],
          },
        },
      },
    );

http.Response _remoteError(
  int statusCode, {
  String code = 'workflow_service_error',
}) => http.Response(
  jsonEncode(<String, Object?>{
    'code': code,
    'message': 'Remote response $statusCode',
  }),
  statusCode,
  headers: const {'content-type': 'application/json'},
);

Future<void> _expectOfflineWrite(Future<dynamic> operation) => expectLater(
  operation,
  throwsA(
    isA<StateError>().having(
      (error) => error.message,
      'offline message',
      LoomWorkflowReplica.offlineWriteMessage,
    ),
  ),
);

void main() {
  tearDown(() {
    resetLoomOfflineReplicaSupportForTesting();
    resetEngineNativeCommunityFactoryRegistrationsForTesting();
    resetEngineNativeCommunityEngineFactoryForTesting();
    resetProductionEngineNativeCommunityEngineFactoryForTesting();
  });

  group('offline replica coordinator', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp(
        'loom-offline-coordinator-',
      );
    });

    tearDown(() async {
      await directory.delete(recursive: true);
    });

    test(
      'a previously synced community reads from its replica when remote is unavailable and reports its age',
      () async {
        final initialChanges = MockClient(
          (_) async => _changePage(
            changed: <Map<String, Object?>>[_snapshot('notice-1')],
            visibleInstanceIds: const ['notice-1'],
          ),
        );
        final initial = LoomWorkflowReplicaCoordinator(
          databaseDirectory: directory.path,
          visibleChangesClient: _changesClient(initialChanges),
        );
        await initial.open(fanId: 'alice', communityId: 'garden');
        initial.dispose();
        initialChanges.close();

        final unavailableChanges = MockClient((_) async => _remoteError(503));
        final coordinator = LoomWorkflowReplicaCoordinator(
          databaseDirectory: directory.path,
          visibleChangesClient: _changesClient(unavailableChanges),
          now: () => DateTime.utc(1970, 1, 1, 0, 0, 8),
        );
        addTearDown(coordinator.dispose);
        addTearDown(unavailableChanges.close);
        await coordinator.open(fanId: 'alice', communityId: 'garden');

        final unavailableRemote = MockClient((_) async => _remoteError(503));
        addTearDown(unavailableRemote.close);
        final engine = coordinator.wrap(
          _remoteEngine(unavailableRemote),
          communityId: 'garden',
        );

        final page = await engine.queryInstances(tabId: 'home', fanId: 'alice');

        expect(page.items.single.instanceId, 'notice-1');
        expect(coordinator.lastOpenSyncFailure, isNotNull);
        expect(engine.lastRead, isNotNull);
        expect(engine.lastRead!.cameFromReplica, isTrue);
        expect(engine.lastRead!.replicaCursor!.nextUpdatedSince, 5000);
        expect(engine.lastRead!.replicaCursorAge, const Duration(seconds: 3));
      },
    );

    test('unavailable writes all go remote once then fail read-only', () async {
      final changes = MockClient(
        (_) async => _changePage(
          changed: <Map<String, Object?>>[_snapshot('notice-1')],
          visibleInstanceIds: const ['notice-1'],
        ),
      );
      final coordinator = LoomWorkflowReplicaCoordinator(
        databaseDirectory: directory.path,
        visibleChangesClient: _changesClient(changes),
      );
      addTearDown(coordinator.dispose);
      addTearDown(changes.close);
      await coordinator.open(fanId: 'alice', communityId: 'garden');

      var remoteRequests = 0;
      final unavailableRemote = MockClient((_) async {
        remoteRequests += 1;
        return _remoteError(503);
      });
      addTearDown(unavailableRemote.close);
      final engine = coordinator.wrap(
        _remoteEngine(unavailableRemote),
        communityId: 'garden',
      );

      await _expectOfflineWrite(
        engine.applyTransition(
          workflowType: 'notice',
          instanceId: 'notice-1',
          transitionId: 'publish',
          fanId: 'alice',
        ),
      );
      await _expectOfflineWrite(
        engine.createInstance(
          workflowType: 'notice',
          initialInstanceData: const <String, dynamic>{},
          fanId: 'alice',
        ),
      );
      await _expectOfflineWrite(
        engine.createInstances(
          workflowType: 'notice',
          initialInstanceDataList: const <Map<String, dynamic>>[],
          fanId: 'alice',
        ),
      );
      await _expectOfflineWrite(
        engine.updateInstanceFields(
          workflowType: 'notice',
          instanceId: 'notice-1',
          fieldUpdates: const <String, dynamic>{},
          fanId: 'alice',
        ),
      );

      expect(remoteRequests, 4);
      final stored = await coordinator.activeReplica!.engine.queryInstances(
        tabId: 'home',
        fanId: 'alice',
      );
      expect(stored.items.map((item) => item.instanceId), ['notice-1']);
    });

    test('a 403 surfaces from remote and never reads the replica', () async {
      final changes = MockClient(
        (_) async => _changePage(
          changed: <Map<String, Object?>>[_snapshot('notice-1')],
          visibleInstanceIds: const ['notice-1'],
        ),
      );
      final coordinator = LoomWorkflowReplicaCoordinator(
        databaseDirectory: directory.path,
        visibleChangesClient: _changesClient(changes),
      );
      addTearDown(coordinator.dispose);
      addTearDown(changes.close);
      await coordinator.open(fanId: 'alice', communityId: 'garden');

      final forbiddenRemote = MockClient(
        (_) async => _remoteError(403, code: 'authentication_required'),
      );
      addTearDown(forbiddenRemote.close);
      final engine = coordinator.wrap(
        _remoteEngine(forbiddenRemote),
        communityId: 'garden',
      );

      await expectLater(
        engine.queryInstances(tabId: 'home', fanId: 'alice'),
        throwsA(
          isA<RemoteWorkflowAuthenticationError>().having(
            (error) => error.statusCode,
            'status code',
            403,
          ),
        ),
      );
      expect(engine.lastRead, isNull);
    });

    test(
      'without an injected directory, the remote factory stays unwrapped',
      () async {
        expect(loomWorkflowReplicaCoordinator, isNull);
        final unavailableRemote = MockClient((_) async => _remoteError(503));
        addTearDown(unavailableRemote.close);
        final database = WorkflowDatabase.memory();
        addTearDown(database.close);
        final engine = createRemoteEngineNativeCommunityEngineFactory(
          session: _Session(),
          workflowServiceBaseUri: Uri.parse('https://workflow.test/api/'),
          httpClient: unavailableRemote,
        )(database: database, extensionId: 'garden');

        expect(engine, isA<RemoteWorkflowEngineApi>());
        await expectLater(
          engine.queryInstances(tabId: 'home', fanId: 'alice'),
          throwsA(
            isA<RemoteWorkflowServiceError>().having(
              (error) => error.statusCode,
              'status code',
              503,
            ),
          ),
        );
      },
    );

    test(
      'switching fans closes the old replica and cannot cross rows',
      () async {
        var syncs = 0;
        final changes = MockClient((_) async {
          syncs += 1;
          return syncs == 1
              ? _changePage(
                  changed: <Map<String, Object?>>[_snapshot('alice-row')],
                  visibleInstanceIds: const ['alice-row'],
                )
              : _changePage(
                  changed: <Map<String, Object?>>[_snapshot('bob-row')],
                  visibleInstanceIds: const ['bob-row'],
                );
        });
        final coordinator = LoomWorkflowReplicaCoordinator(
          databaseDirectory: directory.path,
          visibleChangesClient: _changesClient(changes),
        );
        addTearDown(coordinator.dispose);
        addTearDown(changes.close);
        final unavailableRemote = MockClient((_) async => _remoteError(503));
        addTearDown(unavailableRemote.close);
        final engine = coordinator.wrap(
          _remoteEngine(unavailableRemote),
          communityId: 'garden',
        );

        await coordinator.open(fanId: 'alice', communityId: 'garden');
        final aliceReplica = coordinator.activeReplica!;
        await coordinator.open(fanId: 'bob', communityId: 'garden');

        expect(aliceReplica.isClosed, isTrue);
        expect(coordinator.activeFanId, 'bob');
        final bobPage = await engine.queryInstances(
          tabId: 'home',
          fanId: 'bob',
        );
        expect(bobPage.items.map((item) => item.instanceId), ['bob-row']);
        await expectLater(
          engine.queryInstances(tabId: 'home', fanId: 'alice'),
          throwsA(isA<RemoteWorkflowServiceError>()),
        );
      },
    );

    test(
      'a restarted coordinator resumes the stored cursor instead of full sync',
      () async {
        final firstChanges = MockClient(
          (_) async => _changePage(
            changed: <Map<String, Object?>>[_snapshot('first')],
            visibleInstanceIds: const ['first'],
            nextUpdatedSince: 345,
            nextAfterInstanceId: 'first',
            nextRoleCursor: 'first-role-cursor',
          ),
        );
        final first = LoomWorkflowReplicaCoordinator(
          databaseDirectory: directory.path,
          visibleChangesClient: _changesClient(firstChanges),
        );
        await first.open(fanId: 'alice', communityId: 'garden');
        first.dispose();
        firstChanges.close();

        late http.Request resumedRequest;
        final resumedChanges = MockClient((request) async {
          resumedRequest = request;
          return _changePage(
            changed: <Map<String, Object?>>[
              _snapshot('second', updatedAt: 400),
            ],
            visibleInstanceIds: const ['first', 'second'],
            nextUpdatedSince: 400,
            nextAfterInstanceId: 'second',
            nextRoleCursor: 'second-role-cursor',
          );
        });
        final resumed = LoomWorkflowReplicaCoordinator(
          databaseDirectory: directory.path,
          visibleChangesClient: _changesClient(resumedChanges),
        );
        addTearDown(resumed.dispose);
        addTearDown(resumedChanges.close);

        await resumed.open(fanId: 'alice', communityId: 'garden');

        expect(resumedRequest.url.queryParameters, <String, String>{
          'updatedSince': '345',
          'afterInstanceId': 'first',
          'roleCursor': 'first-role-cursor',
        });
      },
    );

    testWidgets(
      'a replica-served read visibly states its cursor age while a fresh read does not',
      (tester) async {
        final changes = MockClient(
          (_) async => _changePage(
            changed: <Map<String, Object?>>[_snapshot('notice-1')],
            visibleInstanceIds: const ['notice-1'],
          ),
        );
        final coordinator = LoomWorkflowReplicaCoordinator(
          databaseDirectory: directory.path,
          visibleChangesClient: _changesClient(changes),
          now: () => DateTime.utc(1970, 1, 1, 0, 0, 8),
        );
        addTearDown(coordinator.dispose);
        addTearDown(changes.close);
        await coordinator.open(fanId: 'alice', communityId: 'garden');

        final unavailableRemote = MockClient((_) async => _remoteError(503));
        addTearDown(unavailableRemote.close);
        await tester.pumpWidget(
          _readStatusHost(
            coordinator.wrap(
              _remoteEngine(unavailableRemote),
              communityId: 'garden',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('offline-replica-read-status')),
          findsOneWidget,
        );
        expect(
          find.text('Showing saved data from 3 seconds ago'),
          findsOneWidget,
        );

        final freshRemote = MockClient((_) async => _remotePage());
        addTearDown(freshRemote.close);
        await tester.pumpWidget(
          _readStatusHost(
            coordinator.wrap(_remoteEngine(freshRemote), communityId: 'garden'),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('offline-replica-read-status')),
          findsNothing,
        );
        expect(find.text('Loaded 1 saved item'), findsOneWidget);
      },
    );

    testWidgets(
      'entering opens and refreshes the member replica, then leaving closes it fail-closed',
      (tester) async {
        var syncs = 0;
        final changes = MockClient((_) async {
          syncs += 1;
          return _changePage(
            changed: <Map<String, Object?>>[_snapshot('notice-1')],
            visibleInstanceIds: const ['notice-1'],
            communityId: 'offline-screen-extension',
          );
        });
        addTearDown(changes.close);
        const extensionId = 'offline-screen-extension';
        final remote = MockClient((_) async => _remoteError(503));
        addTearDown(remote.close);
        final services = LoomRemoteServiceConfiguration(
          session: _Session(),
          workflowServiceBaseUri: Uri.parse('https://workflow.test/api/'),
          appAccessBaseUri: Uri.parse('https://app-access.test/api/'),
          fanPassportBaseUri: Uri.parse('https://fan-passport.test/api/'),
          communityGroupIds: const <String, String>{},
        );
        configureLoomOfflineReplicaSupportForProduction(
          databaseDirectory: directory.path,
          remoteServices: services,
          httpClient: changes,
        );
        enableRemoteEngineForCommunity(
          extensionId: extensionId,
          session: services.session,
          workflowServiceBaseUri: services.workflowServiceBaseUri,
          httpClient: remote,
          offlineReplicaCoordinator: loomWorkflowReplicaCoordinator,
        );
        final authApi = LocalAuthApi()
          ..seedAccounts(extensionId, const <LoomAccount>[
            LoomAccount(
              accountId: 'alice',
              displayName: 'Alice Member',
              roleId: 'member',
            ),
          ]);
        await authApi.signIn(accountId: 'alice');
        await tester.pumpWidget(
          MaterialApp(
            home: LocalExtensionScreen(
              community: _mountedCommunity(extensionId),
              seedDataFiles: const <String>[],
              authApi: authApi,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('community-offline-refresh-button')),
          findsOneWidget,
        );
        final coordinator = loomWorkflowReplicaCoordinator!;
        expect(coordinator.activeFanId, 'alice');
        expect(coordinator.activeCommunityId, extensionId);
        expect(syncs, 2);

        await tester.tap(
          find.byKey(const ValueKey('community-offline-refresh-button')),
        );
        await tester.pumpAndSettle();
        expect(syncs, 3);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        expect(coordinator.activeReplica, isNull);
        await expectLater(
          openOfflineReplicaForExtensionId(
            extensionId: extensionId,
            fanId: 'bob',
          ),
          throwsA(isA<StateError>()),
        );
      },
    );
  });
}
