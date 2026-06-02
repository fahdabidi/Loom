import '../models/launch/launch_models.dart';

abstract class StarterPackApi {
  Future<StarterPack> getStarterPack({
    required String channelId,
    required String passportId,
    int limit = 6,
  });

  Future<StarterPack> putStarterPack({
    required String channelId,
    required String passportId,
    required List<String> memberChannelIds,
    required List<String> defaultSelectedChannelIds,
    required String idempotencyKey,
  });

  Future<BulkFollowResult> bulkFollow({
    required String channelId,
    required String passportId,
    required List<String> channelIds,
    required String followVisibility,
    required String idempotencyKey,
  });
}
