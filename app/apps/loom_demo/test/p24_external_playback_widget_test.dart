import 'package:feature_playback/feature_playback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_fake_backend/loom_fake_backend.dart';
import 'package:loom_local_store/loom_local_store.dart';

void main() {
  late DemoLocalStore store;
  late AiGatewayFake aiGateway;
  late FanVaultFake fanVault;

  setUp(() async {
    resetAppShellDependencies();
    store = await DemoLocalStore.seeded();
    aiGateway = AiGatewayFake(store, latency: Duration.zero);
    fanVault = FanVaultFake(store, latency: Duration.zero);
    registerAiGatewayApi(aiGateway);
    await _connectAiSearch(fanVault);
  });

  tearDown(() async {
    await store.close();
    resetAppShellDependencies();
  });

  testWidgets(
    'p24 youtube item renders official iframe surface and AI next rail',
    (tester) async {
      final initialItem = (await tester.runAsync(
        () => _youtubeItem(aiGateway),
      ))!;

      await tester.pumpWidget(
        MaterialApp(
          theme: buildLoomTheme(),
          home: Scaffold(
            body: ExternalPlaybackScreen(
              initialItem: initialItem,
              enableLiveYoutubePlayer: false,
              onBack: () {},
            ),
          ),
        ),
      );
      await _pumpExternalPlayback(tester);

      expect(
        find.byKey(const ValueKey('p24_external_playback_screen')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('p24_external_source_banner')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('p24_youtube_embed_player_mock')),
        findsOneWidget,
      );
      await _scrollPlaybackDown(tester);
      expect(
        find.byKey(const ValueKey('p24_no_loom_ads_over_embed')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('p24_ai_next_rail')), findsOneWidget);
      expect(find.text('Next from your AI search'), findsOneWidget);
    },
  );

  testWidgets('p24 non-youtube item launches externally with mock launcher', (
    tester,
  ) async {
    Uri? launchedUri;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLoomTheme(),
        home: Scaffold(
          body: ExternalPlaybackScreen(
            initialItem: _blogItem(),
            enableLiveYoutubePlayer: false,
            launchExternalUrl: (uri) async {
              launchedUri = uri;
              return true;
            },
            onBack: () {},
          ),
        ),
      ),
    );
    await _pumpExternalPlayback(tester);

    expect(launchedUri, Uri.parse('https://creator.example/raid-guide'));
    await _scrollPlaybackDown(tester);
    expect(
      find.byKey(const ValueKey('p24_external_open_status')),
      findsOneWidget,
    );
    expect(find.text('External source opened.'), findsOneWidget);
  });
}

Future<void> _pumpExternalPlayback(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump();
}

Future<void> _scrollPlaybackDown(WidgetTester tester) async {
  await tester.drag(
    find.byKey(const ValueKey('p24_external_playback_screen')),
    const Offset(0, -420),
  );
  await tester.pump();
}

Future<AiSearchItem> _youtubeItem(AiGatewayFake aiGateway) async {
  final result = await aiGateway.runAiSearch(
    passportId: 'passport_demo_fan',
    query: 'retake',
  );
  return result.items.firstWhere(
    (item) => item.embedDescriptor?.kind == EmbedKind.youtubeIframe,
  );
}

AiSearchItem _blogItem() {
  return const AiSearchItem(
    id: 'blog_raid_guide',
    type: AiSearchItemType.external,
    originalTitle: 'Creator blog: raid prep checklist',
    summary: 'A public creator blog checklist for raid-night preparation.',
    thumbnailRef: 'seed://blog/raid-guide',
    rankReason: 'External blog result matched the query.',
    titleRiskSignals: [],
    sourceAttribution: 'Creator blog',
    score: 0.81,
    externalTargetRef: ExternalTargetRef(
      referenceId: 'blog_raid_guide',
      sourceType: ExternalSourceType.blog,
      externalId: 'raid-guide',
    ),
    embedDescriptor: EmbedDescriptor(
      kind: EmbedKind.link,
      externalId: 'raid-guide',
      sourceUrl: 'https://creator.example/raid-guide',
    ),
    accurateMatchLabel: 'Raid prep checklist',
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
    idempotencyKey: 'p24-connect-agent',
  );
  await fanVault.putExternalSourceConnection(
    passportId: 'passport_demo_fan',
    sourceType: ExternalSourceType.youtube,
    connected: true,
    displayName: 'YouTube',
    idempotencyKey: 'p24-connect-youtube',
  );
}
