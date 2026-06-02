import 'package:feature_playback/feature_playback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p26_offline_states', (tester) async {
    resetAppShellDependencies();
    final store = await configureDemoDependencies(persistent: false);
    addTearDown(store.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLoomTheme(),
        home: Scaffold(
          body: ExternalPlaybackScreen(
            initialItem: const AiSearchItem(
              id: 'web_ref',
              type: AiSearchItemType.external,
              originalTitle: 'Creator blog reference',
              summary: 'Non-YouTube source uses explicit external-open state.',
              thumbnailRef: 'seed://external/blog',
              rankReason: 'Offline/external-open smoke.',
              titleRiskSignals: [],
              sourceAttribution: 'Creator blog',
              score: 1,
              externalTargetRef: ExternalTargetRef(
                referenceId: 'web_ref',
                sourceType: ExternalSourceType.blog,
                externalId: 'blog-ref',
              ),
              embedDescriptor: EmbedDescriptor(
                kind: EmbedKind.link,
                externalId: 'blog-ref',
                sourceUrl: 'https://blog.example/ref',
              ),
            ),
            onBack: () {},
            launchExternalUrl: (_) async => false,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byKey(const ValueKey('p24_external_open_status')),
      findsOneWidget,
    );
  });
}
