import 'package:feature_creator_customize/feature_creator_customize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo/main.dart';
import 'package:loom_local_store/loom_local_store.dart';

void main() {
  late DemoLocalStore store;

  setUp(() async {
    resetAppShellDependencies();
    store = await configureDemoDependencies(persistent: false);
  });

  tearDown(() async {
    await store.close();
    resetAppShellDependencies();
  });

  test('p25 creator links external content through typed fake APIs', () async {
    final controller = _controller('creator_nova_clutch');
    await controller.load();

    await controller.resolveExternalLink(
      input: 'NovaClutch VOD',
      creatorNote: 'Creator-picked companion video.',
    );
    expect(controller.externalPreview, isNotNull);
    expect(controller.externalPreview!.sourceAttribution, 'YouTube');

    await controller.linkExternalContent(
      input: 'NovaClutch VOD',
      creatorNote: 'Creator-picked companion video.',
    );
    final persisted = await resolveCreatorExperienceApi().getExperienceConfig(
      channelId: 'creator_nova_clutch',
    );
    final module = persisted.surfaceModules.singleWhere(
      (candidate) =>
          candidate.kind == 'external_content' &&
          candidate.config['creatorNote'] == 'Creator-picked companion video.',
    );
    expect(module.config['sourceAttribution'], 'YouTube');
    expect(module.config['originalTitle'], contains('NovaClutch'));
    expect(module.config['creatorNote'], 'Creator-picked companion video.');
    expect(module.config['searchIndexable'], 'true');
    expect(module.config['aiQueryable'], 'true');

    final linked = await resolveExternalContentSourceApi().getExternalContent(
      referenceId: module.config['referenceId']!,
    );
    expect(linked.creatorNote, 'Creator-picked companion video.');

    await _connectAiSearch();
    final result = await resolveAiGatewayApi().runAiSearch(
      passportId: 'passport_demo_fan',
      query: 'NovaClutch',
      limit: 10,
    );
    expect(
      result.items
          .where((item) => item.type == AiSearchItemType.external)
          .map((item) => item.id),
      contains(module.config['referenceId']),
    );
  });

  test('p25 linked external candidate maps to playback item shape', () async {
    final controller = _controller('creator_nova_clutch');
    await controller.load();
    await controller.linkExternalContent(
      input: 'NovaClutch VOD',
      creatorNote: 'Creator-picked companion video.',
    );
    final linked = await resolveExternalContentSourceApi().getExternalContent(
      referenceId: controller.externalPreview!.targetRef.referenceId,
    );

    AiSearchItem? opened;
    final playbackItem = AiSearchItem(
      id: linked.targetRef.referenceId,
      type: AiSearchItemType.external,
      originalTitle: linked.originalTitle,
      summary: linked.summary,
      thumbnailRef: linked.thumbnailRef,
      rankReason: 'Creator-linked public reference.',
      titleRiskSignals: const [],
      sourceAttribution: linked.sourceAttribution,
      score: 1,
      externalTargetRef: linked.targetRef,
      embedDescriptor: linked.embedDescriptor,
      accurateMatchLabel: linked.accurateMatchLabel,
      creatorNote: linked.creatorNote,
    );
    opened = playbackItem;

    expect(opened, isNotNull);
    expect(opened.type, AiSearchItemType.external);
    expect(opened.sourceAttribution, 'YouTube');
    expect(opened.embedDescriptor?.kind, EmbedKind.youtubeIframe);
  });
}

CreatorCustomizeController _controller(String creatorId) {
  return CreatorCustomizeController(
    initialCreatorId: creatorId,
    metadataApi: resolveCreatorMetadataApi(),
    experienceApi: resolveCreatorExperienceApi(),
    registryApi: resolveExtensionRegistryApi(),
    starterPackApi: resolveStarterPackApi(),
    externalContentApi: resolveExternalContentSourceApi(),
  );
}

Future<void> _connectAiSearch() async {
  final vault = resolveFanVaultApi();
  await vault.putSearchAgentConfig(
    passportId: 'passport_demo_fan',
    provider: AiSearchProvider.anthropicClaude,
    mcpEndpoint: 'mcp://demo-agent/search',
    connected: true,
    preferCreators: true,
    externalSourcesEnabled: true,
    idempotencyKey: 'p25-ai-search-connect',
  );
  await vault.putExternalSourceConnection(
    passportId: 'passport_demo_fan',
    sourceType: ExternalSourceType.youtube,
    connected: true,
    displayName: 'YouTube',
    idempotencyKey: 'p25-ai-search-youtube',
  );
}
