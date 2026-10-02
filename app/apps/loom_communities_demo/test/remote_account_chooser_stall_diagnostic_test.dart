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
///
/// The two tests below close the SAME gap at the two sites `3cb47f8e` left
/// uninstrumented: the membership-resolution wait that runs before any of
/// this, and the post-tap wait for "community content to load after signing
/// in" -- the wait the Garden sign-in stall names (see CLAUDE.md "a recorded
/// row failure must restore the surface... instrument the Garden sign-in
/// wait"). Both used to throw with "Diagnostic frame: (not captured)" and no
/// screen dump; both now capture a frame and name what IS on screen.
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

  testWidgets(
    'signInEvidenceAccount captures a diagnostic frame when community '
    'membership checking never resolves',
    (tester) async {
      // `community-entry-checking` never disappearing is exactly what a
      // stuck membership lookup looks like -- see
      // `_waitForCommunityEntryResolution`. Before this change it had no
      // `diagnosticFrameName`/`captureDiagnostic` parameters at all, so a
      // stall here could never capture a frame.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            key: ValueKey('community-entry-checking'),
            body: Center(child: Text('Checking membership...')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final capturedFrameNames = <String>[];

      // A fake, fast-forwarding clock -- not a short real-time timeout --
      // keeps this deterministic: `budget.expired` is driven by `now()`
      // alone, so the loop exits on its first check without depending on
      // real wall-clock scheduling.
      var observed = DateTime.utc(2026, 1, 1);
      DateTime fakeNow() {
        observed = observed.add(const Duration(seconds: 1));
        return observed;
      }

      await expectLater(
        () => signInEvidenceAccount(
          tester,
          'Garden Member 1',
          timeout: const Duration(seconds: 2),
          now: fakeNow,
          diagnosticFrameName: 'TEST_MEMBERSHIP_CHECKING_STALL_DIAGNOSTIC',
          captureDiagnostic: (name) async {
            capturedFrameNames.add(name);
          },
        ),
        throwsA(
          isA<WalkthroughStallFailure>().having(
            (error) => error.message,
            'message',
            allOf([
              contains('community membership checking to resolve'),
              contains('Checking membership...'),
              contains('TEST_MEMBERSHIP_CHECKING_STALL_DIAGNOSTIC'),
              isNot(contains('(not captured)')),
            ]),
          ),
        ),
      );
      expect(capturedFrameNames, ['TEST_MEMBERSHIP_CHECKING_STALL_DIAGNOSTIC']);
    },
  );

  testWidgets(
    'signInEvidenceAccount captures a diagnostic frame when community '
    'content never loads after signing in',
    (tester) async {
      const extensionId = 'ext_post_sign_in_stall_diagnostic';
      final authApi = LocalAuthApi()
        ..seedAccounts(extensionId, const [
          LoomAccount(
            accountId: 'fan-garden-member-1',
            displayName: 'Garden Member 1',
            roleId: 'garden-member',
          ),
        ]);
      const experience = LoomExperienceDefinition(
        extensionId: extensionId,
        displayName: 'Garden Club',
        tagline: 'Grow together',
        accentColor: 0xFF4CAF50,
        workflows: [],
      );

      // Tapping the seeded account below calls this no-op `onSignIn`, same
      // as the test above -- so nothing in this minimal tree ever renders
      // `actor-identity-picker-button`. That is exactly the shape of "the
      // login round trip completed but the post-sign-in community content
      // never arrived": the account row is found and tapped (the PRECEDING
      // wait succeeds), and the stall is the FOLLOWING one.
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

      var observed = DateTime.utc(2026, 1, 1);
      DateTime fakeNow() {
        observed = observed.add(const Duration(seconds: 1));
        return observed;
      }

      await expectLater(
        () => signInEvidenceAccount(
          tester,
          'Garden Member 1',
          timeout: const Duration(seconds: 2),
          now: fakeNow,
          diagnosticFrameName: 'TEST_POST_SIGN_IN_STALL_DIAGNOSTIC',
          captureDiagnostic: (name) async {
            capturedFrameNames.add(name);
          },
        ),
        throwsA(
          isA<WalkthroughStallFailure>().having(
            (error) => error.message,
            'message',
            allOf([
              contains('community content after signing in as Garden Member 1'),
              contains('TEST_POST_SIGN_IN_STALL_DIAGNOSTIC'),
              isNot(contains('(not captured)')),
            ]),
          ),
        ),
      );
      expect(capturedFrameNames, ['TEST_POST_SIGN_IN_STALL_DIAGNOSTIC']);
    },
  );
}
