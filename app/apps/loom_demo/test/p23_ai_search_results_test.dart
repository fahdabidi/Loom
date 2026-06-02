import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_design_system/loom_design_system.dart';
import 'package:loom_fake_backend/loom_fake_backend.dart';
import 'package:loom_local_store/loom_local_store.dart';

void main() {
  late DemoLocalStore store;
  late FanVaultFake fanVault;

  setUp(() async {
    store = await DemoLocalStore.seeded();
    fanVault = FanVaultFake(store, latency: Duration.zero);
  });

  tearDown(() async {
    await store.close();
  });

  test(
    'p23 connected agent returns merged creator and external results',
    () async {
      await _connectAiSearch(fanVault);
      final controller = _controller(store, fanVault);
      addTearDown(controller.dispose);

      await controller.search('retake');

      final result = controller.aiSearchResult;
      expect(result, isNotNull);
      expect(result!.neutralityLabel, contains('No ads'));
      expect(controller.searchResults, isEmpty);
      expect(
        result.items.map((item) => item.type),
        containsAll([AiSearchItemType.creator, AiSearchItemType.external]),
      );
      expect(result.items.first.type, AiSearchItemType.creator);

      final external = result.items.firstWhere(
        (item) => item.type == AiSearchItemType.external,
      );
      expect(external.sourceAttribution, 'YouTube');
      expect(external.originalTitle, contains('NovaClutch VOD'));
      expect(external.accurateMatchLabel, 'Exact tactical retake breakdown');
    },
  );

  test('p23 no-agent fallback uses neutral search unchanged', () async {
    final controller = _controller(store, fanVault);
    addTearDown(controller.dispose);

    await controller.search('solar');

    expect(controller.aiSearchResult, isNull);
    expect(controller.searchResults, isNotEmpty);
    expect(controller.searchResults.first.neutralityLabel, contains('Neutral'));
  });

  testWidgets('p23 external result tile preserves title and source chip', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLoomTheme(),
        home: const Scaffold(
          body: AiResultTile(
            resultKey: 'p23_ai_external_demo',
            title: 'NovaClutch VOD: 1v4 retake without comms chaos',
            summary:
                'Public YouTube VOD reference focused on clean post-round review.',
            thumbnailRef: 'seed://youtube/nova-clutch-retake',
            sourceLabel: 'YouTube',
            rankReason: 'External public reference matched the query.',
            isExternal: true,
            accurateMatchLabel: 'Exact tactical retake breakdown',
            originalTitle: 'NovaClutch VOD: 1v4 retake without comms chaos',
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('p23_ai_external_demo')), findsOneWidget);
    expect(find.text('Exact tactical retake breakdown'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('p23_ai_external_demo_original_title')),
      findsOneWidget,
    );
    expect(
      find.text('NovaClutch VOD: 1v4 retake without comms chaos'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('p23_source_chip_YouTube')),
      findsOneWidget,
    );
  });
}

DiscoveryController _controller(DemoLocalStore store, FanVaultApi fanVault) {
  return DiscoveryController(
    recommendationApi: RecommendationReferralFake(
      store,
      latency: Duration.zero,
    ),
    searchApi: SearchFake(store, latency: Duration.zero),
    fanVaultApi: fanVault,
    aiGatewayApi: AiGatewayFake(store, latency: Duration.zero),
  );
}

Future<void> _connectAiSearch(FanVaultFake fanVault) async {
  await fanVault.putSearchAgentConfig(
    passportId: 'passport_demo_fan',
    provider: AiSearchProvider.anthropicClaude,
    mcpEndpoint: 'mcp://demo-agent/search',
    connected: true,
    preferCreators: true,
    externalSourcesEnabled: true,
    idempotencyKey: 'p23-connect-agent',
  );
  await fanVault.putExternalSourceConnection(
    passportId: 'passport_demo_fan',
    sourceType: ExternalSourceType.youtube,
    connected: true,
    displayName: 'YouTube',
    idempotencyKey: 'p23-connect-youtube',
  );
}
