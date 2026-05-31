import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p0_content_list', (tester) async {
    await tester.pumpWidget(await buildLoomDemoAppForTest());
    await tester.pumpAndSettle();

    expect(find.text('Solar Sarah'), findsWidgets);
    expect(
      find.text('Rooftop storage that actually pencils out'),
      findsOneWidget,
    );

    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();

    expect(find.text('Battery safety checks before summer'), findsOneWidget);
  });
}
