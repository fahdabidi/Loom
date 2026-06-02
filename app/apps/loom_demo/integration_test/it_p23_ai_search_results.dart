import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo/main.dart';

late ValueNotifier<int> _searchRequests;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('p23 connected agent shows merged AI search results', (
    tester,
  ) async {
    final store = await configureDemoDependencies(persistent: false);
    addTearDown(() async {
      await store.close();
      resetAppShellDependencies();
    });
    await _connectAiSearch();

    await _pumpDiscovery(tester);
    await _runSearch(tester, 'retake');

    expect(
      find.byKey(const ValueKey('p23_ai_rank_disclosure')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('p23_ai_search_results')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('p23_source_chip_YouTube')),
      findsOneWidget,
    );
    expect(find.textContaining('Creator-owned result'), findsWidgets);
  });

  testWidgets('p23 external result preserves original title and source chip', (
    tester,
  ) async {
    final store = await configureDemoDependencies(persistent: false);
    addTearDown(() async {
      await store.close();
      resetAppShellDependencies();
    });
    await _connectAiSearch();

    await _pumpDiscovery(tester);
    await _runSearch(tester, 'retake');

    expect(find.text('Exact tactical retake breakdown'), findsOneWidget);
    expect(
      find.text('NovaClutch VOD: 1v4 retake without comms chaos'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('p23_source_chip_YouTube')),
      findsOneWidget,
    );
  });

  testWidgets('p23 no-agent fallback stays on neutral search path', (
    tester,
  ) async {
    final store = await configureDemoDependencies(persistent: false);
    addTearDown(() async {
      await store.close();
      resetAppShellDependencies();
    });

    await _pumpDiscovery(tester);
    await _runSearch(tester, 'solar');

    expect(
      find.byKey(const ValueKey('p23_neutral_search_results')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('p23_ai_rank_disclosure')), findsNothing);
    expect(
      find.byKey(const ValueKey('p3_search_no_ads_label')),
      findsOneWidget,
    );
  });
}

Future<void> _pumpDiscovery(WidgetTester tester) async {
  _searchRequests = ValueNotifier<int>(0);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLoomTheme(),
      home: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              key: const ValueKey('shell_search_button'),
              onPressed: () => _searchRequests.value += 1,
              icon: const Icon(Icons.search_rounded),
            ),
          ],
        ),
        body: DiscoveryHomeScreen(
          searchRequests: _searchRequests,
          onStartOnboarding: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _runSearch(WidgetTester tester, String query) async {
  await tester.tap(find.byKey(const ValueKey('shell_search_button')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const ValueKey('p3_search_field')), query);
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await tester.pumpAndSettle();
}

Future<void> _connectAiSearch() async {
  await resolveFanVaultApi().putSearchAgentConfig(
    passportId: 'passport_demo_fan',
    provider: AiSearchProvider.anthropicClaude,
    mcpEndpoint: 'mcp://demo-agent/search',
    connected: true,
    preferCreators: true,
    externalSourcesEnabled: true,
    idempotencyKey: 'it-p23-agent',
  );
  await resolveFanVaultApi().putExternalSourceConnection(
    passportId: 'passport_demo_fan',
    sourceType: ExternalSourceType.youtube,
    connected: true,
    displayName: 'YouTube',
    idempotencyKey: 'it-p23-youtube',
  );
}
