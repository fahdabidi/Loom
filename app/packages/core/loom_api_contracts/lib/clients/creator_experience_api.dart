import '../models/extensions/extension_models.dart';

abstract class CreatorExperienceApi {
  Future<CreatorExperienceConfig> getExperienceConfig({
    required String channelId,
  });

  Future<CreatorExperienceConfig> putExperienceConfig({
    required CreatorExperienceConfig config,
    required String idempotencyKey,
  });
}
