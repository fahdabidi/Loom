import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const phase1InterestIds = [
  'creator_tools',
  'family_learning',
  'personal_finance',
  'fermentation',
  'food_safety',
  'weeknight_cooking',
  'joint_friendly_cardio',
  'mobility',
  'strength_basics',
  'home_energy',
];

Future<void> startFanOnboarding(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('start_fan_onboarding_button')));
  await tester.pumpAndSettle();
}

Future<void> createPassportAndPickInterests(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('fan_create_passport_button')));
  await tester.pumpAndSettle();

  for (final id in phase1InterestIds) {
    final finder = find.byKey(ValueKey('interest_chip_$id'));
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  await tester.tap(find.byKey(const ValueKey('fan_save_interests_button')));
  await tester.pumpAndSettle();
}

Future<void> completeFanOnboarding(WidgetTester tester) async {
  await createPassportAndPickInterests(tester);
  await tester.tap(find.byKey(const ValueKey('fan_continue_privacy_button')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('fan_first_follow_button')));
  await tester.pumpAndSettle();
}
