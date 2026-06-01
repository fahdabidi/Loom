import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'p3_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p8_referral_settlement', (tester) async {
    await openDiscoveryHome(tester);

    await tester.tap(find.text('Creator Studio'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('p8_open_recommendations_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('p8_record_referral_conversion_button')),
    );
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('p8_referral_settled')), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('p8_recommendations_back_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('p6_open_revenue_dashboard_button')),
    );
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    expect(find.text('Referrals'), findsOneWidget);
    expect(find.text('\$3.50'), findsWidgets);
  });
}
