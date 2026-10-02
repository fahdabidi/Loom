import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'walkthrough_wait.dart';
import 'workflow_ui_test_harness.dart';

/// Regression coverage for the gap this ticket closes: a stall waiting for a
/// seeded account's `ListTile` reported only what was ABSENT -- never what
/// was actually on screen -- and never captured a diagnostic frame. A real
/// on-device stall produced "Diagnostic frame: (not captured)" with nothing
/// else to investigate, which is why three candidate root causes for the
/// same stall were indistinguishable from the evidence alone (see
/// HARNESS-remote-account-display-name-selection.md). This does not change
/// account-selection behaviour -- that stays exact-text matching on
/// `displayName`, per the ticket's refutation of the display-name-mismatch
/// hypothesis -- it only proves the stall now explains itself.
void main() {
  testWidgets(
    'signInEvidenceAccount names the visible accounts and captures a '
    'diagnostic frame when the expected account never appears',
    (tester) async {
      const extensionId = 'ext_account_chooser_stall_diagnostic';
      final authApi = LocalAuthApi()
        ..seedAccounts(extensionId, const [
          LoomAccount(
            accountId: 'fan-garden-coordinator-1',
            displayName: 'Garden Coordinator 1',
            roleId: 'garden-coordinator',
          ),
        ]);
      const experience = LoomExperienceDefinition(
        extensionId: extensionId,
        displayName: 'Garden Club',
        tagline: 'Grow together',
        accentColor: 0xFF4CAF50,
        workflows: [],
      );

      // `LoomAuthScreen` wrapped under the real `community-entry-gate` key is
      // exactly what `part01_local_extension_screen.dart`'s `_communityEntryGate`
      // renders for an engine-native community, which is the only case
      // `signInEvidenceAccount` reaches the account-row wait without first
      // driving the legacy actor-identity picker.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            key: const ValueKey('community-entry-gate'),
            body: LoomAuthScreen(
              authApi: authApi,
              communityExtensionId: extensionId,
              experience: experience,
              onSignIn: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final capturedFrameNames = <String>[];

      await expectLater(
        signInEvidenceAccount(
          tester,
          // Never seeded -- only "Garden Coordinator 1" exists above. This is
          // the exact shape of the on-device stall this test is named after:
          // the harness waited for a name the backend never rendered.
          'Garden Member 1',
          timeout: const Duration(milliseconds: 200),
          diagnosticFrameName: 'TEST_ACCOUNT_CHOOSER_STALL_DIAGNOSTIC',
          captureDiagnostic: (name) async {
            capturedFrameNames.add(name);
          },
        ),
        throwsA(
          isA<WalkthroughStallFailure>().having(
            (error) => error.message,
            'message',
            allOf([
              contains('seeded account Garden Member 1'),
              // The dump must name what IS on screen, not just what is
              // missing -- this is the account that actually loaded.
              contains('Garden Coordinator 1'),
              contains('TEST_ACCOUNT_CHOOSER_STALL_DIAGNOSTIC'),
              isNot(contains('(not captured)')),
            ]),
          ),
        ),
      );
      expect(capturedFrameNames, ['TEST_ACCOUNT_CHOOSER_STALL_DIAGNOSTIC']);
    },
  );
}
