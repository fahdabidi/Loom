import 'dart:convert';
import 'dart:io';

import 'package:loom_ux_judges/src/validator/validator_http_server.dart';
import 'package:test/test.dart';

void main() {
  group('validator HTTP server', () {
    late HttpServer server;
    late Uri base;
    late HttpClient client;

    setUp(() async {
      // port: 0 -> OS-assigned ephemeral port, so tests never collide with a
      // real server (e.g. the dev instance on 8787) or each other.
      server = await startValidatorServer(
        address: InternetAddress.loopbackIPv4,
        port: 0,
      );
      base = Uri.parse('http://127.0.0.1:${server.port}');
      client = HttpClient();
    });

    tearDown(() async {
      client.close(force: true);
      await server.close(force: true);
    });

    Future<HttpClientResponse> post(String path, String body) async {
      final request = await client.postUrl(base.replace(path: path));
      request.headers.contentType = ContentType.json;
      request.write(body);
      return request.close();
    }

    Future<Map<String, dynamic>> readJson(HttpClientResponse response) async {
      final body = await utf8.decoder.bind(response).join();
      return jsonDecode(body) as Map<String, dynamic>;
    }

    test('GET /health returns ok', () async {
      final request = await client.getUrl(base.replace(path: '/health'));
      final response = await request.close();

      expect(response.statusCode, HttpStatus.ok);
      expect(await readJson(response), {'status': 'ok'});
    });

    test('POST /validate on a clean package returns zero findings', () async {
      final response = await post('/validate', jsonEncode(_hikeClubPackage));

      expect(response.statusCode, HttpStatus.ok);
      final json = await readJson(response);
      expect(json['status'], 'pass');
      expect(json['errorCount'], 0);
      expect(json['warningCount'], 0);
      expect(json['findings'], isEmpty);
    });

    test(
      'POST /validate surfaces the expected-affordance warnings for a type '
      'with editableFields but no editGuard and no create path',
      () async {
        final response = await post('/validate', jsonEncode(_noEditGuardOrCreatePackage));

        expect(response.statusCode, HttpStatus.ok);
        final json = await readJson(response);
        expect(json['status'], 'pass', reason: 'warnings never block pass');
        expect(json['warningCount'], 2);
        final types = (json['findings'] as List)
            .map((f) => (f as Map<String, dynamic>)['type'])
            .toSet();
        expect(types, {
          'editable_fields_without_edit_guard',
          'no_creation_path_for_editable_type',
        });
      },
    );

    test('POST /validate on malformed JSON returns 400', () async {
      final response = await post('/validate', '{not valid json');

      expect(response.statusCode, HttpStatus.badRequest);
      final json = await readJson(response);
      expect(json['error'], 'invalid_json');
    });

    test('POST /validate strips // and /* */ JSONC comments', () async {
      const jsoncBody = '''
      {
        // a line comment
        "schemaVersion": 1,
        "packageId": "init_x_1",
        "communityId": "community_x",
        "communityHandle": "x",
        "displayName": "X",
        "extensionId": "ext_x",
        "seedDataFiles": [],
        /* a block
           comment */
        "experience": {
          "experienceSchemaVersion": 2,
          "workflowGrammarVersion": 1,
          "displayName": "X",
          "personas": [],
          "workflowDefinitions": {}
        }
      }
      ''';

      final response = await post('/validate', jsoncBody);

      expect(response.statusCode, HttpStatus.ok);
      final json = await readJson(response);
      expect(json['status'], 'fail');
      expect(
        (json['findings'] as List).any(
          (f) => (f as Map<String, dynamic>)['type'] ==
              'missing_workflow_definitions',
        ),
        isTrue,
      );
    });

    test('unknown route returns 404', () async {
      final request = await client.getUrl(base.replace(path: '/nope'));
      final response = await request.close();

      expect(response.statusCode, HttpStatus.notFound);
      final json = await readJson(response);
      expect(json['error'], 'not_found');
    });

    test('OPTIONS preflight returns 204 with CORS headers', () async {
      final request = await client.openUrl(
        'OPTIONS',
        base.replace(path: '/validate'),
      );
      final response = await request.close();

      expect(response.statusCode, HttpStatus.noContent);
      expect(
        response.headers.value('access-control-allow-origin'),
        '*',
      );
    });
  });
}

