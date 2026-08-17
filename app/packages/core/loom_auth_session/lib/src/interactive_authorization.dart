import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:openid_client/openid_client.dart';

import 'auth_exceptions.dart';

const List<String> defaultInteractiveLoginScopes = <String>[
  'openid',
  'profile',
  'email',
];

/// The authorization-code request state that must survive a browser redirect.
final class LoomInteractiveAuthorizationRequest {
  LoomInteractiveAuthorizationRequest._({
    required this.flow,
    required this.codeVerifier,
  });

  final Flow flow;
  final String codeVerifier;

  String get state => flow.state;
  Uri get authorizationUri => flow.authenticationUri;

  static LoomInteractiveAuthorizationRequest create({
    required Client client,
    required Uri redirectUri,
    List<String> scopes = defaultInteractiveLoginScopes,
    String? state,
    String? codeVerifier,
  }) {
    final verifier = codeVerifier ?? generatePkceCodeVerifier();
    final flow = Flow.authorizationCodeWithPKCE(
      client,
      state: state,
      scopes: scopes,
      codeVerifier: verifier,
    )..redirectUri = redirectUri;
    return LoomInteractiveAuthorizationRequest._(
      flow: flow,
      codeVerifier: verifier,
    );
  }

  Future<Credential> complete(Map<String, String> callbackParameters) {
    validateInteractiveLoginState(
      expectedState: state,
      callbackState: callbackParameters['state'],
    );
    return flow.callback(callbackParameters);
  }
}

/// Generates an RFC 7636 verifier using 32 cryptographically random bytes.
///
/// Unpadded base64url encoding makes the result exactly 43 characters, inside
/// the RFC's required 43-128 character range and unreserved alphabet.
String generatePkceCodeVerifier({Random? random}) {
  final secureRandom = random ?? Random.secure();
  final bytes = List<int>.generate(32, (_) => secureRandom.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

/// Derives the RFC 7636 `S256` challenge for [codeVerifier].
String derivePkceS256Challenge(String codeVerifier) => base64UrlEncode(
  sha256.convert(utf8.encode(codeVerifier)).bytes,
).replaceAll('=', '');

/// Rejects missing and forged callback state before any code exchange occurs.
void validateInteractiveLoginState({
  required String expectedState,
  required String? callbackState,
}) {
  if (callbackState == null || callbackState != expectedState) {
    throw const LoomAuthStateMismatchException();
  }
}
