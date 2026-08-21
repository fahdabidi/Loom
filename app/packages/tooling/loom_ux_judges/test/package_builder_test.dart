import 'package:loom_ux_judges/src/validator/package_builder.dart';
import 'package:test/test.dart';

void main() {
  test('extension manifest uses the specVersion 4 package stamp', () {
    final plan = buildExtensionPackagePlan(<String, dynamic>{
      'specVersion': 4,
      'extensionId': 'ext_test',
      'communityId': 'community_test',
      'displayName': 'Test Community',
    });

    expect(plan.extensionManifest['specVersion'], 4);
    expect(plan.extensionManifest, isNot(contains('schemaVersion')));
  });
}
