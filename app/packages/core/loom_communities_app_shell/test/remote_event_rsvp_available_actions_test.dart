import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:loom_auth_session/loom_auth_session.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

const _cameraFixtureRelative =
    'docs/references/communities/Loom_Communities_Workflow_Engine_CameraClub_Example.jsonc';
const _communityId = 'community_camera_club';
const _organizerId = 'fan-camera-organizer-1';
const _eventId = 'community_camera_club_photo-walk-rsvp_ak8lexbtkj3r';
const _responseId =
    'community_camera_club_photo-walk-response_organizer_after_publish';

final class _MemoryStorage implements LoomAuthSecureStorageBackend {
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
        clientId: 'remote-event-rsvp-available-actions-test',
        secureStorage: _MemoryStorage(),
      );

  @override
  Future<String> currentAccessToken() async => 'remote-event-rsvp-test-token';
}

/// A controlled workflow-service projection for the Camera Club event that
/// exposed the production dead end. The transport deliberately gives a
/// persisted response action request a failure after publish, so the test
/// independently proves that a secondary action-load failure cannot erase the
/// event actions already loaded from the server.
final class _CameraClubRemoteTransport {
  _CameraClubRemoteTransport() {
    client = MockClient(_handle);
  }

  late final http.Client client;
  final List<http.Request> requests = <http.Request>[];
  bool published = false;
  bool cancelled = false;

  String get _instancesPath => '/api/v1/communities/$_communityId/instances';
  String get _eventActionsPath =>
      '$_instancesPath/$_eventId/available-transitions';
  String get _responseActionsPath =>
      '$_instancesPath/$_responseId/available-transitions';

  List<String> get availableTransitionPaths => <String>[
    for (final request in requests)
      if (request.method == 'GET' &&
          request.url.path.endsWith('/available-transitions'))
        request.url.path,
  ];

  List<String> get unexpectedAvailableTransitionPaths => <String>[
    for (final path in availableTransitionPaths)
      if (path != _eventActionsPath && path != _responseActionsPath) path,
  ];

  RemoteWorkflowEngineApi createEngine() => RemoteWorkflowEngineApi(
    baseUri: Uri.parse('https://workflow.test/api/'),
    communityId: _communityId,
    bearerTokenProvider: () async => 'remote-event-rsvp-test-token',
    httpClient: client,
  );

