import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

const _baseUri = 'https://workflow.example.test/api/';
const _communityId = 'community / one';
const _token = 'fresh-test-token';
final _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

void main() {
  group('RemoteWorkflowEngineApi success requests', () {
    test(
      'queryInstances sends and decodes the OpenAPI collection shape',
      () async {
        late http.Request sent;
        var tokenCalls = 0;
        final api = _api(
          tokenProvider: () async {
            tokenCalls++;
            return _token;
          },
          handler: (request) async {
            sent = request;
            return _jsonResponse({
              'items': [
                {
                  'instanceId': 'instance-1',
                  'workflowType': 'event',
                  'currentState': 'draft',
                  'instanceData': {'title': 'Town hall'},
                },
              ],
              'pageInfo': {'hasMore': true, 'nextCursor': 'cursor-2'},
            });
          },
        );

        final page = await api.queryInstances(
          tabId: 'ignored-tab',
          fanId: 'ignored-fan',
          workflowType: 'event',
          query: const SurfaceQuery(
            sort: SortSpec(key: 'startsAt', direction: SortDirection.desc),
          ),
          limit: 17,
          cursor: 'cursor-1',
        );

        expect(sent.method, 'GET');
        expect(
          sent.url.path,
          '/api/v1/communities/community%20%2F%20one/instances',
        );
        expect(sent.url.queryParameters, {
          'workflowType': 'event',
          'sortKey': 'startsAt',
          'limit': '17',
          'cursor': 'cursor-1',
        });
        _expectCommonHeaders(sent, mutation: false);
        expect(sent.body, isEmpty);
        expect(tokenCalls, 1);
        expect(page.hasMore, isTrue);
        expect(page.nextCursor, 'cursor-2');
        expect(page.items, hasLength(1));
        expect(page.items.single.instanceId, 'instance-1');
        expect(page.items.single.workflowType, 'event');
        expect(page.items.single.currentState, 'draft');
        expect(page.items.single.instanceData, {'title': 'Town hall'});
        expect(page.items.single.createdByFanId, isEmpty);
      },
    );

    test(
      'availableTransitionsAsync sends and decodes the render projection',
      () async {
        late http.Request sent;
        final api = _api(
          handler: (request) async {
            sent = request;
            return _jsonResponse({
              'instanceId': 'instance / 1',
              'currentState': 'draft',
              'transitions': [
                {
                  'transitionId': 'publish',
                  'label': 'Publish',
                  'action': 'publish',
                  'tone': 'positive',
                  'inputs': {
                    'note': {
                      'type': 'text',
                      'required': true,
                      'writesTo': 'note',
                    },
                  },
                },
              ],
            });
          },
        );

        final transitions = await api.availableTransitionsAsync(
          workflowType: 'ignored-by-server',
          instanceId: 'instance / 1',
          currentState: 'stale-client-state',
          instanceData: const {'stale': true},
          fanId: 'ignored-fan',
        );

        expect(sent.method, 'GET');
        expect(
          sent.url.path,
          '/api/v1/communities/community%20%2F%20one/instances/'
          'instance%20%2F%201/available-transitions',
        );
        _expectCommonHeaders(sent, mutation: false);
        expect(transitions, hasLength(1));
        final transition = transitions.single;
        expect(transition.id, 'publish');
        expect(transition.label, 'Publish');
        expect(transition.action, 'publish');
        expect(transition.tone, 'positive');
        expect(transition.from, ['draft']);
        expect(transition.to, isNull);
        expect(transition.inputs!['note']!.type, 'text');
        expect(transition.inputs!['note']!.required, isTrue);
        expect(transition.inputs!['note']!.writesTo, 'note');
      },
    );

    test('applyTransition sends and decodes a transition result', () async {
      late http.Request sent;
      final api = _api(
        handler: (request) async {
          sent = request;
          return _jsonResponse({
            'instanceId': 'instance-1',
            'workflowType': 'event',
            'currentState': 'published',
            'instanceData': {'status': 'published'},
            'updatedAt': '2026-08-16T00:00:00Z',
          });
        },
      );

      final result = await api.applyTransition(
        workflowType: 'event',
        instanceId: 'instance-1',
        transitionId: 'publish',
        fanId: 'ignored-fan',
        inputs: const {'note': 'Ready'},
      );

      expect(sent.method, 'POST');
      expect(
        sent.url.path,
        '/api/v1/communities/community%20%2F%20one/instances/instance-1/'
        'transitions',
      );
      _expectCommonHeaders(sent, mutation: true);
      expect(jsonDecode(sent.body), {
        'transitionId': 'publish',
        'inputs': {'note': 'Ready'},
      });
      expect(result.newState, 'published');
      expect(result.newInstanceData, {'status': 'published'});
    });

    test('createInstance sends and decodes a created instance id', () async {
      late http.Request sent;
      final api = _api(
        handler: (request) async {
          sent = request;
          return _jsonResponse({
            'instanceId': 'created-1',
            'workflowType': 'event',
            'currentState': 'draft',
            'instanceData': {'title': 'Town hall'},
            'updatedAt': '2026-08-16T00:00:00Z',
          }, statusCode: 201);
        },
      );

      final id = await api.createInstance(
        workflowType: 'event',
        initialInstanceData: const {'title': 'Town hall'},
        fanId: 'fan-1',
      );

      expect(sent.method, 'POST');
      expect(
        sent.url.path,
        '/api/v1/communities/community%20%2F%20one/instances',
      );
      _expectCommonHeaders(sent, mutation: true);
      expect(jsonDecode(sent.body), {
        'workflowType': 'event',
        'instanceData': {'title': 'Town hall'},
      });
      expect(id, 'created-1');
    });

    test('createInstances sends and decodes ids in response order', () async {
      late http.Request sent;
      final api = _api(
        handler: (request) async {
          sent = request;
          return _jsonResponse([
            {
              'instanceId': 'created-1',
              'workflowType': 'event',
              'currentState': 'draft',
              'instanceData': {'title': 'First'},
            },
            {
              'instanceId': 'created-2',
              'workflowType': 'event',
              'currentState': 'draft',
              'instanceData': {'title': 'Second'},
            },
          ], statusCode: 201);
        },
      );

      final ids = await api.createInstances(
        workflowType: 'event',
        initialInstanceDataList: const [
          {'title': 'First'},
          {'title': 'Second'},
        ],
        fanId: 'fan-1',
      );

      expect(sent.method, 'POST');
      expect(
        sent.url.path,
        '/api/v1/communities/community%20%2F%20one/instances/batch',
      );
      _expectCommonHeaders(sent, mutation: true);
      expect(jsonDecode(sent.body), {
        'workflowType': 'event',
        'initialInstanceDataList': [
          {'title': 'First'},
          {'title': 'Second'},
        ],
      });
      expect(ids, ['created-1', 'created-2']);
    });

    test(
      'updateInstanceFields sends PATCH and validates its success body',
      () async {
        late http.Request sent;
        final api = _api(
          handler: (request) async {
            sent = request;
            return _jsonResponse({
              'instanceId': 'instance-1',
              'workflowType': 'event',
              'currentState': 'draft',
              'instanceData': {'title': 'Updated'},
            });
          },
        );

        await api.updateInstanceFields(
          workflowType: 'ignored-by-server',
          instanceId: 'instance-1',
          fieldUpdates: const {'title': 'Updated'},
          fanId: 'ignored-fan',
        );

        expect(sent.method, 'PATCH');
        expect(
          sent.url.path,
          '/api/v1/communities/community%20%2F%20one/instances/instance-1/'
          'fields',
        );
        _expectCommonHeaders(sent, mutation: true);
        expect(jsonDecode(sent.body), {
          'fieldUpdates': {'title': 'Updated'},
        });
      },
    );

    test(
      'aggregate sends the read-only POST shape and decodes any result',
      () async {
        late http.Request sent;
        final api = _api(
          handler: (request) async {
            sent = request;
            return _jsonResponse({
              'result': [
                {'category': 'a', 'sum': 12},
              ],
            });
          },
        );

        final result = await api.aggregate(
          workflowType: 'ledger',
          column: 'amount',
          op: 'sum',
          filter: const {'paid': true},
          groupBy: 'category',
          fanId: 'ignored-fan',
        );

        expect(sent.method, 'POST');
        expect(
          sent.url.path,
          '/api/v1/communities/community%20%2F%20one/instances/aggregate',
        );
        _expectCommonHeaders(sent, mutation: false);
        expect(sent.headers, isNot(contains('idempotency-key')));
        expect(jsonDecode(sent.body), {
          'workflowType': 'ledger',
          'column': 'amount',
          'op': 'sum',
          'filter': {'paid': true},
          'groupBy': 'category',
        });
        expect(result, [
          {'category': 'a', 'sum': 12},
        ]);
      },
    );

    test('uses fresh correlation and idempotency UUIDs per mutation', () async {
      final sent = <http.Request>[];
      var tokenCalls = 0;
      final api = _api(
        tokenProvider: () async {
          tokenCalls++;
          return 'token-$tokenCalls';
        },
        handler: (request) async {
          sent.add(request);
          final number = sent.length;
          return _jsonResponse({
            'instanceId': 'created-$number',
            'workflowType': 'event',
            'currentState': 'draft',
            'instanceData': const <String, dynamic>{},
          }, statusCode: 201);
        },
      );

      await api.createInstance(
        workflowType: 'event',
        initialInstanceData: const {},
        fanId: 'fan',
      );
      await api.createInstance(
        workflowType: 'event',
        initialInstanceData: const {},
        fanId: 'fan',
      );

      expect(tokenCalls, 2);
      expect(sent[0].headers['authorization'], 'Bearer token-1');
      expect(sent[1].headers['authorization'], 'Bearer token-2');
      expect(
        sent[0].headers['x-loom-correlation-id'],
        isNot(sent[1].headers['x-loom-correlation-id']),
      );
      expect(
        sent[0].headers['idempotency-key'],
        isNot(sent[1].headers['idempotency-key']),
      );
    });
  });

  group('RemoteWorkflowEngineApi error vocabulary', () {
    final cases = <({String code, Type type})>[
      (code: 'workflow_field_edit_refused', type: WorkflowAuthorizationError),
      (code: 'workflow_guard_refused', type: StateError),
      (code: 'workflow_read_refused', type: StateError),
      (code: 'workflow_instance_not_found', type: StateError),
      (code: 'workflow_type_not_found', type: StateError),
      (code: 'workflow_state_conflict', type: StateError),
      (code: 'workflow_create_refused', type: StateError),
      (code: 'invalid_request', type: RemoteWorkflowProtocolError),
      (code: 'invalid_transition_request', type: StateError),
      (code: 'invalid_correlation_id', type: RemoteWorkflowProtocolError),
      (code: 'invalid_idempotency_key', type: RemoteWorkflowProtocolError),
      (code: 'unsupported_spec_version', type: RemoteWorkflowProtocolError),
      (
        code: 'authentication_required',
        type: RemoteWorkflowAuthenticationError,
      ),
      (
        code: 'authorization_service_unavailable',
        type: RemoteWorkflowServiceError,
      ),
      (code: 'route_not_found', type: RemoteWorkflowProtocolError),
      (code: 'workflow_service_error', type: RemoteWorkflowServiceError),
    ];

    for (final errorCase in cases) {
      test('${errorCase.code} maps to ${errorCase.type}', () async {
        final api = _api(
          handler: (_) async => _jsonResponse({
            'code': errorCase.code,
            'message': 'Informative server message.',
            'correlationId': 'correlation-for-test',
          }, statusCode: _statusFor(errorCase.code)),
        );

        Object? caught;
        try {
          await api.queryInstances(tabId: 'tab', fanId: 'fan');
        } catch (error) {
          caught = error;
        }

        expect(caught, isNotNull);
        expect(caught.runtimeType, errorCase.type);
        expect('$caught', contains(errorCase.code));
        expect('$caught', contains('Informative server message.'));
        expect('$caught', contains('correlation-for-test'));
        expect('$caught', contains('HTTP ${_statusFor(errorCase.code)}'));
      });
    }
  });

  test('unsupported methods throw immediately without token or HTTP calls', () {
    var tokenCalls = 0;
    var httpCalls = 0;
    final api = _api(
      tokenProvider: () async {
        tokenCalls++;
        return _token;
      },
      handler: (_) async {
        httpCalls++;
        return _jsonResponse(const {});
      },
    );

    expect(
      () => api.availableTransitions(
        workflowType: 'event',
        instanceId: 'instance-1',
        currentState: 'draft',
        instanceData: const {},
        fanId: 'fan',
      ),
      throwsA(
        isA<UnsupportedError>().having(
          (error) => '$error',
          'message',
          contains('availableTransitionsAsync'),
        ),
      ),
    );
    expect(
      () => api.dueNotifications(asOf: DateTime.utc(2026, 8, 16)),
      throwsA(
        isA<UnsupportedError>().having(
          (error) => '$error',
          'message',
          contains('no such operation'),
        ),
      ),
    );
    expect(tokenCalls, 0);
    expect(httpCalls, 0);
  });
}

