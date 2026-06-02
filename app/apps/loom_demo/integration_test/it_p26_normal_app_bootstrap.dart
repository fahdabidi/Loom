import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_demo/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p26_normal_app_bootstrap', (tester) async {
    await app.main();

    for (
      var attempt = 0;
      attempt < 60 && find.text('Fan App').evaluate().isEmpty;
      attempt++
    ) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(find.text('Fan App'), findsWidgets);
    expect(find.text('Loom'), findsWidgets);
  });
}
