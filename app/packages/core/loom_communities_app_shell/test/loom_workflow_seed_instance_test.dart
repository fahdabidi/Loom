import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';

Map<String, dynamic> _seedJson() => <String, dynamic>{
  'instanceId': 'seed-1',
  'workflowType': 'example-workflow',
  'currentState': 'open',
  'instanceData': <String, dynamic>{},
};

void main() {
  group('LoomWorkflowSeedInstance.fromJson creator D8 straddle', () {
    test('reads the specVersion 4 createdByFanId spelling', () {
      final seed = LoomWorkflowSeedInstance.fromJson(
        _seedJson()..['createdByFanId'] = 'fan-v4',
      );

      expect(seed.createdByPersonaId, 'fan-v4');
    });

    test('keeps reading the legacy createdByPersonaId spelling', () {
      final seed = LoomWorkflowSeedInstance.fromJson(
        _seedJson()..['createdByPersonaId'] = 'fan-legacy',
      );

      expect(seed.createdByPersonaId, 'fan-legacy');
    });

    test('prefers createdByFanId when both spellings are present', () {
      final seed = LoomWorkflowSeedInstance.fromJson(
        _seedJson()
          ..['createdByFanId'] = 'fan-v4'
          ..['createdByPersonaId'] = 'fan-legacy',
      );

      expect(seed.createdByPersonaId, 'fan-v4');
    });

    test('treats an empty creator spelling as absent', () {
      final legacyFallback = LoomWorkflowSeedInstance.fromJson(
        _seedJson()
          ..['createdByFanId'] = ''
          ..['createdByPersonaId'] = 'fan-legacy',
      );
      final emptyV4 = LoomWorkflowSeedInstance.fromJson(
        _seedJson()..['createdByFanId'] = '',
      );
      final emptyLegacy = LoomWorkflowSeedInstance.fromJson(
        _seedJson()..['createdByPersonaId'] = '',
      );

      expect(legacyFallback.createdByPersonaId, 'fan-legacy');
      expect(emptyV4.createdByPersonaId, isNull);
      expect(emptyLegacy.createdByPersonaId, isNull);
    });

    test('returns null when both creator spellings are absent', () {
      final seed = LoomWorkflowSeedInstance.fromJson(_seedJson());

      expect(seed.createdByPersonaId, isNull);
    });
  });
}
