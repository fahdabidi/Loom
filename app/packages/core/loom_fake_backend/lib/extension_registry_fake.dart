import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart'
    show DemoLocalStore, ExtensionInstallRecord, ExtensionManifestRecord;

class ExtensionRegistryFake implements ExtensionRegistryApi {
  const ExtensionRegistryFake(
    this._store, {
    this.latency = const Duration(milliseconds: 90),
  });

  final DemoLocalStore _store;
  final Duration latency;

  @override
  Future<List<ExtensionManifest>> listExtensions({
    String? category,
    bool certifiedOnly = true,
  }) async {
    await Future<void>.delayed(latency);
    final records = await _store.extensionManifests(
      category: category,
      certifiedOnly: certifiedOnly,
    );
    return records.map(_mapManifest).toList(growable: false);
  }

  @override
  Future<ExtensionManifest> getExtension({required String extensionId}) async {
    await Future<void>.delayed(latency);
    final record = await _store.extensionManifest(extensionId);
    if (record == null) {
      throw StateError('Extension $extensionId was not found.');
    }
    return _mapManifest(record);
  }

  @override
  Future<ExtensionManifest> publishExtension({
    required ExtensionManifest manifest,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    return _mapManifest(
      await _store.publishExtension(
        manifest: _toManifestRecord(manifest),
        idempotencyKey: idempotencyKey,
      ),
    );
  }

  @override
  Future<ExtensionInstall> installExtension({
    required String channelId,
    required String extensionId,
    required String version,
    required List<String> approvedPermissions,
    required List<String> approvedSurfaces,
    required Map<String, String> config,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    return _mapInstall(
      await _store.installExtension(
        channelId: channelId,
        extensionId: extensionId,
        version: version,
        approvedPermissions: approvedPermissions,
        approvedSurfaces: approvedSurfaces,
        config: config,
        idempotencyKey: idempotencyKey,
      ),
    );
  }

  @override
  Future<ExtensionInstall> suspendExtension({
    required String channelId,
    required String extensionId,
    required String reason,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    return _mapInstall(
      await _store.suspendExtension(
        channelId: channelId,
        extensionId: extensionId,
        reason: reason,
        idempotencyKey: idempotencyKey,
      ),
    );
  }
}

ExtensionManifest _mapManifest(ExtensionManifestRecord record) {
  return ExtensionManifest(
    extensionId: record.extensionId,
    name: record.name,
    category: record.category,
    riskTier: record.riskTier,
    surfaces: record.surfaces,
    permissions: record.permissions,
    exportBehavior: record.exportBehavior,
    certificationState: record.certificationState,
    latestVersion: record.latestVersion,
    description: record.description,
  );
}

ExtensionManifestRecord _toManifestRecord(ExtensionManifest manifest) {
  return ExtensionManifestRecord(
    extensionId: manifest.extensionId,
    name: manifest.name,
    category: manifest.category,
    riskTier: manifest.riskTier,
    surfaces: manifest.surfaces,
    permissions: manifest.permissions,
    exportBehavior: manifest.exportBehavior,
    certificationState: manifest.certificationState,
    latestVersion: manifest.latestVersion,
    description: manifest.description,
  );
}

ExtensionInstall _mapInstall(ExtensionInstallRecord record) {
  return ExtensionInstall(
    installId: record.installId,
    channelId: record.channelId,
    extensionId: record.extensionId,
    version: record.version,
    approvedPermissions: record.approvedPermissions,
    approvedSurfaces: record.approvedSurfaces,
    config: record.config,
    state: record.state,
    installedAt: record.installedAt,
    updatedAt: record.updatedAt,
  );
}
