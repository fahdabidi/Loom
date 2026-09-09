import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:loom_auth_session/loom_auth_session.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

/// The pieces the Upload button depends on, tested where they can be.
///
/// The card itself needs a live remote engine and a configured backend, which a
/// widget test has neither of. What it can pin is the decision logic that sits
/// in front of the network call — which field a stored document fills, and why
/// an upload is refused — because that is where a wrong answer silently
/// uploads into the wrong field or hides the button for the wrong reason.
void main() {
  setUp(() {
    resetLoomDocumentPickerForTesting();
    resetLoomDocumentClientForTesting();
  });
  tearDown(() {
    resetLoomDocumentPickerForTesting();
    resetLoomDocumentClientForTesting();
  });

  group('storedDocumentFieldName', () {
    test('finds the platform-written url field', () {
      final machine = _machine({
        'title': {'type': 'text', 'writableBy': 'formEntry'},
        'documentUrl': {'type': 'url', 'writableBy': 'platform'},
      });
      expect(storedDocumentFieldName(machine), 'documentUrl');
    });

    test('ignores a url field the member types into', () {
      // This is the link library every other community ships. Treating it as a
      // stored field would offer an upload that overwrites what a member typed.
      final machine = _machine({
        'materialUrl': {'type': 'url', 'writableBy': 'formEntry'},
      });
      expect(storedDocumentFieldName(machine), isNull);
    });

    test('ignores an effect-written url, which is a link not an upload', () {
      // `effect` means a JSON effect fills it, which no upload does. Only
      // `platform` marks a field the Document Library API writes.
      final machine = _machine({
        'documentUrl': {'type': 'url', 'writableBy': 'effect'},
      });
      expect(storedDocumentFieldName(machine), isNull);
    });

    test('ignores a non-url field the platform writes', () {
      final machine = _machine({
        'publishedAt': {'type': 'date?', 'writableBy': 'platform'},
      });
      expect(storedDocumentFieldName(machine), isNull);
    });

    test('is not fooled by a field named like a document', () {
      // Matching on the identifier's spelling rather than its declaration is a
      // mistake this project has made before.
      final machine = _machine({
        'documentUrl': {'type': 'text', 'writableBy': 'formEntry'},
      });
      expect(storedDocumentFieldName(machine), isNull);
    });

    test('accepts the nullable url spelling', () {
      final machine = _machine({
        'documentUrl': {'type': 'url?', 'writableBy': 'platform'},
      });
      expect(storedDocumentFieldName(machine), 'documentUrl');
    });

    test('refuses to pick between multiple platform-owned document fields', () {
      final machine = _machine({
        'policyUrl': {'type': 'url', 'writableBy': 'platform'},
        'minutesUrl': {'type': 'url?', 'writableBy': 'platform'},
      });

      expect(storedDocumentFieldNames(machine), <String>[
        'policyUrl',
        'minutesUrl',
      ]);
      expect(storedDocumentFieldName(machine), isNull);
    });
  });

  group('upload blockers', () {
    test('a local engine cannot upload, and says so', () {
      final machine = _machine({
        'documentUrl': {'type': 'url', 'writableBy': 'platform'},
      });
      final blocker = loomDocumentUploadBlocker(
        engine: _LocalOnlyEngine(),
        machine: machine,
      );
      // The member is told why rather than left tapping a dead button.
      expect(
        blocker,
        'Uploading needs a connected community. This build is running on the '
        'local engine.',
      );
    });

    test('a replica-wrapped remote engine can upload one stored document', () {
      overrideLoomDocumentClientForTesting(_documentClient());
      final blocker = loomDocumentUploadBlocker(
        engine: _wrappedRemoteEngine(),
        machine: _machine({
          'documentUrl': {'type': 'url', 'writableBy': 'platform'},
        }),
      );

      expect(blocker, isNull);
    });

    test('a replica-wrapped remote engine still needs document storage', () {
      final blocker = loomDocumentUploadBlocker(
        engine: _wrappedRemoteEngine(),
        machine: _machine({
          'documentUrl': {'type': 'url', 'writableBy': 'platform'},
        }),
      );

      expect(blocker, 'This community has no document storage configured.');
    });

    test('a replica-wrapped remote engine still rejects ambiguous fields', () {
      overrideLoomDocumentClientForTesting(_documentClient());
      final blocker = loomDocumentUploadBlocker(
        engine: _wrappedRemoteEngine(),
        machine: _machine({
          'policyUrl': {'type': 'url', 'writableBy': 'platform'},
          'minutesUrl': {'type': 'url?', 'writableBy': 'platform'},
        }),
      );

      expect(
        blocker,
        'This document library declares multiple stored document fields. '
        'It cannot choose a document safely.',
      );
    });
  });

  group('the picker', () {
    test('is replaceable, and cancelling yields null', () async {
      overrideLoomDocumentPickerForTesting(() async => null);
      expect(await loomDocumentPicker(), isNull);

      overrideLoomDocumentPickerForTesting(
        () async => LoomPickedDocument(
          filename: 'ccrs-2025.pdf',
          bytes: Uint8List.fromList(utf8.encode('%PDF-1.7')),
          contentType: 'application/pdf',
        ),
      );
      final picked = await loomDocumentPicker();
      expect(picked, isNotNull);
      expect(picked!.filename, 'ccrs-2025.pdf');
      expect(picked.contentType, 'application/pdf');
    });

    test('resets to the device picker between tests', () {
      overrideLoomDocumentPickerForTesting(() async => null);
      resetLoomDocumentPickerForTesting();
      // Identity, not behaviour: calling it here would open a real dialog.
      expect(loomDocumentPicker, same(pickLoomDocumentFromDevice));
    });
  });

  test('a local build resolves no document client', () {
    // Null is the ordinary answer without a backend, not a failure. An
    // in-memory engine has nowhere to put bytes.
    expect(resolveLoomDocumentClient(), isNull);
  });
}