RemoteWorkflowEngineApi _api({
  required Future<http.Response> Function(http.Request request) handler,
  Future<String> Function()? tokenProvider,
}) => RemoteWorkflowEngineApi(
  baseUri: Uri.parse(_baseUri),
  communityId: _communityId,
  bearerTokenProvider: tokenProvider ?? () async => _token,
  httpClient: MockClient(handler),
);

http.Response _jsonResponse(Object? body, {int statusCode = 200}) =>
    http.Response(
      jsonEncode(body),
      statusCode,
      headers: const {'content-type': 'application/json'},
    );

void _expectCommonHeaders(http.Request request, {required bool mutation}) {
  expect(request.headers['authorization'], 'Bearer $_token');
  expect(request.headers['x-loom-correlation-id'], matches(_uuidPattern));
  if (mutation) {
    expect(request.headers['idempotency-key'], matches(_uuidPattern));
  } else {
    expect(request.headers, isNot(contains('idempotency-key')));
  }
  if (request.method == 'POST' || request.method == 'PATCH') {
    expect(request.headers['content-type'], 'application/json; charset=utf-8');
  }
}

int _statusFor(String code) => switch (code) {
  'authentication_required' => 401,
  'workflow_field_edit_refused' ||
  'workflow_guard_refused' ||
  'workflow_read_refused' ||
  'workflow_create_refused' => 403,
  'workflow_instance_not_found' ||
  'workflow_type_not_found' ||
  'route_not_found' => 404,
  'workflow_state_conflict' => 409,
  'unsupported_spec_version' => 422,
  'authorization_service_unavailable' => 503,
  'workflow_service_error' => 500,
  _ => 400,
};
