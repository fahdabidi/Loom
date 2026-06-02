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
    'p21 agent config and source connections persist through Fan Vault API',
    () async {
      final vault = resolveFanVaultApi();

      final initial = await vault.getSearchAgentConfig('passport_demo_fan');
      expect(initial.connected, isFalse);
      expect(initial.preferCreators, isTrue);

      final connected = await vault.putSearchAgentConfig(
        passportId: 'passport_demo_fan',
        provider: AiSearchProvider.anthropicClaude,
        mcpEndpoint: 'mcp://demo-agent/search',
        connected: true,
        preferCreators: true,
        externalSourcesEnabled: true,
        idempotencyKey: 'p21-connect-agent',
      );
      expect(connected.connected, isTrue);
      expect(connected.externalSourcesEnabled, isTrue);

      final youtube = await vault.putExternalSourceConnection(
        passportId: 'passport_demo_fan',
        sourceType: ExternalSourceType.youtube,
        connected: true,
        displayName: 'YouTube',
        idempotencyKey: 'p21-connect-youtube',
      );
      expect(youtube.connected, isTrue);

      final sources = await vault.getExternalSourceConnections(
        'passport_demo_fan',
      );
      expect(
        sources
            .singleWhere(
              (source) => source.sourceType == ExternalSourceType.youtube,
            )
            .connected,
        isTrue,
      );
    },
  );

  test(
    'p21 AI search merges creator and external candidates with receipts',
    () async {
      final vault = resolveFanVaultApi();
      await vault.putSearchAgentConfig(
        passportId: 'passport_demo_fan',
        provider: AiSearchProvider.anthropicClaude,
        mcpEndpoint: 'mcp://demo-agent/search',
        connected: true,
        preferCreators: true,
        externalSourcesEnabled: true,
        idempotencyKey: 'p21-ai-search-connect',
      );
      await vault.putExternalSourceConnection(
        passportId: 'passport_demo_fan',
        sourceType: ExternalSourceType.youtube,
        connected: true,
        displayName: 'YouTube',
        idempotencyKey: 'p21-ai-search-youtube',
      );

      final result = await resolveAiGatewayApi().runAiSearch(
        passportId: 'passport_demo_fan',
        query: 'raid',
        limit: 8,
      );

      expect(result.searchReceiptId, startsWith('receipt_search_'));
      expect(result.neutralityLabel, contains('No ads'));
      expect(
        result.items.any((item) => item.type == AiSearchItemType.creator),
        isTrue,
      );
      final external = result.items.firstWhere(
        (item) => item.type == AiSearchItemType.external,
      );
      expect(external.sourceAttribution, 'YouTube');
      expect(external.embedDescriptor?.kind, EmbedKind.youtubeIframe);
      expect(external.originalTitle, contains('raid'));
      expect(external.accurateMatchLabel, isNotEmpty);
    },
  );

  test(
    'p21 external content source resolves seeded YouTube references',
    () async {
      final candidates = await resolveExternalContentSourceApi()
          .searchExternalContent(
            passportId: 'passport_demo_fan',
            query: 'clutch',
            sourceTypes: const [ExternalSourceType.youtube],
          );

      expect(candidates, isNotEmpty);
      final candidate = candidates.first;
      expect(candidate.sourceAttribution, 'YouTube');
      expect(candidate.embedDescriptor.kind, EmbedKind.youtubeIframe);
      expect(candidate.originalTitle, contains('NovaClutch'));

      final resolved = await resolveExternalContentSourceApi()
          .getExternalContent(referenceId: candidate.targetRef.referenceId);
      expect(resolved.targetRef.externalId, candidate.targetRef.externalId);
    },
  );

  test(
    'p21 reset restores disconnected defaults and seeded external refs',
    () async {
      await resolveFanVaultApi().putSearchAgentConfig(
        passportId: 'passport_demo_fan',
        provider: AiSearchProvider.openAi,
        mcpEndpoint: 'mcp://changed',
        connected: true,
        preferCreators: false,
        externalSourcesEnabled: true,
        idempotencyKey: 'p21-reset-change',
      );

      await store.resetDemo();

      final config = await resolveFanVaultApi().getSearchAgentConfig(
        'passport_demo_fan',
      );
      expect(config.connected, isFalse);
      expect(config.preferCreators, isTrue);

      final candidates = await resolveExternalContentSourceApi()
          .searchExternalContent(
            passportId: 'passport_demo_fan',
            query: 'raid',
            sourceTypes: const [ExternalSourceType.youtube],
          );
      expect(candidates, isNotEmpty);
    },
  );
}
