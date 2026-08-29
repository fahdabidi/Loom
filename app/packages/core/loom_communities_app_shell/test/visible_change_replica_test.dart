import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:loom_auth_session/loom_auth_session.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';

final class _MemorySecureStorage implements LoomAuthSecureStorageBackend {
  @override
  Future<void> delete({required String key}) async {}

  @override
  Future<String?> read({required String key}) async => null;

  @override
  Future<void> write({required String key, required String value}) async {}
}

final class _TestSession extends LoomAuthSession {
  _TestSession()
    : super(
        tokenEndpoint: Uri.parse('https://identity.test/token'),
        clientId: 'replica-test',
        secureStorage: _MemorySecureStorage(),
      );

  @override
  Future<String> currentAccessToken() async => 'replica-test-token';
}

LoomVisibleChangesClient _client(http.Client httpClient) =>
    LoomVisibleChangesClient(
      workflowServiceBaseUri: Uri.parse('https://workflow.test/api/'),
      session: _TestSession(),
      httpClient: httpClient,
    );

Map<String, Object?> _snapshot(String id, {int updatedAt = 100}) =>
    <String, Object?>{
      'instanceId': id,
      'workflowType': 'notice',
      'currentState': 'published',
      'instanceData': <String, Object?>{'title': id},
      'createdAt': 1,
      'updatedAt': updatedAt,
      'createdByFanId': 'author',
    };

http.Response _page({
  required List<Map<String, Object?>> changed,
  required List<String> visibleInstanceIds,
  int nextUpdatedSince = 100,
  String nextAfterInstanceId = 'a',
  String nextRoleCursor = 'role-1',
  bool hasMore = false,
  bool resyncRequired = false,
}) => http.Response(
  jsonEncode(<String, Object?>{
    'communityId': 'garden',
    'changed': changed,
    'visibleInstanceIds': visibleInstanceIds,
    'nextUpdatedSince': nextUpdatedSince,
    'nextAfterInstanceId': nextAfterInstanceId,
    'nextRoleCursor': nextRoleCursor,
    'hasMore': hasMore,
    'resyncRequired': resyncRequired,
  }),
  200,
  headers: const {'content-type': 'application/json'},
);

Future<List<String>> _ids(LoomWorkflowReplica replica, String fanId) async {
  final page = await replica.engine.queryInstances(
    tabId: 'any-tab',
    fanId: fanId,
    limit: 100,
  );
  return page.items.map((item) => item.instanceId).toList();
}

