import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p20_full_demo_regression', (tester) async {
    resetAppShellDependencies();
    final store = await configureDemoDependencies(persistent: false);
    addTearDown(store.close);

    await tester.pumpWidget(const LoomDemoApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.text('Loom'), findsWidgets);
    expect(find.byKey(const ValueKey('p9_demo_menu_button')), findsOneWidget);
  });
}
