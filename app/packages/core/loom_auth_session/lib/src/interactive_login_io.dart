import 'package:flutter/foundation.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:openid_client/openid_client.dart';

import 'auth_exceptions.dart';
import 'interactive_authorization.dart';
import 'interactive_login_transaction.dart';
import 'secure_storage_backend.dart';

/// Launches Android's authorization browser and completes its PKCE callback.
///
/// This source file is selected for Dart IO targets. It rejects every IO target
/// other than Android so unsupported platforms continue to fail explicitly.
final class InteractiveLoginPlatform {
  InteractiveLoginPlatform({
    required Uri? issuerUri,
    required String clientId,
    required http.Client httpClient,
    required Future<void> Function(Map<String, dynamic>) persistTokens,
    required LoomAuthSecureStorageBackend pendingTransactionStorage,
    Future<Uri> Function(Uri authorizationUri)? authorizationLauncher,
    Future<Uri?> Function()? callbackReader,
  }) : _issuerUri = issuerUri,
       _clientId = clientId,
       _httpClient = httpClient,
       _persistTokens = persistTokens,
       _pendingTransactionStorage = pendingTransactionStorage,
       _authorizationLauncher =
           authorizationLauncher ?? _launchAuthorizationInBrowser,
       _callbackReader = callbackReader ?? _noPendingCallback;

  static const String transactionStorageKey =
      'loom.auth_session.interactive_login.v1';
  static final Uri _redirectUri = Uri.parse(
    'com.loom.communities:/oauthredirect',
  );

  final Uri? _issuerUri;
  final String _clientId;
  final http.Client _httpClient;
  final Future<void> Function(Map<String, dynamic>) _persistTokens;
  final LoomAuthSecureStorageBackend _pendingTransactionStorage;
  final Future<Uri> Function(Uri authorizationUri) _authorizationLauncher;
  final Future<Uri?> Function() _callbackReader;

  Future<void> start({
    List<String> scopes = defaultInteractiveLoginScopes,
  }) async {
    _requireAndroid();
    final issuer = await _discoverIssuer();
    final request = LoomInteractiveAuthorizationRequest.create(
      client: Client(issuer, _clientId, httpClient: _httpClient),
      redirectUri: _redirectUri,
      scopes: scopes,
    );
    final transaction = InteractiveLoginTransaction(
      state: request.state,
      codeVerifier: request.codeVerifier,
      redirectUri: _redirectUri,
      scopes: scopes,
    );
    await _writeTransaction(transaction);

    final Uri callbackUri;
    try {
      callbackUri = await _authorizationLauncher(request.authorizationUri);
    } on Object {
      await _deleteTransaction();
      throw const LoomAuthInteractiveLoginException(
        message: 'Secure sign-in was cancelled or could not be completed.',
        oauthError: 'authorization_cancelled',
      );
    }
    await _completeCallback(callbackUri);
  }

  /// Android callbacks are delivered to the in-flight browser authorization.
  /// A cold app start has no callback to consume, so it is not an error.
  Future<bool> complete() async {
    _requireAndroid();
    final callbackUri = await _callbackReader();
    if (callbackUri == null) return false;
    await _completeCallback(callbackUri);
    return true;
  }

  Future<void> _completeCallback(Uri callbackUri) async {
    if (!_isOurRedirectUri(callbackUri)) {
      throw const LoomAuthStateMismatchException();
    }
    final transaction = await _readTransaction();
    if (transaction == null) {
      throw const LoomAuthStateMismatchException();
    }

    final callback = callbackUri.queryParameters;
    validateInteractiveLoginState(
      expectedState: transaction.state,
      callbackState: callback['state'],
    );

    // Both the OAuth code and its verifier are single-use. Delete the
    // transaction before processing either a provider error or a code.
    await _deleteTransaction();

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

    try {
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
    } on LoomAuthSessionException {
      rethrow;
    } on Object {
      throw const LoomAuthInteractiveLoginException(
        message: 'Secure sign-in could not be completed. Please try again.',
        oauthError: 'authorization_exchange_failed',
      );
    }
  }

  Future<InteractiveLoginTransaction?> _readTransaction() async {
    final String? encoded;
    try {
      encoded = await _pendingTransactionStorage.read(
        key: transactionStorageKey,
      );
    } on Exception catch (error) {
      throw LoomAuthStorageException(
        'Failed to read the pending interactive login: $error',
      );
    }
    return encoded == null
        ? null
        : InteractiveLoginTransaction.fromJson(encoded);
  }

  Future<void> _writeTransaction(
    InteractiveLoginTransaction transaction,
  ) async {
    try {
      await _pendingTransactionStorage.write(
        key: transactionStorageKey,
        value: transaction.toJson(),
      );
    } on Exception catch (error) {
      throw LoomAuthStorageException(
        'Failed to store the pending interactive login: $error',
      );
    }
  }

  Future<void> _deleteTransaction() async {
    try {
      await _pendingTransactionStorage.delete(key: transactionStorageKey);
    } on Exception catch (error) {
      throw LoomAuthStorageException(
        'Failed to clear the pending interactive login: $error',
      );
    }
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

  static Future<Uri> _launchAuthorizationInBrowser(Uri authorizationUri) async {
    final callback = await FlutterWebAuth2.authenticate(
      url: authorizationUri.toString(),
      callbackUrlScheme: _redirectUri.scheme,
    );
    return Uri.parse(callback);
  }

  static Future<Uri?> _noPendingCallback() async => null;

  static bool _isOurRedirectUri(Uri callbackUri) =>
      callbackUri.scheme == _redirectUri.scheme &&
      callbackUri.host == _redirectUri.host &&
      callbackUri.path == _redirectUri.path &&
      callbackUri.port == _redirectUri.port;

  static void _requireAndroid() {
    if (defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError(
        'Interactive Loom login is currently supported only on Flutter Web '
        'and Android.',
      );
    }
  }
}
