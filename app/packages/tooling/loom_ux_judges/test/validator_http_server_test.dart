import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:loom_ux_judges/src/validator/validator_http_server.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show currentCommunitySpecVersion;
import 'package:test/test.dart';

void main() {
  group('validator HTTP server', () {
    late HttpServer server;
    late Uri base;
    late HttpClient client;
    late Directory tempDirectory;
    late String validatorLogPath;

    setUp(() async {
      // port: 0 -> OS-assigned ephemeral port, so tests never collide with a
      // real server (e.g. the dev instance on 8787) or each other.
      tempDirectory = await Directory.systemTemp.createTemp(
        'loom-validator-server-test-',
      );
      validatorLogPath = '${tempDirectory.path}/rounds.jsonl';
      server = await startValidatorServer(
        address: InternetAddress.loopbackIPv4,
        port: 0,
        validatorLogPath: validatorLogPath,
      );
      base = Uri.parse('http://127.0.0.1:${server.port}');
      client = HttpClient();
    });

    tearDown(() async {
      client.close(force: true);
      await server.close(force: true);
      await tempDirectory.delete(recursive: true);
    });

    Future<HttpClientResponse> post(
      String path,
      String body, {
      Map<String, String> headers = const {},
    }) async {
      final request = await client.postUrl(base.replace(path: path));
      request.headers.contentType = ContentType.json;
      headers.forEach(request.headers.set);
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
      'POST /validate writes exactly one round log line with absent headers',
      () async {
        final response = await post('/validate', jsonEncode(_hikeClubPackage));
        expect(response.statusCode, HttpStatus.ok);
        await readJson(response);

        final lines = await File(validatorLogPath).readAsLines();
        expect(lines, hasLength(1));
        final logged = jsonDecode(lines.single) as Map<String, dynamic>;
        expect(logged.keys.toSet(), {
          'at',
          'dispatch',
          'round',
          'status',
          'errorCount',
          'warningCount',
          'findingTypes',
          'packageId',
          'communityId',
        });
        expect(DateTime.parse(logged['at'] as String).isUtc, isTrue);
        expect(logged['dispatch'], 'unknown');
        expect(logged['round'], isNull);
        expect(logged['status'], 'pass');
        expect(logged['errorCount'], 0);
        expect(logged['warningCount'], 0);
        expect(logged['findingTypes'], isEmpty);
        expect(logged['packageId'], 'init_hiking_club_1');
        expect(logged['communityId'], 'community_hiking_club');
      },
    );

    test('POST /validate captures dispatch and round headers', () async {
      final packageWithoutIds = Map<String, dynamic>.from(_hikeClubPackage)
        ..remove('packageId')
        ..remove('communityId');
      final response = await post(
        '/validate',
        jsonEncode(packageWithoutIds),
        headers: {'X-Loom-Dispatch': 'dispatch-42', 'X-Loom-Round': '3'},
      );
      expect(response.statusCode, HttpStatus.ok);
      await readJson(response);

      final lines = await File(validatorLogPath).readAsLines();
      expect(lines, hasLength(1));
      final logged = jsonDecode(lines.single) as Map<String, dynamic>;
      expect(logged['dispatch'], 'dispatch-42');
      expect(logged['round'], 3);
      expect(logged['packageId'], isNull);
      expect(logged['communityId'], isNull);
    });

    test('POST /validate counts repeated finding types', () async {
      final package =
          jsonDecode(jsonEncode(_hikeClubPackage)) as Map<String, dynamic>;
      final experience = package['experience'] as Map<String, dynamic>;
      final definitions =
          experience['workflowDefinitions'] as Map<String, dynamic>;
      final workflow = definitions['hike-rsvp'] as Map<String, dynamic>;
      final states = workflow['states'] as Map<String, dynamic>;
      (states['open'] as Map<String, dynamic>)['isTerminated'] = false;
      (states['cancelled'] as Map<String, dynamic>)['isTerminated'] = true;

      final response = await post('/validate', jsonEncode(package));
      expect(response.statusCode, HttpStatus.ok);
      await readJson(response);

      final lines = await File(validatorLogPath).readAsLines();
      expect(lines, hasLength(1));
      final logged = jsonDecode(lines.single) as Map<String, dynamic>;
      final findingTypes = logged['findingTypes'] as Map<String, dynamic>;
      expect(findingTypes['unknown_key'], 2);
    });

    test(
      'an unwritable validator log still returns the normal response',
      () async {
        final unwritableServer = await startValidatorServer(
          address: InternetAddress.loopbackIPv4,
          port: 0,
          // Opening a directory as an append-only file deterministically fails.
          validatorLogPath: tempDirectory.path,
        );
        final unwritableClient = HttpClient();
        try {
          final request = await unwritableClient.postUrl(
            Uri.parse('http://127.0.0.1:${unwritableServer.port}/validate'),
          );
          request.headers.contentType = ContentType.json;
          request.write(jsonEncode(_hikeClubPackage));
          final response = await request.close();

          expect(response.statusCode, HttpStatus.ok);
          final json = await readJson(response);
          expect(json['status'], 'pass');
          expect(json['errorCount'], 0);
          expect(json['warningCount'], 0);
        } finally {
          unwritableClient.close(force: true);
          await unwritableServer.close(force: true);
        }
      },
    );

    test('POST /validate also accepts the package wrapped as '
        'packageJson: "<string>"', () async {
      final wrapped = jsonEncode({'packageJson': jsonEncode(_hikeClubPackage)});

      final response = await post('/validate', wrapped);

      expect(response.statusCode, HttpStatus.ok);
      final json = await readJson(response);
      expect(json['status'], 'pass');
      expect(json['errorCount'], 0);
      expect(json['warningCount'], 0);
      expect(json['findings'], isEmpty);
    });

    test('POST /validate surfaces the expected-affordance warnings for a type '
        'with editableFields but no editGuard and no create path', () async {
      final response = await post(
        '/validate',
        jsonEncode(_noEditGuardOrCreatePackage),
      );

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
    });

    test('POST /validate on malformed JSON returns 400', () async {
      final response = await post('/validate', '{not valid json');

      expect(response.statusCode, HttpStatus.badRequest);
      final json = await readJson(response);
      expect(json['error'], 'invalid_json');

      final lines = await File(validatorLogPath).readAsLines();
      expect(lines, hasLength(1));
      final logged = jsonDecode(lines.single) as Map<String, dynamic>;
      expect(logged['status'], isNull);
      expect(logged['errorCount'], isNull);
      expect(logged['warningCount'], isNull);
      expect(logged['findingTypes'], isEmpty);
    });

    test('POST /validate strips // and /* */ JSONC comments', () async {
      const jsoncBody =
          '''
      {
        // a line comment
        "specVersion": $currentCommunitySpecVersion,
        "packageId": "init_x_1",
        "communityId": "community_x",
        "communityHandle": "x",
        "displayName": "X",
        "extensionId": "ext_x",
        "seedDataFiles": [],
        /* a block
           comment */
        "experience": {
          "displayName": "X",
          "roles": [],
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
          (f) =>
              (f as Map<String, dynamic>)['type'] ==
              'missing_workflow_definitions',
        ),
        isTrue,
      );
    });

    test('POST /package on a clean package returns a downloadable zip '
        'containing the extension manifest + init package pair', () async {
      final request = await client.postUrl(base.replace(path: '/package'));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(_hikeClubPackage));
      final response = await request.close();

      expect(response.statusCode, HttpStatus.ok);
      expect(response.headers.contentType?.mimeType, 'application/zip');
      expect(
        response.headers.value('content-disposition'),
        contains('hiking-club-loom-package.zip'),
      );
      expect(response.headers.value('x-loom-extension-id'), 'ext_hiking_club');

      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
      }
      final archive = ZipDecoder().decodeBytes(Uint8List.fromList(bytes));
      final names = archive.files.map((f) => f.name).toSet();
      expect(names, {
        'hiking-club.loom-extension.zip',
        'hiking-club.loom-init.zip',
      });

      final manifestFile = archive.findFile('hiking-club.loom-extension.zip')!;
      final manifest =
          jsonDecode(utf8.decode(manifestFile.content as List<int>))
              as Map<String, dynamic>;
      expect(manifest['extensionId'], 'ext_hiking_club');
      expect(manifest['displayName'], 'Hiking Club');
      expect(manifest['specVersion'], currentCommunitySpecVersion);
      expect(manifest, isNot(contains('schemaVersion')));
      expect(manifest['version'], isA<String>());

      final initFile = archive.findFile('hiking-club.loom-init.zip')!;
      final initPackage =
          jsonDecode(utf8.decode(initFile.content as List<int>))
              as Map<String, dynamic>;
      expect(initPackage['extensionId'], 'ext_hiking_club');
      expect(initPackage['communityId'], 'community_hiking_club');
    });

    test(
      'POST /package refuses a package with validator errors (422, no zip)',
      () async {
        final broken = Map<String, dynamic>.from(_hikeClubPackage)
          ..remove('experience');

        final request = await client.postUrl(base.replace(path: '/package'));
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(broken));
        final response = await request.close();

        expect(response.statusCode, HttpStatus.unprocessableEntity);
        final json = await readJson(response);
        expect(json['error'], 'package_has_errors');
        final validation = json['validation'] as Map<String, dynamic>;
        expect(validation['errorCount'], greaterThan(0));
      },
    );

    test('POST /package refuses a validator-clean package missing fields the '
        'real installer requires (422)', () async {
      final missingExtensionId = Map<String, dynamic>.from(_hikeClubPackage)
        ..remove('extensionId');

      final request = await client.postUrl(base.replace(path: '/package'));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(missingExtensionId));
      final response = await request.close();

      expect(response.statusCode, HttpStatus.unprocessableEntity);
      final json = await readJson(response);
      expect(json['error'], 'package_build_failed');
    });

    test('POST /package.json on a clean package returns the manifest + init '
        'package pair inline as JSON (no binary response)', () async {
      final response = await post(
        '/package.json',
        jsonEncode(_hikeClubPackage),
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.headers.contentType?.mimeType, 'application/json');
      final json = await readJson(response);

      expect(json['extensionId'], 'ext_hiking_club');
      expect(json['downloadFilename'], 'hiking-club-loom-package.zip');
      expect(
        json['extensionManifestFilename'],
        'hiking-club.loom-extension.zip',
      );
      expect(
        json['initializationPackageFilename'],
        'hiking-club.loom-init.zip',
      );

      final manifest = json['extensionManifest'] as Map<String, dynamic>;
      expect(manifest['extensionId'], 'ext_hiking_club');
      expect(manifest['displayName'], 'Hiking Club');
      expect(manifest['specVersion'], currentCommunitySpecVersion);
      expect(manifest, isNot(contains('schemaVersion')));

      final initPackage = json['initializationPackage'] as Map<String, dynamic>;
      expect(initPackage['extensionId'], 'ext_hiking_club');
      expect(initPackage['communityId'], 'community_hiking_club');

      expect(json['downloadUrl'], isA<String>());
      expect(json['downloadUrl'], contains('/download/'));
    });

    test('downloadUrl from POST /package.json serves a real zip with both '
        'files', () async {
      final buildResponse = await post(
        '/package.json',
        jsonEncode(_hikeClubPackage),
      );
      final buildJson = await readJson(buildResponse);
      final downloadUrl = buildJson['downloadUrl'] as String;
      final downloadPath = Uri.parse(downloadUrl).path;

      final request = await client.getUrl(base.replace(path: downloadPath));
      final response = await request.close();

      expect(response.statusCode, HttpStatus.ok);
      expect(response.headers.contentType?.mimeType, 'application/zip');
      expect(
        response.headers.value('content-disposition'),
        contains('hiking-club-loom-package.zip'),
      );

      final bytes = await response.fold<BytesBuilder>(
        BytesBuilder(),
        (builder, chunk) => builder..add(chunk),
      );
      final archive = ZipDecoder().decodeBytes(bytes.toBytes());
      final names = archive.files.map((f) => f.name).toSet();
      expect(
        names,
        containsAll([
          'hiking-club.loom-extension.zip',
          'hiking-club.loom-init.zip',
        ]),
      );
    });

    test('GET /download/:id returns 404 for an unknown id', () async {
      final request = await client.getUrl(
        base.replace(path: '/download/does-not-exist'),
      );
      final response = await request.close();

      expect(response.statusCode, HttpStatus.notFound);
      final json = await readJson(response);
      expect(json['error'], 'download_not_found');
    });

    test(
      'POST /package.json refuses a package with validator errors (422)',
      () async {
        final broken = Map<String, dynamic>.from(_hikeClubPackage)
          ..remove('experience');

        final response = await post('/package.json', jsonEncode(broken));

        expect(response.statusCode, HttpStatus.unprocessableEntity);
        final json = await readJson(response);
        expect(json['error'], 'package_has_errors');
        final validation = json['validation'] as Map<String, dynamic>;
        expect(validation['errorCount'], greaterThan(0));
      },
    );

    test('POST /package.json refuses a validator-clean package missing fields '
        'the real installer requires (422)', () async {
      final missingExtensionId = Map<String, dynamic>.from(_hikeClubPackage)
        ..remove('extensionId');

      final response = await post(
        '/package.json',
        jsonEncode(missingExtensionId),
      );

      expect(response.statusCode, HttpStatus.unprocessableEntity);
      final json = await readJson(response);
      expect(json['error'], 'package_build_failed');
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
      expect(response.headers.value('access-control-allow-origin'), '*');
    });
  });
}

const _hikeClubPackage = {
  'specVersion': currentCommunitySpecVersion,
  'packageId': 'init_hiking_club_1',
  'communityId': 'community_hiking_club',
  'communityHandle': 'hiking-club',
  'displayName': 'Hiking Club',
  'extensionId': 'ext_hiking_club',
  'branding': {'accentColor': '#2D6A4F'},
  'seedDataFiles': <dynamic>[],
  'appShell': {
    'tabs': [
      {
        'tabId': 'calendar',
        'label': 'Calendar',
        'rendererContractId': 'engine-native-generic-list',
      },
    ],
  },
  'experience': {
    'displayName': 'Hiking Club',
    'tagline': 'Weekend trails.',
    'accentColor': '#2D6A4F',
    'roles': [
      {
        'roleId': 'hiking-organizer',
        'label': 'Organizer',
        'roleLabel': 'Organizer',
        'description': 'Plans hikes.',
      },
      {
        'roleId': 'hiking-member',
        'label': 'Member',
        'roleLabel': 'Member',
        'description': 'Joins hikes.',
      },
    ],
    'workflowDefinitions': {
      'hike-rsvp': {
        'initialState': 'open',
        'visibility': {'default': 'public'},
        'states': {
          'open': {
            'label': 'Signups open',
            'tone': 'positive',
            'editableFields': ['title', 'capacity'],
            'editGuard': {
              'allowedRoleIds': ['hiking-organizer'],
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
            'action': 'respond',
            'label': "I'm going",
            'tone': 'primary',
            'from': ['open'],
            'to': null,
            'guard': {
              'allowedRoleIds': ['hiking-member'],
              'actorInList': {'key': 'goingFanIds', 'present': false},
              'formula': 'size(goingFanIds) < capacity',
            },
            'effects': [
              {'op': 'appendUnique', 'key': 'goingFanIds', 'value': r'$actor'},
            ],
          },
          {
            'id': 'cancel-hike',
            'action': 'cancel',
            'label': 'Cancel hike',
            'tone': 'destructive',
            'from': ['open'],
            'to': 'cancelled',
            'guard': {
              'allowedRoleIds': ['hiking-organizer'],
            },
          },
        ],
        'renderBindings': [
          {
            'states': ['open'],
            'audience': 'any',
            'tabId': 'calendar',
            'cardSurfaceFamily': 'event-rsvp',
            'bindingKind': 'primary',
            'actions': [
              {
                'kind': 'create',
                'label': 'New hike',
                'byRoleIds': ['hiking-organizer'],
                'scope': 'tab',
                'presentation': 'fab',
              },
            ],
          },
          {
            'states': ['cancelled'],
            'audience': 'any',
            'tabId': 'calendar',
            'cardSurfaceFamily': 'event-rsvp',
            'bindingKind': 'summary',
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
          'goingFanIds': {'type': 'fanId[]', 'writableBy': 'effect'},
        },
      },
    },
    'workflowInstances': [
      {
        'instanceId': 'hike-eagle-ridge',
        'workflowType': 'hike-rsvp',
        'currentState': 'open',
        'createdByFanId': 'hiking-organizer',
        'instanceData': {'title': 'Eagle Ridge loop', 'capacity': 12},
      },
    ],
  },
};

const _noEditGuardOrCreatePackage = {
  'specVersion': currentCommunitySpecVersion,
  'packageId': 'init_no_gaps_1',
  'communityId': 'community_no_gaps',
  'communityHandle': 'no-gaps',
  'displayName': 'No Gaps',
  'extensionId': 'ext_no_gaps',
  'seedDataFiles': <dynamic>[],
  'experience': {
    'displayName': 'No Gaps',
    'roles': [
      {
        'roleId': 'organizer',
        'label': 'Organizer',
        'roleLabel': 'Organizer',
        'description': 'Manages things.',
      },
    ],
    'workflowDefinitions': {
      'thing': {
        'initialState': 'open',
        'visibility': {'default': 'public'},
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
        'renderBindings': [
          {
            'states': ['open'],
            'audience': 'any',
            'tabId': 'home',
            'cardSurfaceFamily': 'formEntry',
            'bindingKind': 'primary',
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
        'createdByFanId': 'organizer',
        'instanceData': {'title': 'Only ever this one'},
      },
    ],
  },
};
