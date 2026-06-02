import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart'
    show
        AnnouncementTemplateRecord,
        DemoLocalStore,
        LinkInBioPageRecord,
        RenderedAnnouncementRecord;

class CreatorAnnouncementFake implements CreatorAnnouncementApi {
  const CreatorAnnouncementFake(
    this._store, {
    this.latency = const Duration(milliseconds: 100),
  });

  final DemoLocalStore _store;
  final Duration latency;

  @override
  Future<List<AnnouncementTemplate>> listAnnouncementTemplates({
    required String channelId,
  }) async {
    await Future<void>.delayed(latency);
    return (await _store.announcementTemplates())
        .map(_mapTemplate)
        .toList(growable: false);
  }

  @override
  Future<RenderedAnnouncement> renderAnnouncement({
    required String channelId,
    required String templateId,
    required String captureLinkToken,
    required Map<String, String> fields,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    return _mapRendered(
      await _store.renderAnnouncement(
        channelId: channelId,
        templateId: templateId,
        captureLinkToken: captureLinkToken,
        fields: fields,
        idempotencyKey: idempotencyKey,
      ),
    );
  }

  @override
  Future<LinkInBioPage> getLinkInBio({required String channelId}) async {
    await Future<void>.delayed(latency);
    return _mapLinkInBio(await _store.linkInBioPage(channelId));
  }
}

AnnouncementTemplate _mapTemplate(AnnouncementTemplateRecord record) {
  return AnnouncementTemplate(
    templateId: record.templateId,
    name: record.name,
    channel: record.channel,
    body: record.body,
    placeholders: record.placeholders,
  );
}

RenderedAnnouncement _mapRendered(RenderedAnnouncementRecord record) {
  return RenderedAnnouncement(
    announcementId: record.announcementId,
    channelId: record.channelId,
    channel: record.channel,
    renderedBody: record.renderedBody,
    captureLinkUrl: record.captureLinkUrl,
    qrPayload: record.qrPayload,
    createdAt: record.createdAt,
  );
}

LinkInBioPage _mapLinkInBio(LinkInBioPageRecord record) {
  return LinkInBioPage(
    channelId: record.channelId,
    handle: record.handle,
    displayName: record.displayName,
    avatarRef: record.avatarRef,
    captureLinkUrl: record.captureLinkUrl,
    qrPayload: record.qrPayload,
    externalLinks: record.externalLinks
        .map(
          (link) =>
              LinkInBioLink(label: link['label'] ?? '', url: link['url'] ?? ''),
        )
        .toList(growable: false),
  );
}
