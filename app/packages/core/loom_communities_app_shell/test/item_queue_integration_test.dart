import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:loom_auth_session/loom_auth_session.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

final class _MemoryStorage implements LoomAuthSecureStorageBackend {
  @override
  Future<void> delete({required String key}) async {}

  @override
  Future<String?> read({required String key}) async => null;

  @override
  Future<void> write({required String key, required String value}) async {}
}

final class _TokenSession extends LoomAuthSession {
  _TokenSession()
    : super(
        tokenEndpoint: Uri.parse('https://identity.test/token'),
        clientId: 'test-client',
        secureStorage: _MemoryStorage(),
      );

  @override
  Future<String> currentAccessToken() async => 'test-access-token';
}

final class _RemoteQueueEngine extends RemoteWorkflowEngineApi {
  _RemoteQueueEngine(this.transitions)
    : super(
        baseUri: Uri.parse('https://workflow.test/'),
        communityId: 'community-test',
        bearerTokenProvider: () async => 'test-access-token',
        httpClient: MockClient(
          (_) async => throw StateError('The test engine overrides requests.'),
        ),
      );

  final List<LoomWorkflowTransition> transitions;
  final appliedTransitionIds = <String>[];

  @override
  Future<List<LoomWorkflowTransition>> availableTransitionsAsync({
    required String workflowType,
    required String instanceId,
    required String currentState,
    required Map<String, dynamic> instanceData,
    required String fanId,
  }) async => transitions;

  @override
  Future<WorkflowTransitionResult> applyTransition({
    required String workflowType,
    required String instanceId,
    required String transitionId,
    required String fanId,
    Map<String, dynamic>? inputs,
  }) async {
    appliedTransitionIds.add(transitionId);
    return const WorkflowTransitionResult(
      newState: 'published',
      newInstanceData: const <String, dynamic>{},
    );
  }
}

final class _QueueService {
  _QueueService({Set<String> entriesVisibleFor = const {}})
    : _entriesVisibleFor = entriesVisibleFor;

  final List<String> queuedFanIds = <String>[];
  final Set<String> _entriesVisibleFor;
  late final http.Client client = MockClient(_handle);
  String actor = 'alice';

  Future<http.Response> _handle(http.Request request) async {
    final path = request.url.path;
    if (request.method == 'GET' && path.endsWith('/queue')) {
      final position = queuedFanIds.indexOf(actor) + 1;
      return http.Response(
        jsonEncode(<String, Object?>{
          'instanceId': 'listing-7',
          'length': queuedFanIds.length,
          'viewerPosition': position,
          if (_entriesVisibleFor.contains(actor))
            'entries': <Map<String, Object?>>[
              for (var index = 0; index < queuedFanIds.length; index++)
                <String, Object?>{
                  'fanId': queuedFanIds[index],
                  'position': index + 1,
                  'joinedAt': '2026-08-28T00:00:00.000Z',
                },
            ],
        }),
        200,
      );
    }
    if (request.method == 'POST' && path.endsWith('/queue')) {
      if (!queuedFanIds.contains(actor)) queuedFanIds.add(actor);
      return http.Response(
        jsonEncode(<String, Object?>{
          'fanId': actor,
          'position': queuedFanIds.indexOf(actor) + 1,
          'joinedAt': '2026-08-28T00:00:00.000Z',
        }),
        201,
      );
    }
    if (request.method == 'DELETE' && path.endsWith('/queue')) {
      queuedFanIds.remove(actor);
      return http.Response('', 204);
    }
    return http.Response('unexpected request: ${request.method} $path', 500);
  }

  void close() => client.close();
}

LoomWorkflowStateMachine _queueMachine({
  String joinId = 'join-queue',
  String leaveId = 'leave-queue',
  bool hasAdminDecision = false,
  bool hasLegacyQueueFields = false,
}) => LoomWorkflowStateMachine.fromJson(<String, dynamic>{
  'initialState': 'published',
  'states': <String, Object?>{
    'published': <String, Object?>{'label': 'Published'},
  },
  'transitions': <Map<String, Object?>>[
    <String, Object?>{
      'id': joinId,
      'action': 'join_queue',
      'label': 'Join queue',
      'icon': 'groups',
      'tone': 'secondary',
      'from': <String>['published'],
      'to': null,
    },
    <String, Object?>{
      'id': leaveId,
      'action': 'leave_queue',
      'label': 'Leave queue',
      'icon': 'group_remove',
      'tone': 'secondary',
      'from': <String>['published'],
      'to': null,
    },
    if (hasAdminDecision)
      <String, Object?>{
        'id': 'approve-request',
        'action': 'decide_request',
        'label': 'Approve request',
        'from': <String>['published'],
        'to': null,
      },
  ],
  'instanceDataSchema': <String, Object?>{
    'title': <String, Object?>{'type': 'text', 'labelTemplate': '{value}'},
    if (hasLegacyQueueFields) ...<String, Object?>{
      'queueLength': <String, Object?>{
        'type': 'number',
        'labelTemplate': 'Queue length: {value}',
      },
      'myQueuePosition': <String, Object?>{
        'type': 'number',
        'labelTemplate': 'Your position: {value}',
      },
    },
  },
}, 'equipment-loan');

