import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p0_boot', (tester) async {
    await tester.pumpWidget(await buildLoomDemoAppForTest());
    await tester.pumpAndSettle();

    expect(find.text('Fan App'), findsWidgets);

    await tester.tap(find.text('Creator Studio'));
    await tester.pumpAndSettle();
    expect(find.text('Create your channel'), findsOneWidget);

    await tester.tap(find.text('Fan App'));
    await tester.pumpAndSettle();
    expect(find.text('Fan App'), findsWidgets);
  });
}
