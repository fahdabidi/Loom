import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';

void main() {
  group('Milestone 2.1 audienceSelector form field', () {
    testWidgets('switches mode inputs and emits matching instanceData', (
      tester,
    ) async {
      Map<String, dynamic>? submitted;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkflowAudienceSelectorField(
              availableFanIds: const ['alice', 'bob', 'cora'],
              onChanged: (data) => submitted = data,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('audience-selector-field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('audience-selector-selected-many')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('audience-selector-individual')),
        findsNothing,
      );
      expect(submitted, {'audienceScope': 'all', 'invitedFanIds': <String>[]});

      await tester.tap(find.byKey(const ValueKey('audience-selector-scope')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selected members').last);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('audience-selector-selected-many')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('audience-selector-fan-alice')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('audience-selector-fan-bob')),
      );
      await tester.pumpAndSettle();
      expect(submitted, {
        'audienceScope': 'selected',
        'invitedFanIds': ['alice', 'bob'],
      });

      await tester.tap(find.byKey(const ValueKey('audience-selector-scope')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('One member').last);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('audience-selector-individual')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('audience-selector-fan-cora')),
      );
      await tester.pumpAndSettle();
      expect(submitted, {
        'audienceScope': 'individual',
        'invitedFanIds': ['cora'],
      });
    });
  });
}
