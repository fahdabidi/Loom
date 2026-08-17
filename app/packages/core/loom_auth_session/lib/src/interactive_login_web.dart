import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:http/http.dart' as http;
import 'package:openid_client/openid_client.dart';
import 'package:web/web.dart' hide Client;

import 'auth_exceptions.dart';
import 'interactive_authorization.dart';

final class InteractiveLoginPlatform {
  InteractiveLoginPlatform({
    required Uri? issuerUri,
    required String clientId,
    required http.Client httpClient,
    required Future<void> Function(Map<String, dynamic>) persistTokens,
  }) : _issuerUri = issuerUri,
       _clientId = clientId,
       _httpClient = httpClient,
       _persistTokens = persistTokens;

  static const String _transactionStorageKey =
      'loom.auth_session.interactive_login.v1';

  final Uri? _issuerUri;
  final String _clientId;
  final http.Client _httpClient;
  final Future<void> Function(Map<String, dynamic>) _persistTokens;

  Future<void> start({
    List<String> scopes = defaultInteractiveLoginScopes,
  }) async {
    final issuer = await _discoverIssuer();
    final redirectUri = _currentRedirectUri();
    final request = LoomInteractiveAuthorizationRequest.create(
      client: Client(issuer, _clientId, httpClient: _httpClient),
      redirectUri: redirectUri,
      scopes: scopes,
    );
    final transaction = _InteractiveLoginTransaction(
      state: request.state,
      codeVerifier: request.codeVerifier,
      redirectUri: redirectUri,
      scopes: scopes,
    );
    window.sessionStorage.setItem(_transactionStorageKey, transaction.toJson());
    window.location.href = request.authorizationUri.toString();

    // A successful assignment unloads this page. Keeping the Future pending
    // prevents callers from treating redirect initiation as a completed login.
    await Completer<void>().future;
  }

  Future<bool> complete() async {
    final callbackUri = Uri.parse(window.location.href);
    final callback = callbackUri.queryParameters;
    if (!callback.containsKey('code') && !callback.containsKey('error')) {
      return false;
    }

    final encodedTransaction = window.sessionStorage.getItem(
      _transactionStorageKey,
    );
    if (encodedTransaction == null) {
      throw const LoomAuthStateMismatchException();
    }
    final transaction = _InteractiveLoginTransaction.fromJson(
      encodedTransaction,
    );
    validateInteractiveLoginState(
      expectedState: transaction.state,
      callbackState: callback['state'],
    );

    // State is single-use. Remove it before exchanging the single-use code so
    // a refresh or replay cannot attempt the same callback again.
    window.sessionStorage.removeItem(_transactionStorageKey);

    final oauthError = callback['error'];
    if (oauthError != null) {
      throw LoomAuthInteractiveLoginException(
        message:
            callback['error_description'] ??
            'Keycloak rejected the interactive authorization request.',
        oauthError: oauthError,
      );
    }
    if (!callback.containsKey('code')) {
      throw const LoomAuthProtocolException(
        'Keycloak authorization callback did not contain a code.',
      );
    }

    final issuer = await _discoverIssuer();
    final request = LoomInteractiveAuthorizationRequest.create(
      client: Client(issuer, _clientId, httpClient: _httpClient),
      redirectUri: transaction.redirectUri,
      scopes: transaction.scopes,
      state: transaction.state,
      codeVerifier: transaction.codeVerifier,
    );
    final credential = await request.complete(callback);
    final tokens = credential.response;
    if (tokens == null) {
      throw const LoomAuthProtocolException(
        'The authorization-code exchange returned no token response.',
      );
    }
    await _persistTokens(tokens);

    window.history.replaceState(
      ''.toJS,
      '',
      transaction.redirectUri.toString(),
    );
    return true;
  }

  Future<Issuer> _discoverIssuer() {
    final issuerUri = _issuerUri;
    if (issuerUri == null) {
      throw const LoomAuthProtocolException(
        'Interactive login requires a Keycloak token endpoint ending in '
        '/protocol/openid-connect/token.',
      );
    }
    return Issuer.discover(issuerUri, httpClient: _httpClient);
  }

  static Uri _currentRedirectUri() {
    final current = Uri.parse(window.location.href);
    return Uri(
      scheme: current.scheme,
      userInfo: current.userInfo,
      host: current.host,
      port: current.hasPort ? current.port : null,
      path: current.path,
    );
  }
}

final class _InteractiveLoginTransaction {
  const _InteractiveLoginTransaction({
    required this.state,
    required this.codeVerifier,
    required this.redirectUri,
    required this.scopes,
  });

  final String state;
  final String codeVerifier;
  final Uri redirectUri;
  final List<String> scopes;

  factory _InteractiveLoginTransaction.fromJson(String encoded) {
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
    return _InteractiveLoginTransaction(
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
