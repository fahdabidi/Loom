import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart'
    show
        DemoLocalStore,
        ExtensionEventRecord,
        ExtensionSessionRecord,
        ExtensionStateExportRecord,
        ExtensionStateRecord;

class ExtensionRuntimeFake implements ExtensionRuntimeApi {
  const ExtensionRuntimeFake(
    this._store, {
    this.latency = const Duration(milliseconds: 90),
  });

  final DemoLocalStore _store;
  final Duration latency;

  @override
  Future<ExtensionSession> createExtensionSession({
    required String channelId,
    required String extensionId,
    required String surface,
    required String fanId,
    required String idempotencyKey,
    String? version,
    String? pairwiseCreatorFanId,
  }) async {
    await Future<void>.delayed(latency);
    return _mapSession(
      await _store.createExtensionSession(
        channelId: channelId,
        extensionId: extensionId,
        surface: surface,
        fanId: fanId,
        idempotencyKey: idempotencyKey,
        version: version,
        pairwiseCreatorFanId: pairwiseCreatorFanId,
      ),
    );
  }

  @override
  Future<ExtensionEvent> submitExtensionEvent({
    required String sessionId,
    required String type,
    required Map<String, String> payload,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    return _mapEvent(
      await _store.submitExtensionEvent(
        sessionId: sessionId,
        type: type,
        payload: payload,
        idempotencyKey: idempotencyKey,
      ),
    );
  }

  @override
  Future<ExtensionStateExport> createExtensionStateExport({
    required String channelId,
    String? fanId,
  }) async {
    await Future<void>.delayed(latency);
    return _mapExport(
      await _store.createExtensionStateExport(
        channelId: channelId,
        fanId: fanId,
      ),
    );
  }
}

ExtensionSession _mapSession(ExtensionSessionRecord record) {
  return ExtensionSession(
    sessionId: record.sessionId,
    channelId: record.channelId,
    extensionId: record.extensionId,
    version: record.version,
    surface: record.surface,
    fanId: record.fanId,
    pairwiseCreatorFanId: record.pairwiseCreatorFanId,
    state: record.state,
    allowedPermissions: record.allowedPermissions,
    createdAt: record.createdAt,
  );
}

ExtensionEvent _mapEvent(ExtensionEventRecord record) {
  return ExtensionEvent(
    eventId: record.eventId,
    sessionId: record.sessionId,
    type: record.type,
    payload: record.payload,
    createdAt: record.createdAt,
    idempotencyKey: record.idempotencyKey,
  );
}

ExtensionStateExport _mapExport(ExtensionStateExportRecord record) {
  return ExtensionStateExport(
    exportId: record.exportId,
    channelId: record.channelId,
    fanId: record.fanId,
    generatedAt: record.generatedAt,
    entries: record.entries.map(_mapState).toList(growable: false),
  );
}

ExtensionStateEntry _mapState(ExtensionStateRecord record) {
  return ExtensionStateEntry(
    scopeKey: record.scopeKey,
    key: record.key,
    value: record.value,
    exportBehavior: record.exportBehavior,
    updatedAt: record.updatedAt,
  );
}
