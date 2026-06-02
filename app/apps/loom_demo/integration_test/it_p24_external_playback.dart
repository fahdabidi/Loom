import 'package:feature_playback/feature_playback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('p24 embed launch renders player surface and attribution', (
    tester,
  ) async {
    final store = await configureDemoDependencies(persistent: false);
    addTearDown(() async {
      await store.close();
      resetAppShellDependencies();
    });
    await _connectAiSearch();
    final item = await _youtubeItem();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLoomTheme(),
        home: ExternalPlaybackScreen(
          initialItem: item,
          enableLiveYoutubePlayer: false,
          onBack: () {},
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
    expect(find.byKey(const ValueKey('p24_ai_next_rail')), findsOneWidget);
  });

  testWidgets('p24 non-youtube external uses external launcher', (
    tester,
  ) async {
    final store = await configureDemoDependencies(persistent: false);
    addTearDown(() async {
      await store.close();
      resetAppShellDependencies();
    });
    await _connectAiSearch();
    Uri? launchedUri;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLoomTheme(),
        home: ExternalPlaybackScreen(
          initialItem: _blogItem(),
          enableLiveYoutubePlayer: false,
          launchExternalUrl: (uri) async {
            launchedUri = uri;
            return true;
          },
          onBack: () {},
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

Future<AiSearchItem> _youtubeItem() async {
  final result = await resolveAiGatewayApi().runAiSearch(
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

Future<void> _connectAiSearch() async {
  await resolveFanVaultApi().putSearchAgentConfig(
    passportId: 'passport_demo_fan',
    provider: AiSearchProvider.anthropicClaude,
    mcpEndpoint: 'mcp://demo-agent/search',
    connected: true,
    preferCreators: true,
    externalSourcesEnabled: true,
    idempotencyKey: 'it-p24-agent',
  );
  await resolveFanVaultApi().putExternalSourceConnection(
    passportId: 'passport_demo_fan',
    sourceType: ExternalSourceType.youtube,
    connected: true,
    displayName: 'YouTube',
    idempotencyKey: 'it-p24-youtube',
  );
}
