import '../models/launch/launch_models.dart';

abstract class CreatorAnnouncementApi {
  Future<List<AnnouncementTemplate>> listAnnouncementTemplates({
    required String channelId,
  });

  Future<RenderedAnnouncement> renderAnnouncement({
    required String channelId,
    required String templateId,
    required String captureLinkToken,
    required Map<String, String> fields,
    required String idempotencyKey,
  });

  Future<LinkInBioPage> getLinkInBio({required String channelId});
}
