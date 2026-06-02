import 'package:feature_creator_channel/feature_creator_channel.dart';
import 'package:feature_creator_customize/feature_creator_customize.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p25_play_linked_external', (tester) async {
    resetAppShellDependencies();
    final store = await configureDemoDependencies(persistent: false);
    addTearDown(store.close);

    final controller = CreatorCustomizeController(
      initialCreatorId: 'creator_nova_clutch',
      metadataApi: resolveCreatorMetadataApi(),
      experienceApi: resolveCreatorExperienceApi(),
      registryApi: resolveExtensionRegistryApi(),
      starterPackApi: resolveStarterPackApi(),
      externalContentApi: resolveExternalContentSourceApi(),
    );
    await controller.load();
    await controller.linkExternalContent(
      input: 'NovaClutch VOD',
      creatorNote: 'Creator-picked companion video.',
    );

    AiSearchItem? opened;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLoomTheme(),
        home: Scaffold(
          body: CreatorChannelHomeScreen(
            channelId: 'creator_nova_clutch',
            onOpenContent: (_) {},
            onBack: () {},
            onOpenExternal: (item) => opened = item,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.drag(
      find.byKey(const ValueKey('p4_channel_home')),
      const Offset(0, -500),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(
        const ValueKey(
          'p25_external_content_tile_pubref_creator-nova-clutch_youtube_m7lc1uvf-ve',
        ),
      ),
    );
    await tester.pump();

    expect(opened, isNotNull);
    expect(opened!.embedDescriptor?.kind, EmbedKind.youtubeIframe);
  });
}
