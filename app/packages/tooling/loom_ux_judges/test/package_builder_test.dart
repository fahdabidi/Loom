import 'package:loom_ux_judges/src/validator/package_builder.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show currentCommunitySpecVersion;
import 'package:test/test.dart';

void main() {
  test('extension manifest uses the specVersion 4 package stamp', () {
    final plan = buildExtensionPackagePlan(<String, dynamic>{
      'specVersion': currentCommunitySpecVersion,
      'extensionId': 'ext_test',
      'communityId': 'community_test',
      'displayName': 'Test Community',
    });

    expect(plan.extensionManifest['specVersion'], currentCommunitySpecVersion);
    expect(plan.extensionManifest, isNot(contains('schemaVersion')));
  });
}
