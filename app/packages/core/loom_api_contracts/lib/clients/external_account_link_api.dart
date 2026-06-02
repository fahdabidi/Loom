import '../models/launch/launch_models.dart';

abstract class ExternalAccountLinkApi {
  Future<List<ExternalAccountLink>> listExternalAccounts({
    required String channelId,
  });

  Future<ExternalAccountLink> linkExternalAccount({
    required String channelId,
    required String platform,
    required String handle,
    String? profileUrl,
    required String idempotencyKey,
  });

  Future<ExternalAccountLink> verifyExternalAccount({
    required String channelId,
    required String linkId,
    required String method,
    String? evidence,
    required String idempotencyKey,
  });

  Future<void> unlinkExternalAccount({
    required String channelId,
    required String linkId,
  });
}
