import '../models/creator_channel/creator_channel.dart';

abstract class CreatorChannelRegistryApi {
  Future<CreatorChannel> createChannel({
    required String ownerPassportId,
    required String displayName,
    required String vertical,
    required String idempotencyKey,
  });

  Future<CreatorChannel> bindHandle({
    required String channelId,
    required String handle,
    required String idempotencyKey,
  });

  Future<CreatorChannel?> getChannel(String channelId);
}
