import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_auth_session/loom_auth_session.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';

final class _MemorySecureStorage implements LoomAuthSecureStorageBackend {
  @override
  Future<void> delete({required String key}) async {}

  @override
  Future<String?> read({required String key}) async => null;

  @override
  Future<void> write({required String key, required String value}) async {}
}

final class _InteractiveFakeLoomAuthSession extends LoomAuthSession {
  _InteractiveFakeLoomAuthSession({
    this.completionResult = false,
    this.completionError,
    this.loginError,
    this.loginCompletes = false,
  }) : super(
         tokenEndpoint: Uri.parse(
           'https://identity.test/realms/loom/protocol/openid-connect/token',
         ),
         clientId: 'test-client',
         secureStorage: _MemorySecureStorage(),
       );

  final bool completionResult;
  final Object? completionError;
  final Object? loginError;
  final bool loginCompletes;
  int loginCalls = 0;

  @override
  Future<bool> completeInteractiveLogin() async {
    final error = completionError;
    if (error != null) throw error;
    return completionResult;
  }

  @override
  Future<void> loginInteractively({List<String>? scopes}) async {
    loginCalls += 1;
    final error = loginError;
    if (error != null) throw error;
    if (!loginCompletes) await Completer<void>().future;
  }
}

void main() {
  testWidgets(
    'real sign-in action invokes loginInteractively and stays pending',
    (tester) async {
      final session = _InteractiveFakeLoomAuthSession();
      await tester.pumpWidget(
        MaterialApp(home: LoomProductionLoginScreen(session: session)),
      );
      await tester.pump();

      expect(find.text('Sign in to Loom'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('production-login-button')));
      await tester.pump();

      expect(session.loginCalls, 1);
      expect(find.text('Opening secure sign-in'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    },
  );

  testWidgets('completed Android sign-in reports success to the member', (
    tester,
  ) async {
    var successCalls = 0;
    final session = _InteractiveFakeLoomAuthSession(loginCompletes: true);
    await tester.pumpWidget(
      MaterialApp(
        home: LoomProductionLoginScreen(
          session: session,
          onLoginSucceeded: () => successCalls += 1,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('production-login-button')));
    await tester.pump();

    expect(session.loginCalls, 1);
    expect(find.text('You’re signed in'), findsOneWidget);
    expect(successCalls, 1);
  });

  testWidgets('unsupported interactive platform renders an honest state', (
    tester,
  ) async {
    final session = _InteractiveFakeLoomAuthSession(
      completionError: UnsupportedError('web only'),
    );
    await tester.pumpWidget(
      MaterialApp(home: LoomProductionLoginScreen(session: session)),
    );
    await tester.pump();

    expect(
      find.text('Secure sign-in is not supported on this platform yet'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Interactive identity-provider sign-in is currently available in Loom '
        'on the web and Android.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('production-login-button')), findsNothing);
  });

  testWidgets('unsupported sign-in action cannot crash or silently fall back', (
    tester,
  ) async {
    final session = _InteractiveFakeLoomAuthSession(
      loginError: UnsupportedError('web only'),
    );
    await tester.pumpWidget(
      MaterialApp(home: LoomProductionLoginScreen(session: session)),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('production-login-button')));
    await tester.pump();

    expect(session.loginCalls, 1);
    expect(
      find.text('Secure sign-in is not supported on this platform yet'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('production-login-button')), findsNothing);
  });

  testWidgets('completed redirect renders success and notifies the caller', (
    tester,
  ) async {
    var successCalls = 0;
    final session = _InteractiveFakeLoomAuthSession(completionResult: true);
    await tester.pumpWidget(
      MaterialApp(
        home: LoomProductionLoginScreen(
          session: session,
          onLoginSucceeded: () => successCalls += 1,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('You’re signed in'), findsOneWidget);
    expect(successCalls, 1);
  });

  testWidgets('identity-provider error surfaces its real message', (
    tester,
  ) async {
    final session = _InteractiveFakeLoomAuthSession(
      completionError: const LoomAuthInteractiveLoginException(
        message: 'Your organization denied this sign-in request.',
        oauthError: 'access_denied',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: LoomProductionLoginScreen(session: session)),
    );
    await tester.pump();

    expect(find.text('We couldn’t sign you in'), findsOneWidget);
    expect(
      find.text('Your organization denied this sign-in request.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('LoomAuthInteractiveLoginException'),
      findsNothing,
    );
  });
}
