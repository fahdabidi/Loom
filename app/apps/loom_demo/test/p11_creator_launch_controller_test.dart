import 'package:feature_creator_launch/feature_creator_launch.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';

void main() {
  test(
    'p11 controller renders launch assets and simulates cross-post',
    () async {
      final controller = CreatorLaunchController(
        creatorId: 'creator_solar_sarah',
        metadataApi: _MetadataApi(),
        announcementApi: _AnnouncementApi(),
        captureApi: _CaptureApi(),
        externalAccountApi: _ExternalAccountApi(),
        crossPostingApi: _CrossPostingApi(),
      );

      await controller.load();
      expect(controller.loading, isFalse);
      expect(controller.templates, isNotEmpty);
      expect(controller.selectedTemplateId, 'launch_social_post');

      await controller.generateAssets();
      expect(controller.captureLink?.url, contains('/c/cap_launch'));
      expect(controller.renderedAnnouncement?.renderedBody, contains('Loom'));

      await controller.simulateCrossPost();
      expect(controller.crossPost?.targets.single.deliveryStatus, 'complete');
    },
  );
}

class _MetadataApi extends Fake implements CreatorMetadataApi {
  @override
  Future<ChannelHome> getChannelHome({
    required String channelId,
    required String passportId,
  }) async {
    return const ChannelHome(
      creatorId: 'creator_solar_sarah',
      displayName: 'Solar Sarah',
      handle: 'solar-sarah',
      vertical: 'home-energy',
      avatarRef: 'seed://avatars/solar-sarah',
      isFollowed: false,
      isBlocked: false,
      visibilityLabel: 'Creator visible',
      content: [],
      adPolicy: null,
    );
  }
}

class _AnnouncementApi extends Fake implements CreatorAnnouncementApi {
  @override
  Future<List<AnnouncementTemplate>> listAnnouncementTemplates({
    required String channelId,
  }) async {
    return const [
      AnnouncementTemplate(
        templateId: 'launch_social_post',
        name: 'Social launch post',
        channel: 'social_post',
        body: 'Follow me on Loom: {captureLink}',
        placeholders: ['captureLink'],
      ),
    ];
  }

  @override
  Future<LinkInBioPage> getLinkInBio({required String channelId}) async {
    return const LinkInBioPage(
      channelId: 'creator_solar_sarah',
      handle: 'solar-sarah',
      displayName: 'Solar Sarah',
      avatarRef: 'seed://avatars/solar-sarah',
      captureLinkUrl: 'https://loom.example/c/cap_seed',
      qrPayload: 'loom://capture/cap_seed',
      externalLinks: [
        LinkInBioLink(
          label: 'Creator-owned Loom hub',
          url: 'https://loom.example/c/cap_seed',
        ),
      ],
    );
  }

  @override
  Future<RenderedAnnouncement> renderAnnouncement({
    required String channelId,
    required String templateId,
    required String captureLinkToken,
    required Map<String, String> fields,
    required String idempotencyKey,
  }) async {
    return RenderedAnnouncement(
      announcementId: 'ann_launch',
      channelId: 'creator_solar_sarah',
      channel: 'social_post',
      renderedBody: 'Follow me on Loom: https://loom.example/c/cap_launch',
      captureLinkUrl: 'https://loom.example/c/cap_launch',
      qrPayload: 'loom://capture/cap_launch',
      createdAt: DateTime(2026, 6, 2),
    );
  }
}

class _CaptureApi extends Fake implements FanFollowCaptureApi {
  @override
  Future<CaptureLink> createCaptureLink({
    required String channelId,
    required String channel,
    required bool starterPackEnabled,
    DateTime? expiresAt,
    required String idempotencyKey,
  }) async {
    return CaptureLink(
      token: 'cap_launch',
      channelId: 'creator_solar_sarah',
      url: 'https://loom.example/c/cap_launch',
      channel: 'social_post',
      qrPayload: 'loom://capture/cap_launch',
      starterPackEnabled: true,
      createdAt: DateTime(2026, 6, 2),
    );
  }
}

class _ExternalAccountApi extends Fake implements ExternalAccountLinkApi {
  @override
  Future<List<ExternalAccountLink>> listExternalAccounts({
    required String channelId,
  }) async {
    return [
      ExternalAccountLink(
        linkId: 'ext_youtube',
        channelId: 'creator_solar_sarah',
        platform: 'youtube',
        handle: '@solar-sarah',
        verificationState: 'verified',
        linkedAt: DateTime(2026, 6, 2),
      ),
    ];
  }
}

class _CrossPostingApi extends Fake implements CrossPostingApi {
  @override
  Future<CrossPost> createCrossPost({
    required String channelId,
    required List<String> targetLinkIds,
    required String message,
    String? announcementId,
    String? contentRef,
    String? captureLinkUrl,
    required String idempotencyKey,
  }) async {
    return CrossPost(
      crossPostId: 'cross_launch',
      channelId: 'creator_solar_sarah',
      message: 'Follow me on Loom',
      createdAt: DateTime(2026, 6, 2),
      targets: const [
        CrossPostTarget(
          targetLinkId: 'ext_youtube',
          platform: 'youtube',
          deliveryStatus: 'processing',
        ),
      ],
    );
  }

  @override
  Future<CrossPost> getCrossPost({
    required String channelId,
    required String crossPostId,
  }) async {
    return CrossPost(
      crossPostId: 'cross_launch',
      channelId: 'creator_solar_sarah',
      message: 'Follow me on Loom',
      createdAt: DateTime(2026, 6, 2),
      targets: const [
        CrossPostTarget(
          targetLinkId: 'ext_youtube',
          platform: 'youtube',
          deliveryStatus: 'complete',
        ),
      ],
    );
  }
}
