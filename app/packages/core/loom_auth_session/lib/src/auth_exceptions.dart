/// Base type for failures produced by [LoomAuthSession].
abstract class LoomAuthSessionException implements Exception {
  const LoomAuthSessionException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// No locally persisted login session exists.
class LoomAuthNotLoggedInException extends LoomAuthSessionException {
  const LoomAuthNotLoggedInException()
    : super('No Loom authentication session is stored; login is required.');
}

/// The refresh token can no longer renew the session, so login is required.
class LoomAuthRefreshTokenExpiredException extends LoomAuthSessionException {
  const LoomAuthRefreshTokenExpiredException()
    : super('The Loom refresh token has expired; login is required again.');
}

/// Keycloak could not be reached for a token exchange.
class LoomAuthNetworkException extends LoomAuthSessionException {
  const LoomAuthNetworkException(super.message);
}

/// Keycloak rejected credentials supplied to the test-only login bypass.
class LoomAuthTestCredentialsRejectedException
    extends LoomAuthSessionException {
  const LoomAuthTestCredentialsRejectedException({
    required String message,
    required this.statusCode,
    this.oauthError,
  }) : super(message);

  final int statusCode;
  final String? oauthError;
}

/// Keycloak rejected a token request for a reason other than bad credentials.
class LoomAuthTokenEndpointException extends LoomAuthSessionException {
  const LoomAuthTokenEndpointException({
    required String message,
    required this.statusCode,
    this.oauthError,
  }) : super(message);

  final int statusCode;
  final String? oauthError;
}

/// Keycloak returned a successful response that did not match its token API.
class LoomAuthProtocolException extends LoomAuthSessionException {
  const LoomAuthProtocolException(super.message);
}

/// The secure-storage backend could not read, write, or clear session state.
class LoomAuthStorageException extends LoomAuthSessionException {
  const LoomAuthStorageException(super.message);
}
