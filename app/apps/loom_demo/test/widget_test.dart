import 'package:flutter_test/flutter_test.dart';
import 'package:loom_demo/main.dart';

void main() {
  testWidgets('Phase 0 app boots with fan content slice', (tester) async {
    await tester.pumpWidget(await buildLoomDemoAppForTest());
    await tester.pumpAndSettle();

    expect(find.text('Fan App'), findsWidgets);
    expect(find.text('Solar Sarah'), findsWidgets);
    expect(find.text('Load more'), findsOneWidget);
  });
}
