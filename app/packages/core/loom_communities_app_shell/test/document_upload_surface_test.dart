import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
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
  setUp(resetLoomDocumentPickerForTesting);
  tearDown(resetLoomDocumentPickerForTesting);

  group('storedDocumentFieldName', () {
    test('finds the platform-written url field', () {
      final machine = _machine({
        'title': {'type': 'text', 'writableBy': 'formEntry'},
        'documentUrl': {'type': 'url', 'writableBy': 'effect'},
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

    test('ignores a non-url field the platform writes', () {
      final machine = _machine({
        'publishedAt': {'type': 'date?', 'writableBy': 'effect'},
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
        'documentUrl': {'type': 'url?', 'writableBy': 'effect'},
      });
      expect(storedDocumentFieldName(machine), 'documentUrl');
    });
  });

  group('upload blockers', () {
    test('a local engine cannot upload, and says so', () {
      final machine = _machine({
        'documentUrl': {'type': 'url', 'writableBy': 'effect'},
      });
      final blocker = loomDocumentUploadBlocker(
        engine: _LocalOnlyEngine(),
        machine: machine,
      );
      // The member is told why rather than left tapping a dead button.
      expect(blocker, isNotNull);
      expect(blocker, contains('local engine'));
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
