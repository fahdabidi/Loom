import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:loom_auth_session/loom_auth_session.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';

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

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

Map<String, Object?> _preferenceSet({
  List<Map<String, Object?>> preferences = const <Map<String, Object?>>[],
}) => <String, Object?>{
  'fanId': 'fan-1',
  'preferences': preferences,
  'platformDefault': <String, Object?>{
    'channels': <String>['inbox', 'push'],
    'muted': false,
  },
};

Map<String, Object?> _memberPreference() => <String, Object?>{
  'communityId': 'community_garden_club',
  'channels': <String>['inbox', 'push'],
  'muted': false,
  'source': 'member',
  'updatedAt': '2026-08-29T00:00:00.000Z',
};

LoomNotificationPreferencesClient _client(http.Client httpClient) =>
    LoomNotificationPreferencesClient(
      fanPassportServiceBaseUri: Uri.parse('https://identity.test/service/'),
      session: _TokenSession(),
      httpClient: httpClient,
    );

void main() {
  test(
    'notification preference client sends UUID correlation ids and parses an identifier-free platform default',
    () async {
      final requests = <http.Request>[];
      final httpClient = MockClient((request) async {
        requests.add(request);
        expect(
          request.url.path,
          '/service/v1/fan-passports/fan-1/notification-preferences',
        );
        if (request.method == 'GET') {
          return http.Response(jsonEncode(_preferenceSet()), 200);
        }
        return http.Response(jsonEncode(_memberPreference()), 200);
      });
      final client = _client(httpClient);
      addTearDown(client.close);

      final preferences = await client.listNotificationPreferences(
        fanId: 'fan-1',
      );
      expect(preferences.preferences, isEmpty);
      expect(preferences.platformDefault.channels, const <NotificationChannel>[
        NotificationChannel.inbox,
        NotificationChannel.push,
      ]);
      expect(preferences.platformDefault.muted, isFalse);

      await client.setCommunityNotificationPreference(
        fanId: 'fan-1',
        communityId: 'community_garden_club',
        channels: const <NotificationChannel>[NotificationChannel.inbox],
        muted: false,
      );

      expect(requests, hasLength(2));
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
      }
      final write = requests.last;
      expect(write.method, 'PUT');
      expect(write.headers, isNot(contains('idempotency-key')));
      expect(jsonDecode(write.body), <String, Object?>{
        'communityId': 'community_garden_club',
        'channels': <String>['inbox'],
        'muted': false,
      });
    },
  );

  test('an empty channel list is rejected before it can be sent', () async {
    var requests = 0;
    final httpClient = MockClient((_) async {
      requests += 1;
      return http.Response('unexpected request', 500);
    });
    final client = _client(httpClient);
    addTearDown(client.close);

    await expectLater(
      client.setCommunityNotificationPreference(
        fanId: 'fan-1',
        communityId: 'community_garden_club',
        channels: const <NotificationChannel>[],
        muted: true,
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(requests, 0);
  });

  testWidgets(
    'identical values show whether they are a platform default or the member choice',
    (tester) async {
      final defaultHttpClient = MockClient(
        (_) async => http.Response(jsonEncode(_preferenceSet()), 200),
      );
      final defaultClient = _client(defaultHttpClient);
      addTearDown(defaultClient.close);
      await tester.pumpWidget(
        _host(
          CommunityNotificationPreferenceControl(
            key: const ValueKey('default-preference'),
            client: defaultClient,
            fanId: 'fan-1',
            communityId: 'community_garden_club',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'You have not chosen. You are following the platform default.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('This is your chosen notification setting.'),
        findsNothing,
      );

      final memberHttpClient = MockClient(
        (_) async => http.Response(
          jsonEncode(
            _preferenceSet(
              preferences: <Map<String, Object?>>[_memberPreference()],
            ),
          ),
          200,
        ),
      );
      final memberClient = _client(memberHttpClient);
      addTearDown(memberClient.close);
      await tester.pumpWidget(
        _host(
          CommunityNotificationPreferenceControl(
            key: const ValueKey('member-preference'),
            client: memberClient,
            fanId: 'fan-1',
            communityId: 'community_garden_club',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('This is your chosen notification setting.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'You have not chosen. You are following the platform default.',
        ),
        findsNothing,
      );
    },
  );

  testWidgets('choosing Muted retains inbox and sends muted true', (
    tester,
  ) async {
    Map<String, Object?>? written;
    final httpClient = MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(jsonEncode(_preferenceSet()), 200);
      }
      written = Map<String, Object?>.from(jsonDecode(request.body) as Map);
      return http.Response(
        jsonEncode(<String, Object?>{
          'communityId': 'community_garden_club',
          'channels': <String>['inbox'],
          'muted': true,
          'source': 'member',
          'updatedAt': '2026-08-29T00:00:00.000Z',
        }),
        200,
      );
    });
    final client = _client(httpClient);
    addTearDown(client.close);
    await tester.pumpWidget(
      _host(
        CommunityNotificationPreferenceControl(
          client: client,
          fanId: 'fan-1',
          communityId: 'community_garden_club',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Muted'));
    await tester.pumpAndSettle();

    expect(written, <String, Object?>{
      'communityId': 'community_garden_club',
      'channels': <String>['inbox'],
      'muted': true,
    });
    expect(
      find.text('This is your chosen notification setting.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'a service error is unavailable rather than the member having no choice',
    (tester) async {
      final httpClient = MockClient(
        (_) async => http.Response('Fan Passport unavailable', 503),
      );
      final client = _client(httpClient);
      addTearDown(client.close);
      await tester.pumpWidget(
        _host(
          CommunityNotificationPreferenceControl(
            client: client,
            fanId: 'fan-1',
            communityId: 'community_garden_club',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Notification preferences are unavailable.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'You have not chosen. You are following the platform default.',
        ),
        findsNothing,
      );
    },
  );
}
