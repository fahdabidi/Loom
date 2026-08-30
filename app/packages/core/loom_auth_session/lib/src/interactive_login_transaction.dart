import 'dart:convert';

import 'auth_exceptions.dart';

/// The PKCE state that must survive an interactive authorization redirect.
final class InteractiveLoginTransaction {
  const InteractiveLoginTransaction({
    required this.state,
    required this.codeVerifier,
    required this.redirectUri,
    required this.scopes,
  });

  final String state;
  final String codeVerifier;
  final Uri redirectUri;
  final List<String> scopes;

  factory InteractiveLoginTransaction.fromJson(String encoded) {
    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException {
      throw const LoomAuthProtocolException(
        'The pending interactive login transaction is malformed.',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const LoomAuthProtocolException(
        'The pending interactive login transaction is malformed.',
      );
    }
    final state = decoded['state'];
    final codeVerifier = decoded['code_verifier'];
    final redirectUriValue = decoded['redirect_uri'];
    final scopesValue = decoded['scopes'];
    final redirectUri = redirectUriValue is String
        ? Uri.tryParse(redirectUriValue)
        : null;
    if (state is! String ||
        state.isEmpty ||
        codeVerifier is! String ||
        codeVerifier.isEmpty ||
        redirectUri == null ||
        !redirectUri.hasScheme ||
        scopesValue is! List ||
        scopesValue.any((scope) => scope is! String)) {
      throw const LoomAuthProtocolException(
        'The pending interactive login transaction is malformed.',
      );
    }
    return InteractiveLoginTransaction(
      state: state,
      codeVerifier: codeVerifier,
      redirectUri: redirectUri,
      scopes: scopesValue.cast<String>(),
    );
  }

  String toJson() => jsonEncode({
    'state': state,
    'code_verifier': codeVerifier,
    'redirect_uri': redirectUri.toString(),
    'scopes': scopes,
  });
}
