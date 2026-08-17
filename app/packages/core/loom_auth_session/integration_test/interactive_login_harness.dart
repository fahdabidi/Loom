import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:loom_auth_session/loom_auth_session.dart';
import 'package:web/web.dart' as web;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SemanticsBinding.instance.ensureSemantics();
  runApp(const _InteractiveLoginHarness());
}

final class _InteractiveLoginHarness extends StatefulWidget {
  const _InteractiveLoginHarness();

  @override
  State<_InteractiveLoginHarness> createState() =>
      _InteractiveLoginHarnessState();
}

final class _InteractiveLoginHarnessState
    extends State<_InteractiveLoginHarness> {
  late final LoomAuthSession _session;
  String _status = 'Checking for an authorization callback…';
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _session = LoomAuthSession(
      tokenEndpoint: Uri.parse(
        'http://192.168.56.10:30082/realms/loom/'
        'protocol/openid-connect/token',
      ),
      clientId: 'loom-test-client',
      secureStorage: const FlutterSecureStorageBackend(FlutterSecureStorage()),
    );
    unawaited(_completeCallback());
  }

  Future<void> _completeCallback() async {
    try {
      final completed = await _session.completeInteractiveLogin();
      if (!completed) {
        setState(() {
          _ready = true;
          _status = 'Ready for interactive login';
        });
        return;
      }

      final accessToken = await _session.currentAccessToken();
      final claims = _decodeJwtClaims(accessToken);
      web.document.body!.setAttribute('data-loom-access-token', accessToken);
      setState(() {
        _status = 'Authenticated fanId: ${claims['fanId']}';
      });
    } on Object catch (error) {
      setState(() {
        _status = 'Interactive login failed: $error';
      });
    }
  }

  Future<void> _startLogin() async {
    setState(() {
      _ready = false;
      _status = 'Redirecting to Keycloak…';
    });
    try {
      await _session.loginInteractively();
    } on Object catch (error) {
      setState(() {
        _ready = true;
        _status = 'Interactive login failed: $error';
      });
    }
  }

  @override
  void dispose() {
    _session.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_ready)
              Semantics(
                identifier: 'loom-login-trigger',
                button: true,
                child: ElevatedButton(
                  onPressed: () => unawaited(_startLogin()),
                  child: const Text('Sign in with Keycloak'),
                ),
              )
            else
              const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Semantics(identifier: 'loom-login-status', child: Text(_status)),
          ],
        ),
      ),
    ),
  );
}

Map<String, dynamic> _decodeJwtClaims(String token) {
  final parts = token.split('.');
  if (parts.length != 3) {
    throw const FormatException('Keycloak access token is not a compact JWT');
  }
  final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
  final decoded = jsonDecode(payload);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Keycloak JWT claims are not a JSON object');
  }
  return decoded;
}