void main() {
  group('server-fed workflow replicas', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp(
        'loom-visible-replica-',
      );
    });

    tearDown(() async {
      await directory.delete(recursive: true);
    });

    test('deletes a local instance absent from visibleInstanceIds', () async {
      var call = 0;
      final httpClient = MockClient((_) async {
        call += 1;
        return call == 1
            ? _page(
                changed: <Map<String, Object?>>[
                  _snapshot('keep'),
                  _snapshot('no-longer-visible'),
                ],
                visibleInstanceIds: const ['keep', 'no-longer-visible'],
                nextAfterInstanceId: 'no-longer-visible',
              )
            : _page(
                changed: <Map<String, Object?>>[
                  _snapshot('keep', updatedAt: 200),
                ],
                visibleInstanceIds: const ['keep'],
                nextUpdatedSince: 200,
                nextAfterInstanceId: 'keep',
                nextRoleCursor: 'role-2',
              );
      });
      final replica = await LoomWorkflowReplica.openFile(
        databasePath: '${directory.path}/alice-garden.sqlite',
        fanId: 'alice',
        communityId: 'garden',
      );
      addTearDown(replica.close);
      addTearDown(httpClient.close);

      await replica.sync(_client(httpClient));
      expect(
        await _ids(replica, 'alice'),
        containsAll(['keep', 'no-longer-visible']),
      );

      await replica.sync(_client(httpClient));
      expect(await _ids(replica, 'alice'), ['keep']);
    });

    test('resyncRequired discards rows and retries with no cursor', () async {
      final requests = <http.Request>[];
      final httpClient = MockClient((request) async {
        requests.add(request);
        return switch (requests.length) {
          1 => _page(
            changed: <Map<String, Object?>>[_snapshot('old')],
            visibleInstanceIds: const ['old'],
          ),
          2 => _page(
            changed: const <Map<String, Object?>>[],
            visibleInstanceIds: const ['old'],
            resyncRequired: true,
          ),
          3 => _page(
            changed: <Map<String, Object?>>[_snapshot('new', updatedAt: 200)],
            visibleInstanceIds: const ['new'],
            nextUpdatedSince: 200,
            nextAfterInstanceId: 'new',
            nextRoleCursor: 'role-after-resync',
          ),
          _ => throw StateError('Unexpected request.'),
        };
      });
      final replica = await LoomWorkflowReplica.openFile(
        databasePath: '${directory.path}/alice-garden.sqlite',
        fanId: 'alice',
        communityId: 'garden',
      );
      addTearDown(replica.close);
      addTearDown(httpClient.close);

      await replica.sync(_client(httpClient));
      await replica.sync(_client(httpClient));

      expect(await _ids(replica, 'alice'), ['new']);
      expect(requests, hasLength(3));
      expect(requests[1].url.queryParameters['updatedSince'], '100');
      expect(requests[2].url.queryParameters, isEmpty);
    });

    test('reopens a persisted cursor and resumes from it', () async {
      final firstRequests = <http.Request>[];
      final firstHttpClient = MockClient((request) async {
        firstRequests.add(request);
        return _page(
          changed: <Map<String, Object?>>[_snapshot('first')],
          visibleInstanceIds: const ['first'],
          nextUpdatedSince: 345,
          nextAfterInstanceId: 'first',
          nextRoleCursor: 'opaque-role-cursor',
        );
      });
      final path = '${directory.path}/alice-garden.sqlite';
      final firstReplica = await LoomWorkflowReplica.openFile(
        databasePath: path,
        fanId: 'alice',
        communityId: 'garden',
      );
      await firstReplica.sync(_client(firstHttpClient));
      firstReplica.close();
      firstHttpClient.close();

      final resumedRequests = <http.Request>[];
      final resumedHttpClient = MockClient((request) async {
        resumedRequests.add(request);
        return _page(
          changed: <Map<String, Object?>>[_snapshot('second', updatedAt: 400)],
          visibleInstanceIds: const ['first', 'second'],
          nextUpdatedSince: 400,
          nextAfterInstanceId: 'second',
          nextRoleCursor: 'next-opaque-role-cursor',
        );
      });
      final resumedReplica = await LoomWorkflowReplica.openFile(
        databasePath: path,
        fanId: 'alice',
        communityId: 'garden',
      );
      addTearDown(resumedReplica.close);
      addTearDown(resumedHttpClient.close);

      await resumedReplica.sync(_client(resumedHttpClient));

      expect(firstRequests.single.url.queryParameters, isEmpty);
      expect(resumedRequests.single.url.queryParameters, <String, String>{
        'updatedSince': '345',
        'afterInstanceId': 'first',
        'roleCursor': 'opaque-role-cursor',
      });
      expect(
        await _ids(resumedReplica, 'alice'),
        containsAll(['first', 'second']),
      );
    });

    test(
      'separates replicas by fan and refuses another fan the first file',
      () async {
        var call = 0;
        final httpClient = MockClient((_) async {
          call += 1;
          return call == 1
              ? _page(
                  changed: <Map<String, Object?>>[_snapshot('alice-row')],
                  visibleInstanceIds: const ['alice-row'],
                )
              : _page(
                  changed: <Map<String, Object?>>[_snapshot('bob-row')],
                  visibleInstanceIds: const ['bob-row'],
                );
        });
        final alicePath = '${directory.path}/alice-garden.sqlite';
        final alice = await LoomWorkflowReplica.openFile(
          databasePath: alicePath,
          fanId: 'alice',
          communityId: 'garden',
        );
        final bob = await LoomWorkflowReplica.openFile(
          databasePath: '${directory.path}/bob-garden.sqlite',
          fanId: 'bob',
          communityId: 'garden',
        );
        addTearDown(alice.close);
        addTearDown(bob.close);
        addTearDown(httpClient.close);

        await alice.sync(_client(httpClient));
        await bob.sync(_client(httpClient));

        expect(await _ids(alice, 'alice'), ['alice-row']);
        expect(await _ids(bob, 'bob'), ['bob-row']);
        await expectLater(
          alice.engine.queryInstances(tabId: 'any-tab', fanId: 'bob'),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'member-readable reason',
              contains('another member'),
            ),
          ),
        );
        await expectLater(
          LoomWorkflowReplica.openFile(
            databasePath: alicePath,
            fanId: 'bob',
            communityId: 'garden',
          ),
          throwsA(isA<StateError>()),
        );
      },
    );

    test(
      'immediately follows hasMore pages and retains each instance once',
      () async {
        final requests = <http.Request>[];
        final httpClient = MockClient((request) async {
          requests.add(request);
          return switch (requests.length) {
            1 => _page(
              changed: <Map<String, Object?>>[_snapshot('a')],
              visibleInstanceIds: const ['a', 'b'],
              nextUpdatedSince: 100,
              nextAfterInstanceId: 'a',
              nextRoleCursor: 'role-1',
              hasMore: true,
            ),
            2 => _page(
              changed: <Map<String, Object?>>[_snapshot('b', updatedAt: 100)],
              visibleInstanceIds: const ['a', 'b'],
              nextUpdatedSince: 100,
              nextAfterInstanceId: 'b',
              nextRoleCursor: 'role-1',
            ),
            _ => throw StateError('Unexpected request.'),
          };
        });
        final replica = await LoomWorkflowReplica.openFile(
          databasePath: '${directory.path}/alice-garden.sqlite',
          fanId: 'alice',
          communityId: 'garden',
        );
        addTearDown(replica.close);
        addTearDown(httpClient.close);

        await replica.sync(_client(httpClient));

        expect(requests, hasLength(2));
        expect(requests[1].url.queryParameters, <String, String>{
          'updatedSince': '100',
          'afterInstanceId': 'a',
          'roleCursor': 'role-1',
        });
        expect(await _ids(replica, 'alice'), unorderedEquals(['a', 'b']));
      },
    );

    test(
      'every facade write fails with a member-readable offline reason',
      () async {
        final replica = await LoomWorkflowReplica.openFile(
          databasePath: '${directory.path}/alice-garden.sqlite',
          fanId: 'alice',
          communityId: 'garden',
        );
        addTearDown(replica.close);
        final api = replica.engine;

        Future<void> expectOffline(Future<dynamic> operation) => expectLater(
          operation,
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'member-readable reason',
              ReadOnlyWorkflowReplicaApi.offlineWriteMessage,
            ),
          ),
        );

        await expectOffline(
          api.applyTransition(
            workflowType: 'notice',
            instanceId: 'one',
            transitionId: 'publish',
            fanId: 'alice',
          ),
        );
        await expectOffline(
          api.createInstance(
            workflowType: 'notice',
            initialInstanceData: const <String, dynamic>{},
            fanId: 'alice',
          ),
        );
        await expectOffline(
          api.createInstances(
            workflowType: 'notice',
            initialInstanceDataList: const <Map<String, dynamic>>[],
            fanId: 'alice',
          ),
        );
        await expectOffline(
          api.updateInstanceFields(
            workflowType: 'notice',
            instanceId: 'one',
            fieldUpdates: const <String, dynamic>{},
            fanId: 'alice',
          ),
        );
      },
    );

    test(
      'change-feed client sends an RFC 4122 version-four correlation id',
      () async {
        late http.Request captured;
        final httpClient = MockClient((request) async {
          captured = request;
          return _page(
            changed: const <Map<String, Object?>>[],
            visibleInstanceIds: const <String>[],
            nextAfterInstanceId: '',
          );
        });
        addTearDown(httpClient.close);

        await _client(httpClient).listVisibleChanges(communityId: 'garden');

        expect(
          captured.headers['x-loom-correlation-id'],
          matches(
            RegExp(
              r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
            ),
          ),
        );
      },
    );
  });
}
