import '../models/extensions/extension_models.dart';

abstract class ExtensionRuntimeApi {
  Future<ExtensionSession> createExtensionSession({
    required String channelId,
    required String extensionId,
    required String surface,
    required String fanId,
    required String idempotencyKey,
    String? version,
    String? pairwiseCreatorFanId,
  });

  Future<ExtensionEvent> submitExtensionEvent({
    required String sessionId,
    required String type,
    required Map<String, String> payload,
    required String idempotencyKey,
  });

  Future<ExtensionStateExport> createExtensionStateExport({
    required String channelId,
    String? fanId,
  });
}