  Future<http.Response> _handle(http.Request request) async {
    requests.add(request);
    final path = request.url.path;
    if (request.method == 'GET' && path == _instancesPath) {
      return _json(_instancePage());
    }
    if (request.method == 'GET' && path == _eventActionsPath) {
      // This is the deployed projection from the root-cause trace, with the
      // adapter-required instanceId added to make it a complete API response.
      return _json(<String, Object?>{
        'instanceId': _eventId,
        'currentState': published ? 'open' : 'draft',
        'transitions': published
            ? <Map<String, Object?>>[
                <String, Object?>{
                  'transitionId': 'cancel-walk',
                  'label': 'Cancel walk',
                  'action': 'cancel',
                  'tone': 'destructive',
                },
              ]
            : <Map<String, Object?>>[
                <String, Object?>{
                  'transitionId': 'publish-walk',
                  'label': 'Publish walk',
                  'action': 'create',
                  'tone': 'primary',
                },
                <String, Object?>{
                  'transitionId': 'cancel-walk',
                  'label': 'Cancel walk',
                  'action': 'cancel',
                  'tone': 'destructive',
                },
              ],
      });
    }
    if (request.method == 'GET' && path == _responseActionsPath) {
      // This row is persisted: the failure is intentionally unrelated to a
      // missing synthetic id. Parent actions must survive it.
      return _json(<String, Object?>{
        'code': 'workflow_service_error',
        'message': 'Controlled response-action failure.',
      }, statusCode: 503);
    }
    if (request.method == 'POST' &&
        path == '$_instancesPath/$_eventId/transitions') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final transitionId = body['transitionId'];
      if (transitionId == 'publish-walk') {
        published = true;
        return _json(_eventInstance());
      }
      if (transitionId == 'cancel-walk') {
        cancelled = true;
        return _json(_eventInstance(currentState: 'cancelled'));
      }
    }
    return _json(<String, Object?>{
      'code': 'route_not_found',
      'message': 'Unexpected ${request.method} $path',
    }, statusCode: 404);
  }

  Map<String, Object?> _instancePage() => <String, Object?>{
    'items': <Map<String, Object?>>[_eventInstance()],
    'pageInfo': const <String, Object?>{'hasMore': false},
  };

  Map<String, Object?> _eventInstance({String? currentState}) =>
      <String, Object?>{
        'instanceId': _eventId,
        'workflowType': 'photo-walk-rsvp',
        'currentState': currentState ?? (published ? 'open' : 'draft'),
        'instanceData': <String, Object?>{
          'title': 'Remote Camera Club photo walk',
          'routeName': 'Presidio shoreline',
          'eventDate': '2026-09-20',
          'eventTime': '09:00',
          'location': 'Battery East trailhead',
          'organizerName': 'Camera Club organizer',
          'capacity': 12,
          'weatherChecklistNotes': 'Bring a camera and lens cloth.',
          // Before publish there is deliberately no response row for the
          // organizer. The server must never be asked to address one.
          'responses': published
              ? <Map<String, Object?>>[
                  <String, Object?>{
                    r'$id': _responseId,
                    r'$state': 'pending',
                    'eventId': _eventId,
                    'fanId': _organizerId,
                  },
                ]
              : const <Map<String, Object?>>[],
        },
      };

  void close() => client.close();
}

http.Response _json(Object body, {int statusCode = 200}) => http.Response(
  jsonEncode(body),
  statusCode,
  headers: const <String, String>{'content-type': 'application/json'},
);

File _fixtureFile() {
  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidate = File('${directory.path}/$_cameraFixtureRelative');
    if (candidate.existsSync()) return candidate;
    directory = directory.parent;
  }
  throw StateError('Could not find $_cameraFixtureRelative');
}

LoomExperienceDefinition _cameraExperience() {
  final source =
      jsonDecode(stripJsonComments(_fixtureFile().readAsStringSync()))
          as Map<String, dynamic>;
  return experienceForExtensionId(
    source['extensionId'] as String,
    displayName: source['displayName'] as String,
    specVersion: source['specVersion'] as int,
    experienceConfiguration: Map<String, dynamic>.from(
      source['experience'] as Map,
    ),
  );
}

Widget _calendar(WorkflowEngineApi engine) {
  final experience = _cameraExperience();
  final organizer = experience.actorIdentities!.singleWhere(
    (identity) => identity.roleId == 'camera-club-organizer',
  );
  return MaterialApp(
    home: ActiveIdentityScope(
      identity: ActiveIdentityContext(
        accountId: _organizerId,
        authApi: LocalAuthApi(),
        roleId: 'camera-club-organizer',
      ),
      child: Scaffold(
        body: SingleChildScrollView(
          child: EngineNativeCalendarSurface(
            experience: experience,
            actorIdentity: organizer,
            accent: Colors.blue,
            modernTheme: null,
            engine: engine,
            currentDate: () => DateTime(2026, 9, 20),
          ),
        ),
      ),
    ),
  );
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  required String description,
}) async {
  for (var attempt = 0; attempt < 80; attempt++) {
    await tester.pump(const Duration(milliseconds: 25));
    if (condition()) return;
  }
  throw TestFailure('Timed out waiting for $description.');
}

