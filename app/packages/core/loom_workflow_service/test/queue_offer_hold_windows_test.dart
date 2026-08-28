import 'package:loom_workflow_service/src/queue_offer_hold_windows.dart';
import 'package:test/test.dart';

void main() {
  test('an absent or blank queue offer-hold configuration is unconfigured', () {
    expect(parseQueueOfferHoldWindows(null), isEmpty);
    expect(parseQueueOfferHoldWindows(''), isEmpty);
    expect(parseQueueOfferHoldWindows('{}'), isEmpty);
  });

  test('a configured queue offer-hold window is parsed as a duration', () {
    expect(
      parseQueueOfferHoldWindows('{"community_camera_club": 86400}'),
      <String, Duration>{'community_camera_club': const Duration(days: 1)},
    );
  });

  test('a present queue offer-hold configuration must be a JSON object', () {
    expect(() => parseQueueOfferHoldWindows('{'), throwsA(isA<StateError>()));
    expect(() => parseQueueOfferHoldWindows('[]'), throwsA(isA<StateError>()));
  });

  test('queue offer-hold windows must be positive integer seconds', () {
    for (final encoded in <String>[
      '{"community_camera_club": 0}',
      '{"community_camera_club": -1}',
      '{"community_camera_club": 1.5}',
    ]) {
      expect(
        () => parseQueueOfferHoldWindows(encoded),
        throwsA(isA<StateError>()),
      );
    }
  });
}
