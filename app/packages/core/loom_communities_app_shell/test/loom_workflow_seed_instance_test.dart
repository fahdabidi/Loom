import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';

Map<String, dynamic> _seedJson() => <String, dynamic>{
  'instanceId': 'seed-1',
  'workflowType': 'example-workflow',
  'currentState': 'open',
  'instanceData': <String, dynamic>{},
};

void main() {
  group('LoomWorkflowSeedInstance.fromJson specVersion 4 creator', () {
    test('reads the specVersion 4 createdByFanId spelling', () {
      final seed = LoomWorkflowSeedInstance.fromJson(
        _seedJson()..['createdByFanId'] = 'fan-v4',
      );

      expect(seed.createdByFanId, 'fan-v4');
    });

    test('does not read the legacy createdByPersonaId spelling', () {
      final seed = LoomWorkflowSeedInstance.fromJson(
        _seedJson()..['createdByPersonaId'] = 'fan-legacy',
      );

      expect(seed.createdByFanId, isNull);
    });

    test('treats an empty v4 creator as absent', () {
      final emptyV4 = LoomWorkflowSeedInstance.fromJson(
        _seedJson()..['createdByFanId'] = '',
      );

      expect(emptyV4.createdByFanId, isNull);
    });

    test('returns null when the creator is absent', () {
      final seed = LoomWorkflowSeedInstance.fromJson(_seedJson());

      expect(seed.createdByFanId, isNull);
    });
  });
}
