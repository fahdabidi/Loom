part of '../loom_communities_app_shell.dart';

/// A file the member chose to upload.
final class LoomPickedDocument {
  const LoomPickedDocument({
    required this.filename,
    required this.bytes,
    this.contentType = 'application/octet-stream',
  });

  final String filename;
  final Uint8List bytes;
  final String contentType;
}

/// Asks the member for a file, or returns null if they backed out.
///
/// Injected rather than called directly so a widget test can supply bytes
/// without a platform channel. A test that had to open a real file dialog
/// would be a test nobody runs.
typedef LoomDocumentPicker = Future<LoomPickedDocument?> Function();

LoomDocumentPicker _loomDocumentPicker = pickLoomDocumentFromDevice;

/// The picker the document surfaces use.
LoomDocumentPicker get loomDocumentPicker => _loomDocumentPicker;

/// Replaces the picker, for a host app that wants its own file chooser.
void configureLoomDocumentPicker(LoomDocumentPicker picker) {
  _loomDocumentPicker = picker;
}

@visibleForTesting
void overrideLoomDocumentPickerForTesting(LoomDocumentPicker picker) {
  _loomDocumentPicker = picker;
}

@visibleForTesting
void resetLoomDocumentPickerForTesting() {
  _loomDocumentPicker = pickLoomDocumentFromDevice;
}

/// The default picker: the device's own file chooser.
Future<LoomPickedDocument?> pickLoomDocumentFromDevice() async {
  final file = await FilePicker.pickFile();
  // Cancelling is null, and is not an error.
  if (file == null) return null;
  // Bytes now, rather than a path kept for later. On Android the picker hands
  // back a content:// URI whose permission does not outlive this activity, so a
  // path stored and reopened afterwards would fail intermittently and only on
  // device.
  return LoomPickedDocument(
    filename: file.name,
    bytes: await file.readAsBytes(),
    contentType: _contentTypeForExtension(file.extension),
  );
}

/// The document client for this build, or null when there is no backend.
///
/// Null is the ordinary answer for a local build, not a failure. The document
/// library stores bytes in a real service; an in-memory engine has nowhere to
/// put them, and pretending otherwise is the kind of fake this migration exists
/// to remove.
LoomDocumentClient? _documentClientOverrideForTesting;

LoomDocumentClient? resolveLoomDocumentClient() {
  final override = _documentClientOverrideForTesting;
  if (override != null) return override;
  final configuration = loomRemoteServiceConfiguration;
  if (configuration == null) return null;
  return LoomDocumentClient(
    workflowServiceBaseUri: configuration.workflowServiceBaseUri,
    session: configuration.session,
  );
}

@visibleForTesting
void overrideLoomDocumentClientForTesting(LoomDocumentClient? client) {
  _documentClientOverrideForTesting = client;
}

@visibleForTesting
void resetLoomDocumentClientForTesting() {
  _documentClientOverrideForTesting = null;
}

/// The instance field a stored document fills, or null for a link library.
///
/// Derived structurally, exactly as `document-library.md` §3a defines a stored
/// library: a `url` field the platform writes and a member cannot type into.
/// Not matched by name — `documentUrl` is what Cedar happens to call it, and
/// reading meaning from an identifier's spelling is a mistake this project has
/// made before.
List<String> storedDocumentFieldNames(LoomWorkflowStateMachine machine) {
  final fields = <String>[];
  for (final entry in machine.instanceDataSchema.entries) {
    final field = entry.value;
    final type = field.type;
    if ((type == 'url' || type == 'url?') && field.writableBy == 'platform')
      fields.add(entry.key);
  }
  return List.unmodifiable(fields);
}

String? storedDocumentFieldName(LoomWorkflowStateMachine machine) {
  final fields = storedDocumentFieldNames(machine);
  return fields.length == 1 ? fields.single : null;
}

/// Why an upload could not start. Null means it can.
///
/// Returned rather than thrown so the caller can put the reason on screen. A
/// member who taps Upload and sees nothing happen learns less than one who is
/// told the community has no document storage configured.
String? loomDocumentUploadBlocker({
  required WorkflowEngineApi engine,
  required LoomWorkflowStateMachine machine,
}) {
  if (engine is! RemoteWorkflowEngineApi) {
    return 'Uploading needs a connected community. This build is running on '
        'the local engine.';
  }
  if (resolveLoomDocumentClient() == null) {
    return 'This community has no document storage configured.';
  }
  final storedFields = storedDocumentFieldNames(machine);
  if (storedFields.length > 1) {
    return 'This document library declares multiple stored document fields. '
        'It cannot choose a document safely.';
  }
  if (storedFields.isEmpty) {
    return 'This document library holds links rather than stored files.';
  }
  return null;
}

String _contentTypeForExtension(String? extension) {
  switch (extension?.toLowerCase()) {
    case 'pdf':
      return 'application/pdf';
    case 'png':
      return 'image/png';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'gif':
      return 'image/gif';
    case 'txt':
      return 'text/plain';
    case 'csv':
      return 'text/csv';
    case 'doc':
      return 'application/msword';
    case 'docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    case 'xls':
      return 'application/vnd.ms-excel';
    case 'xlsx':
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    default:
      // Deliberately not guessed from the bytes. The service stores whatever it
      // is told and always serves it as an attachment, so a wrong guess costs a
      // less helpful label rather than an execution risk.
      return 'application/octet-stream';
  }
}
