import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p26_gaming_external_seed', (tester) async {
    resetAppShellDependencies();
    final store = await configureDemoDependencies(persistent: false);
    addTearDown(store.close);

    for (final creatorId in _gamingCreatorIds) {
      final config = await resolveCreatorExperienceApi().getExperienceConfig(
        channelId: creatorId,
      );
      final module = config.surfaceModules.singleWhere(
        (candidate) => candidate.kind == 'external_content',
      );
      expect(module.config['sourceAttribution'], 'YouTube');
      final reference = await resolveExternalContentSourceApi()
          .getExternalContent(referenceId: module.config['referenceId']!);
      expect(reference.embedDescriptor.kind, EmbedKind.youtubeIframe);
    }
  });
}

const _gamingCreatorIds = [
  'creator_nova_clutch',
  'creator_ember_hollow',
  'creator_frame_by_frame',
  'creator_drift_and_chill',
  'creator_iron_vael',
];
