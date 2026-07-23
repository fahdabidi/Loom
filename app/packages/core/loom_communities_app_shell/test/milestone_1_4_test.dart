import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';

void main() {
  group('Milestone 1.4 rendering primitives', () {
    testWidgets(
      'WorkflowActionButtonRow renders fixed transitions with stable keys and distinct tones',
      (WidgetTester tester) async {
        const transitions = <WorkflowActionButtonTransition>[
          WorkflowActionButtonTransition(
            id: 'borrow',
            label: 'Borrow',
            iconName: 'arrow_forward',
            tone: WorkflowActionTone.primary,
          ),
          WorkflowActionButtonTransition(
            id: 'join',
            label: 'Join queue',
            iconName: 'add_circle_outline',
            tone: WorkflowActionTone.secondary,
          ),
          WorkflowActionButtonTransition(
            id: 'return',
            label: 'Return',
            iconName: 'keyboard_return',
            tone: WorkflowActionTone.destructive,
          ),
        ];
        const primaryColor = Color(0xFF1F6FEB);
        const secondaryColor = Color(0xFFF57C00);

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: primaryColor,
              ).copyWith(primary: primaryColor, secondary: secondaryColor),
            ),
            home: Scaffold(
              body: WorkflowActionButtonRow(
                surface: 'equipment-loan',
                availableTransitions: transitions,
                onTransitionPressed: (_) {},
              ),
            ),
          ),
        );

        expect(find.byType(FilledButton), findsNWidgets(2));
        expect(find.byType(OutlinedButton), findsNWidgets(1));
        expect(
          find.byKey(const ValueKey('equipment-loan-action-borrow')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('equipment-loan-action-join')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('equipment-loan-action-return')),
          findsOneWidget,
        );

        final primaryButton = tester.widget<FilledButton>(
          find.byKey(const ValueKey('equipment-loan-action-borrow')),
        );
        final secondaryButton = tester.widget<OutlinedButton>(
          find.byKey(const ValueKey('equipment-loan-action-join')),
        );
        final destructiveButton = tester.widget<FilledButton>(
          find.byKey(const ValueKey('equipment-loan-action-return')),
        );

        expect(
          primaryButton.style?.backgroundColor?.resolve(const {}),
          equals(primaryColor),
        );
        expect(
          destructiveButton.style?.backgroundColor?.resolve(const {}),
          equals(Colors.red.shade700),
        );
        expect(
          secondaryButton.style?.backgroundColor?.resolve(const {}),
          isNot(equals(Colors.red.shade700)),
        );
        expect(
          primaryButton.style?.backgroundColor?.resolve(const {}),
          isNot(secondaryButton.style?.foregroundColor?.resolve(const {})),
        );

        expect(
          find.descendant(
            of: find.byKey(const ValueKey('equipment-loan-action-borrow')),
            matching: find.byIcon(Icons.arrow_forward),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('equipment-loan-action-join')),
            matching: find.byIcon(Icons.add_circle_outline),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('equipment-loan-action-return')),
            matching: find.byIcon(Icons.keyboard_return),
          ),
          findsOneWidget,
        );
        expect(primaryButton.onPressed, isNotNull);
      },
    );

    testWidgets(
      'WorkflowActionButtonRow renders waiting UX when prerequisite is unsatisfied',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: WorkflowActionButtonRow(
                surface: 'equipment-loan',
                availableTransitions: const [
                  WorkflowActionButtonTransition(
                    id: 'borrow',
                    label: 'Borrow',
                    iconName: 'arrow_forward',
                    tone: WorkflowActionTone.primary,
                    waitingForPrerequisite: true,
                    waitingText: 'Waiting',
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.byType(FilledButton), findsNothing);
        expect(find.byType(OutlinedButton), findsNothing);
        expect(
          find.byKey(const ValueKey('equipment-loan-action-borrow')),
          findsOneWidget,
        );
        expect(find.text('Waiting'), findsOneWidget);
        expect(find.byIcon(Icons.schedule), findsOneWidget);
      },
    );

    testWidgets(
      'WorkflowFactPillRow renders icon/label schema and hideWhenEmpty for queuedPersonaIds',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: WorkflowFactPillRow(
              instanceData: const {
                'title': 'Catan',
                'category': 'Board games',
                'condition': 'Mint condition',
                'holderPersonaId': 'Alice',
                'queuedPersonaIds': <String>[],
                'dueDate': '2025-01-01',
              },
              instanceDataSchema: equipmentLoanDefaultInstanceDataSchema,
              displayContext: 'detail',
            ),
          ),
        );

        expect(find.byIcon(Icons.title), findsOneWidget);
        expect(find.text('Catan'), findsOneWidget);
        expect(find.text('Board games'), findsOneWidget);
        expect(find.text('Mint condition'), findsOneWidget);
        expect(find.text('Holder: Alice'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('workflow-fact-persona-holderPersonaId')),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.groups_outlined), findsNothing);
        expect(find.byIcon(Icons.label_outline), findsNothing);

        await tester.pumpWidget(
          const MaterialApp(
            home: WorkflowFactPillRow(
              instanceData: const {
                'title': 'Catan',
                'category': 'Board games',
                'condition': 'Mint condition',
                'holderPersonaId': 'Alice',
                'queuedPersonaIds': ['m1', 'm2', 'm3'],
                'dueDate': '2025-01-01',
              },
              instanceDataSchema: equipmentLoanDefaultInstanceDataSchema,
              displayContext: 'detail',
            ),
          ),
        );

        await tester.pump();
        expect(find.text('Queue: 3'), findsOneWidget);
        expect(find.byIcon(Icons.groups_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'WorkflowFactPillRow keeps short scalars as pills and wraps long text',
      (WidgetTester tester) async {
        const description =
            'A detailed description that is intentionally allowed to wrap across lines rather than being clipped into a fact pill.';
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: WorkflowFactPillRow(
                instanceData: {
                  'shortLabel': 'Available now',
                  'description': description,
                },
                instanceDataSchema: {
                  'shortLabel': WorkflowFactPillFieldSchema(
                    type: 'text',
                    maxLength: 40,
                    displayIcon: 'inventory_2_outlined',
                    labelTemplate: '{value}',
                  ),
                  'description': WorkflowFactPillFieldSchema(
                    type: 'text',
                    maxLength: null,
                  ),
                },
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
        expect(
          find.byKey(const ValueKey('workflow-fact-paragraph-shortLabel')),
          findsNothing,
        );
        final paragraph = find.byKey(
          const ValueKey('workflow-fact-paragraph-description'),
        );
        expect(paragraph, findsOneWidget);
        expect(find.descendant(of: paragraph, matching: find.text(description)), findsOneWidget);
      },
    );

    testWidgets(
      'equipment-loan and equipment-giveaway templates render exactly one WorkflowActionButtonRow in primary bindings',
      (WidgetTester tester) async {
        const loanTransition = WorkflowActionButtonTransition(
          id: 'borrow',
          label: 'Borrow',
          iconName: 'arrow_forward',
          tone: WorkflowActionTone.primary,
        );
        const giveawayTransition = WorkflowActionButtonTransition(
          id: 'claim',
          label: 'Claim',
          iconName: 'check_circle_outline',
          tone: WorkflowActionTone.primary,
        );
        final templateSurfaceByData =
            <String, Map<String, WorkflowFactPillFieldSchema>>{
              'equipment-loan': equipmentLoanDefaultInstanceDataSchema,
              'equipment-giveaway': equipmentGiveawayDefaultInstanceDataSchema,
            };
        final templateTransitions =
            <String, List<WorkflowActionButtonTransition>>{
              'equipment-loan': [loanTransition],
              'equipment-giveaway': [giveawayTransition],
            };
        final templateData = <String, Map<String, dynamic>>{
          'equipment-loan': const {
            'title': 'Catan',
            'category': 'Board games',
            'condition': 'Mint',
            'holderPersonaId': 'Alice',
            'queuedPersonaIds': ['m1', 'm2'],
          },
          'equipment-giveaway': const {
            'title': 'Dice',
            'category': 'Board games',
            'condition': 'Excellent',
            'claimedByPersonaId': 'Alice',
          },
        };

        for (final surface in const ['equipment-loan', 'equipment-giveaway']) {
          await tester.pumpWidget(
            MaterialApp(
              home: WorkflowCardSurfaceTemplateRenderer(
                surfaceFamily: surface,
                instanceData: templateData[surface]!,
                instanceDataSchema: templateSurfaceByData[surface]!,
                availableTransitions: templateTransitions[surface]!,
              ),
            ),
          );
          expect(find.byType(WorkflowActionButtonRow), findsOneWidget);
        }
      },
    );
  });
}
