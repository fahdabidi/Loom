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

  test(
    'p26 five gaming creators include seeded youtube feed modules',
    () async {
      for (final creatorId in _gamingCreatorIds) {
        final config = await resolveCreatorExperienceApi().getExperienceConfig(
          channelId: creatorId,
        );
        final module = config.surfaceModules.singleWhere(
          (candidate) => candidate.kind == 'external_content',
        );
        expect(module.config['sourceAttribution'], 'YouTube');
        expect(module.config['embedKind'], 'youtube_iframe');
        expect(module.config['searchIndexable'], 'true');
        expect(module.config['aiQueryable'], 'true');

        final reference = await resolveExternalContentSourceApi()
            .getExternalContent(referenceId: module.config['referenceId']!);
        expect(reference.sourceAttribution, 'YouTube');
        expect(reference.embedDescriptor.kind, EmbedKind.youtubeIframe);
        expect(reference.originalTitle, module.config['originalTitle']);
      }
    },
  );

  test(
    'p26 ai search showcase returns playable external youtube result',
    () async {
      await _connectAiSearch();

      final result = await resolveAiGatewayApi().runAiSearch(
        passportId: 'passport_demo_fan',
        query: 'raid',
        limit: 10,
      );

      expect(result.neutralityLabel, contains('No ads'));
      final external = result.items.firstWhere(
        (item) => item.type == AiSearchItemType.external,
      );
      expect(external.sourceAttribution, 'YouTube');
      expect(external.embedDescriptor?.kind, EmbedKind.youtubeIframe);
      expect(external.accurateMatchLabel, isNotEmpty);
      expect(external.originalTitle, isNot(contains('RAGEBAIT')));
    },
  );

  test(
    'p26 reset restores seeded external modules and clears mutable link',
    () async {
      await resolveExternalContentSourceApi().linkCreatorExternalContent(
        channelId: 'creator_nova_clutch',
        sourceType: ExternalSourceType.youtube,
        input: 'https://www.youtube.com/watch?v=M7lc1UVf-VE',
        creatorNote: 'Mutable creator-added note.',
        searchIndexable: true,
        aiQueryable: true,
        idempotencyKey: 'p26-mutable-link',
      );

      await store.resetDemo();

      final config = await resolveCreatorExperienceApi().getExperienceConfig(
        channelId: 'creator_nova_clutch',
      );
      final module = config.surfaceModules.singleWhere(
        (candidate) => candidate.kind == 'external_content',
      );
      expect(module.config['creatorNote'], contains('calm clutch review'));
      expect(
        module.config['referenceId'],
        'pubref_creator-nova-clutch_youtube_1',
      );
    },
  );
}

const _gamingCreatorIds = [
  'creator_nova_clutch',
  'creator_ember_hollow',
  'creator_frame_by_frame',
  'creator_drift_and_chill',
  'creator_iron_vael',
];

Future<void> _connectAiSearch() async {
  final vault = resolveFanVaultApi();
  await vault.putSearchAgentConfig(
    passportId: 'passport_demo_fan',
    provider: AiSearchProvider.anthropicClaude,
    mcpEndpoint: 'mcp://demo-agent/search',
    connected: true,
    preferCreators: true,
    externalSourcesEnabled: true,
    idempotencyKey: 'p26-ai-search-connect',
  );
  await vault.putExternalSourceConnection(
    passportId: 'passport_demo_fan',
    sourceType: ExternalSourceType.youtube,
    connected: true,
    displayName: 'YouTube',
    idempotencyKey: 'p26-ai-search-youtube',
  );
}
