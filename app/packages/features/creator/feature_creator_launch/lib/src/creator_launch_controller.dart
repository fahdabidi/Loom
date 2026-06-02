import 'package:flutter/foundation.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';

class CreatorLaunchController extends ChangeNotifier {
  CreatorLaunchController({
    required this.creatorId,
    required CreatorMetadataApi metadataApi,
    required CreatorAnnouncementApi announcementApi,
    required FanFollowCaptureApi captureApi,
    required ExternalAccountLinkApi externalAccountApi,
    required CrossPostingApi crossPostingApi,
  }) : _metadataApi = metadataApi,
       _announcementApi = announcementApi,
       _captureApi = captureApi,
       _externalAccountApi = externalAccountApi,
       _crossPostingApi = crossPostingApi;

  final String creatorId;
  final CreatorMetadataApi _metadataApi;
  final CreatorAnnouncementApi _announcementApi;
  final FanFollowCaptureApi _captureApi;
  final ExternalAccountLinkApi _externalAccountApi;
  final CrossPostingApi _crossPostingApi;

  ChannelHome? channelHome;
  LinkInBioPage? linkInBio;
  CaptureLink? captureLink;
  RenderedAnnouncement? renderedAnnouncement;
  CrossPost? crossPost;
  List<AnnouncementTemplate> templates = const [];
  List<ExternalAccountLink> externalAccounts = const [];
  String? selectedTemplateId;
  String? errorMessage;
  bool loading = true;
  bool busy = false;

  Future<void> load() async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait<Object>([
        _metadataApi.getChannelHome(
          channelId: creatorId,
          passportId: 'passport_demo_fan',
        ),
        _announcementApi.listAnnouncementTemplates(channelId: creatorId),
        _announcementApi.getLinkInBio(channelId: creatorId),
        _externalAccountApi.listExternalAccounts(channelId: creatorId),
      ]);
      channelHome = results[0] as ChannelHome;
      templates = results[1] as List<AnnouncementTemplate>;
      linkInBio = results[2] as LinkInBioPage;
      externalAccounts = results[3] as List<ExternalAccountLink>;
      selectedTemplateId ??= templates.isEmpty
          ? null
          : templates.first.templateId;
    } catch (error) {
      errorMessage = '$error';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void selectTemplate(String templateId) {
    selectedTemplateId = templateId;
    notifyListeners();
  }

  Future<void> generateAssets() async {
    final templateId = selectedTemplateId;
    if (templateId == null || busy) {
      return;
    }
    await _runBusy(() async {
      captureLink = await _captureApi.createCaptureLink(
        channelId: creatorId,
        channel: 'social_post',
        starterPackEnabled: true,
        idempotencyKey: 'p11-capture-$creatorId-$templateId',
      );
      renderedAnnouncement = await _announcementApi.renderAnnouncement(
        channelId: creatorId,
        templateId: templateId,
        captureLinkToken: captureLink!.token,
        fields: const {},
        idempotencyKey: 'p11-render-$creatorId-$templateId',
      );
      linkInBio = await _announcementApi.getLinkInBio(channelId: creatorId);
    });
  }

  Future<void> simulateCrossPost() async {
    final announcement = renderedAnnouncement;
    final link = captureLink;
    final targets = externalAccounts
        .where((account) => account.verificationState == 'verified')
        .map((account) => account.linkId)
        .toList(growable: false);
    if (announcement == null || link == null || targets.isEmpty || busy) {
      return;
    }
    await _runBusy(() async {
      final created = await _crossPostingApi.createCrossPost(
        channelId: creatorId,
        targetLinkIds: targets.take(2).toList(growable: false),
        message: announcement.renderedBody,
        announcementId: announcement.announcementId,
        captureLinkUrl: link.url,
        idempotencyKey:
            'p11-cross-post-$creatorId-${announcement.announcementId}',
      );
      crossPost = await _crossPostingApi.getCrossPost(
        channelId: creatorId,
        crossPostId: created.crossPostId,
      );
    });
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      errorMessage = '$error';
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
