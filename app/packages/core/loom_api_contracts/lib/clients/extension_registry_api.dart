import '../models/extensions/extension_models.dart';

abstract class ExtensionRegistryApi {
  Future<List<ExtensionManifest>> listExtensions({
    String? category,
    bool certifiedOnly = true,
  });

  Future<ExtensionManifest> getExtension({required String extensionId});

  Future<ExtensionManifest> publishExtension({
    required ExtensionManifest manifest,
    required String idempotencyKey,
  });

  Future<ExtensionInstall> installExtension({
    required String channelId,
    required String extensionId,
    required String version,
    required List<String> approvedPermissions,
    required List<String> approvedSurfaces,
    required Map<String, String> config,
    required String idempotencyKey,
  });

  Future<ExtensionInstall> suspendExtension({
    required String channelId,
    required String extensionId,
    required String reason,
    required String idempotencyKey,
  });
}