EngineNativeResolvedBinding _binding(
  LoomWorkflowStateMachine machine, {
  Map<String, dynamic> instanceData = const <String, dynamic>{
    'title': 'Shared lens',
  },
}) => EngineNativeResolvedBinding(
  instance: WorkflowInstance(
    instanceId: 'listing-7',
    workflowType: machine.workflowType,
    currentState: 'published',
    instanceData: instanceData,
    createdByFanId: 'owner',
  ),
  machine: machine,
  binding: const RenderBinding(
    states: const ['published'],
    role: 'member',
    tabId: 'marketplace',
    cardSurfaceFamily: 'equipment-loan',
    bindingKind: 'primary',
  ),
  definitionBindingIndex: 0,
);

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

Widget _queueCard({
  required LoomWorkflowStateMachine machine,
  required _RemoteQueueEngine engine,
  required String fanId,
  Map<String, dynamic> instanceData = const <String, dynamic>{
    'title': 'Shared lens',
  },
}) => EquipmentLoanArchetypeCard(
  resolved: _binding(machine, instanceData: instanceData),
  engine: engine,
  fanId: fanId,
  accent: Colors.blue,
  displayContext: 'detail',
  onInstanceChanged: (_) {},
);

void main() {
  tearDown(resetLoomItemQueueClientForTesting);

  test(
    'item queue client sends UUID correlation ids on all five supported operations',
    () async {
      final requests = <http.Request>[];
      final client = LoomItemQueueClient(
        workflowServiceBaseUri: Uri.parse('https://workflow.test/service/'),
        session: _TokenSession(),
        httpClient: MockClient((request) async {
          requests.add(request);
          if (request.method == 'GET' &&
              request.url.path.endsWith('/queue-memberships')) {
            return http.Response(
              jsonEncode(<String, Object?>{
                'fanId': 'member',
                'memberships': <Map<String, Object?>>[
                  <String, Object?>{
                    'instanceId': 'listing-7',
                    'itemTitle': 'Shared lens',
                    'position': 1,
                    'length': 2,
                    'joinedAt': '2026-08-28T00:00:00.000Z',
                  },
                ],
              }),
              200,
            );
          }
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode(<String, Object?>{
                'instanceId': 'listing-7',
                'length': 1,
                'viewerPosition': 1,
              }),
              200,
            );
          }
          if (request.method == 'POST') {
            return http.Response(
              jsonEncode(<String, Object?>{
                'fanId': 'member',
                'position': 1,
                'joinedAt': '2026-08-28T00:00:00.000Z',
              }),
              201,
            );
          }
          return http.Response('', 204);
        }),
      );
      addTearDown(client.close);

      await client.getItemQueue(
        communityId: 'community-test',
        instanceId: 'listing-7',
      );
      await client.joinItemQueue(
        communityId: 'community-test',
        instanceId: 'listing-7',
      );
      await client.leaveItemQueue(
        communityId: 'community-test',
        instanceId: 'listing-7',
      );
      await client.removeFromItemQueue(
        communityId: 'community-test',
        instanceId: 'listing-7',
        fanId: 'other-member',
      );
      final memberships = await client.listMyQueueMemberships(
        communityId: 'community-test',
      );

      expect(memberships.fanId, 'member');
      expect(memberships.memberships.single.position, 1);
      expect(requests, hasLength(5));
      for (final request in requests) {
        expect(request.headers['authorization'], 'Bearer test-access-token');
        expect(
          request.headers['x-loom-correlation-id'],
          matches(
            RegExp(
              r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
            ),
          ),
        );
        // The OpenAPI spec requires this only on advanceItemQueue, which this
        // client deliberately does not expose. Join is idempotent by identity.
        expect(request.headers, isNot(contains('idempotency-key')));
      }
    },
  );

  testWidgets(
    'service queue joins render positions one and two, and choose actions rather than transition ids',
    (tester) async {
      final service = _QueueService();
      addTearDown(service.close);
      overrideLoomItemQueueClientForTesting(
        LoomItemQueueClient(
          workflowServiceBaseUri: Uri.parse('https://workflow.test/'),
          session: _TokenSession(),
          httpClient: service.client,
        ),
      );
      final machine = _queueMachine(
        joinId: 'reserve-this-item',
        leaveId: 'withdraw-reservation',
      );
      final engine = _RemoteQueueEngine(const []);

      await tester.pumpWidget(
        _host(_queueCard(machine: machine, engine: engine, fanId: 'alice')),
      );
      await tester.pumpAndSettle();

      expect(find.text('You are not queued.'), findsOneWidget);
      expect(find.text('Your position: 0'), findsNothing);
      expect(
        find.byKey(const ValueKey('marketplace-action-reserve-this-item')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('marketplace-action-reserve-this-item')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Queue length: 1'), findsOneWidget);
      expect(find.text('Your position: 1'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('marketplace-action-withdraw-reservation')),
        findsOneWidget,
      );

      service.actor = 'bob';
      await tester.pumpWidget(
        _host(_queueCard(machine: machine, engine: engine, fanId: 'bob')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('marketplace-action-reserve-this-item')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Queue length: 2'), findsOneWidget);
      expect(find.text('Your position: 2'), findsOneWidget);
      expect(engine.appliedTransitionIds, isEmpty);
    },
  );

  testWidgets(
    'leaving the service queue flips the affordance back to Join queue',
    (tester) async {
      final service = _QueueService()..queuedFanIds.add('alice');
      addTearDown(service.close);
      overrideLoomItemQueueClientForTesting(
        LoomItemQueueClient(
          workflowServiceBaseUri: Uri.parse('https://workflow.test/'),
          session: _TokenSession(),
          httpClient: service.client,
        ),
      );
      final machine = _queueMachine();
      final engine = _RemoteQueueEngine(const []);

      await tester.pumpWidget(
        _host(_queueCard(machine: machine, engine: engine, fanId: 'alice')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('marketplace-action-leave-queue')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('marketplace-action-leave-queue')),
      );
      await tester.pumpAndSettle();

      expect(find.text('You are not queued.'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('marketplace-action-join-queue')),
        findsOneWidget,
      );
      expect(engine.appliedTransitionIds, isEmpty);
    },
  );

  testWidgets(
    'queue entries appear only when the service includes them for an administering caller',
    (tester) async {
      final service = _QueueService(entriesVisibleFor: {'owner'})
        ..queuedFanIds.add('alice');
      addTearDown(service.close);
      overrideLoomItemQueueClientForTesting(
        LoomItemQueueClient(
          workflowServiceBaseUri: Uri.parse('https://workflow.test/'),
          session: _TokenSession(),
          httpClient: service.client,
        ),
      );
      final machine = _queueMachine(hasAdminDecision: true);
      final engine = _RemoteQueueEngine(const []);

      service.actor = 'owner';
      await tester.pumpWidget(
        _host(_queueCard(machine: machine, engine: engine, fanId: 'owner')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Queue members'), findsOneWidget);
      expect(find.text('1. alice'), findsOneWidget);

      service.actor = 'member';
      await tester.pumpWidget(
        _host(_queueCard(machine: machine, engine: engine, fanId: 'member')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Queue length: 1'), findsOneWidget);
      expect(find.text('Queue members'), findsNothing);
      expect(find.text('No one is waiting.'), findsNothing);
    },
  );

  testWidgets(
    'a queue service error is unavailable and never rendered as a queue value',
    (tester) async {
      final service = MockClient((_) async => http.Response('down', 503));
      addTearDown(service.close);
      overrideLoomItemQueueClientForTesting(
        LoomItemQueueClient(
          workflowServiceBaseUri: Uri.parse('https://workflow.test/'),
          session: _TokenSession(),
          httpClient: service,
        ),
      );
      final machine = _queueMachine(hasLegacyQueueFields: true);

      await tester.pumpWidget(
        _host(
          _queueCard(
            machine: machine,
            engine: _RemoteQueueEngine(const []),
            fanId: 'alice',
            instanceData: const <String, dynamic>{
              'title': 'Shared lens',
              'queueLength': 99,
              'myQueuePosition': 88,
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Queue unavailable.'), findsOneWidget);
      expect(find.text('Queue length: 99'), findsNothing);
      expect(find.text('Your position: 88'), findsNothing);
      expect(find.text('You are not queued.'), findsNothing);
    },
  );
}