LoomWorkflowStateMachine _machine(Map<String, Map<String, dynamic>> schema) =>
    LoomWorkflowStateMachine.fromJson({
      'initialState': 'draft',
      'states': {
        'draft': {'label': 'Draft'},
      },
      'transitions': <Map<String, dynamic>>[],
      'instanceDataSchema': schema,
    }, 'doc-library');

/// Stands in for an engine that is not the remote one.
class _LocalOnlyEngine implements WorkflowEngineApi {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not used here');
}

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
        clientId: 'document-upload-test',
        secureStorage: _MemoryStorage(),
      );

  @override
  Future<String> currentAccessToken() async => 'document-upload-test-token';
}

http.Client _unreachableHttpClient() => MockClient(
  (_) async => throw StateError('The upload blocker must not make a request.'),
);

LoomDocumentClient _documentClient() => LoomDocumentClient(
  workflowServiceBaseUri: Uri.parse('https://workflow.test/api/'),
  session: _TestSession(),
  httpClient: _unreachableHttpClient(),
);

LoomReplicaFallbackWorkflowEngineApi _wrappedRemoteEngine() {
  final coordinator = LoomWorkflowReplicaCoordinator(
    databaseDirectory: Directory.systemTemp.path,
    visibleChangesClient: LoomVisibleChangesClient(
      workflowServiceBaseUri: Uri.parse('https://workflow.test/api/'),
      session: _TestSession(),
      httpClient: _unreachableHttpClient(),
    ),
  );
  return coordinator.wrap(
    RemoteWorkflowEngineApi(
      baseUri: Uri.parse('https://workflow.test/api/'),
      communityId: 'document-upload-test-community',
      bearerTokenProvider: () async => 'document-upload-test-token',
      httpClient: _unreachableHttpClient(),
    ),
    communityId: 'document-upload-test-extension',
  );
}