const _hikeClubPackage = {
  'schemaVersion': 1,
  'packageId': 'init_hiking_club_1',
  'communityId': 'community_hiking_club',
  'communityHandle': 'hiking-club',
  'displayName': 'Hiking Club',
  'extensionId': 'ext_hiking_club',
  'branding': {'accentColor': '#2D6A4F'},
  'seedDataFiles': <dynamic>[],
  'experience': {
    'experienceSchemaVersion': 2,
    'workflowGrammarVersion': 1,
    'displayName': 'Hiking Club',
    'tagline': 'Weekend trails.',
    'accentColor': '#2D6A4F',
    'personas': [
      {
        'personaId': 'hiking-organizer',
        'label': 'Organizer',
        'roleLabel': 'Organizer',
        'description': 'Plans hikes.',
      },
      {
        'personaId': 'hiking-member',
        'label': 'Member',
        'roleLabel': 'Member',
        'description': 'Joins hikes.',
      },
    ],
    'workflowDefinitions': {
      'hike-rsvp': {
        'initialState': 'open',
        'states': {
          'open': {
            'label': 'Signups open',
            'tone': 'positive',
            'editableFields': ['title', 'capacity'],
            'editGuard': {
              'allowedPersonaIds': ['hiking-organizer'],
            },
          },
          'cancelled': {
            'label': 'Cancelled',
            'tone': 'negative',
            'isTerminal': true,
          },
        },
        'transitions': [
          {
            'id': 'rsvp-going',
            'label': "I'm going",
            'tone': 'primary',
            'from': ['open'],
            'to': null,
            'guard': {
              'allowedPersonaIds': ['hiking-member'],
              'actorInList': {'key': 'goingPersonaIds', 'present': false},
              'formula': 'size(goingPersonaIds) < capacity',
            },
            'effects': [
              {'op': 'appendUnique', 'key': 'goingPersonaIds', 'value': r'$actor'},
            ],
          },
          {
            'id': 'cancel-hike',
            'label': 'Cancel hike',
            'tone': 'destructive',
            'from': ['open'],
            'to': 'cancelled',
            'guard': {
              'allowedPersonaIds': ['hiking-organizer'],
            },
          },
        ],
        'renderBindings': [
          {
            'states': ['open'],
            'role': 'any',
            'tabId': 'calendar',
            'cardSurfaceFamily': 'event-rsvp',
            'bindingKind': 'primary',
            'actions': [
              {
                'kind': 'create',
                'label': 'New hike',
                'byPersonaIds': ['hiking-organizer'],
                'scope': 'tab',
                'presentation': 'fab',
              },
            ],
          },
        ],
        'instanceDataSchema': {
          'title': {
            'type': 'text',
            'required': true,
            'writableBy': 'formEntry',
          },
          'capacity': {
            'type': 'number',
            'required': true,
            'writableBy': 'formEntry',
          },
          'goingPersonaIds': {'type': 'personaId[]', 'writableBy': 'effect'},
        },
      },
    },
    'workflowInstances': [
      {
        'instanceId': 'hike-eagle-ridge',
        'workflowType': 'hike-rsvp',
        'currentState': 'open',
        'createdByPersonaId': 'hiking-organizer',
        'instanceData': {'title': 'Eagle Ridge loop', 'capacity': 12},
      },
    ],
  },
};

const _noEditGuardOrCreatePackage = {
  'schemaVersion': 1,
  'packageId': 'init_no_gaps_1',
  'communityId': 'community_no_gaps',
  'communityHandle': 'no-gaps',
  'displayName': 'No Gaps',
  'extensionId': 'ext_no_gaps',
  'seedDataFiles': <dynamic>[],
  'experience': {
    'experienceSchemaVersion': 2,
    'workflowGrammarVersion': 1,
    'displayName': 'No Gaps',
    'personas': [
      {
        'personaId': 'organizer',
        'label': 'Organizer',
        'roleLabel': 'Organizer',
        'description': 'Manages things.',
      },
    ],
    'workflowDefinitions': {
      'thing': {
        'initialState': 'open',
        'states': {
          'open': {
            'label': 'Open',
            'editableFields': ['title'],
          },
        },
        'transitions': [
          {
            'id': 'noop',
            'label': 'Noop',
            'from': ['open'],
            'to': null,
          },
        ],
        'instanceDataSchema': {
          'title': {
            'type': 'text',
            'required': true,
            'writableBy': 'formEntry',
          },
        },
      },
    },
    'workflowInstances': [
      {
        'instanceId': 'thing-1',
        'workflowType': 'thing',
        'currentState': 'open',
        'createdByPersonaId': 'organizer',
        'instanceData': {'title': 'Only ever this one'},
      },
    ],
  },
};