Future<void> _exerciseRemoteCalendar(
  WidgetTester tester, {
  required bool wrapWithReplica,
}) async {
  final transport = _CameraClubRemoteTransport();
  addTearDown(transport.close);
  final remote = transport.createEngine();
  LoomWorkflowReplicaCoordinator? coordinator;
  final WorkflowEngineApi engine;
  if (wrapWithReplica) {
    final directory = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('loom-remote-event-rsvp-replica-'),
    ))!;
    addTearDown(() async {
      coordinator?.dispose();
      await directory.delete(recursive: true);
    });
    coordinator = LoomWorkflowReplicaCoordinator(
      databaseDirectory: directory.path,
      visibleChangesClient: LoomVisibleChangesClient(
        workflowServiceBaseUri: Uri.parse('https://workflow.test/api/'),
        session: _TestSession(),
        httpClient: transport.client,
      ),
    );
    engine = coordinator.wrap(remote, communityId: _communityId);
  } else {
    engine = remote;
  }

  await tester.pumpWidget(_calendar(engine));
  final publish = find.byKey(
    const ValueKey('event-rsvp-$_eventId-action-publish-walk'),
  );
  final cancel = find.byKey(
    const ValueKey('event-rsvp-$_eventId-action-cancel-walk'),
  );
  await _pumpUntil(
    tester,
    () => publish.evaluate().isNotEmpty && cancel.evaluate().isNotEmpty,
    description: 'draft event-level Publish and Cancel actions',
  );

  expect(publish, findsOneWidget);
  expect(cancel, findsOneWidget);
  expect(
    transport.unexpectedAvailableTransitionPaths,
    isEmpty,
    reason:
        'A missing response row has no persisted instance id, so the remote '
        'adapter must receive no synthetic or empty response action request.',
  );
  expect(
    transport.availableTransitionPaths,
    [transport._eventActionsPath],
    reason: 'Only the parent event action request is valid before publish.',
  );

  await tester.ensureVisible(publish);
  await tester.tap(publish);
  await _pumpUntil(
    tester,
    () => transport.published,
    description: 'Publish walk remote transition',
  );

  // Reload from the HTTP adapter rather than relying only on the mutation
  // result held by the card. The response row now has a durable id.
  final reloaded = await engine.queryInstances(
    tabId: 'calendar',
    fanId: _organizerId,
    limit: 100,
  );
  final event = reloaded.items.singleWhere(
    (instance) => instance.instanceId == _eventId,
  );
  expect(event.currentState, 'open');
  final persistedResponse =
      (event.instanceData['responses'] as List).single as Map<String, dynamic>;
  expect(persistedResponse[r'$id'], _responseId);

  await _pumpUntil(
    tester,
    () => transport.availableTransitionPaths.contains(
      transport._responseActionsPath,
    ),
    description: 'persisted response action request after publish',
  );
  expect(
    transport.unexpectedAvailableTransitionPaths,
    isEmpty,
    reason: 'Every response action request after publish must name its row id.',
  );
  expect(
    transport.availableTransitionPaths.where(
      (path) => path == transport._responseActionsPath,
    ),
    isNotEmpty,
    reason:
        'The controlled failure must exercise the persisted secondary '
        'response-action request, independently of the absent-row case.',
  );
  expect(
    find.text(
      'Could not load RSVP response actions. Event actions remain available.',
    ),
    findsOneWidget,
    reason:
        'A secondary load failure must be visible without discarding the '
        'loaded event actions.',
  );

  // The response request above deliberately returned 503. Cancel remains a
  // usable event-level action, proving the first successful action result was
  // retained instead of being discarded with the secondary failure.
  await tester.ensureVisible(cancel);
  await tester.tap(cancel);
  await _pumpUntil(
    tester,
    () => transport.cancelled,
    description: 'Cancel walk after a failed secondary action load',
  );
}

void main() {
  for (final wrapped in <bool>[false, true]) {
    testWidgets(
      '${wrapped ? 'replica-wrapped' : 'direct'} remote Camera Club RSVP '
      'keeps event actions usable without a synthetic response request',
      (tester) => _exerciseRemoteCalendar(tester, wrapWithReplica: wrapped),
    );
  }
}
