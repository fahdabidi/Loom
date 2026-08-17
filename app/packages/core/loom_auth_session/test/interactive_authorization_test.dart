import 'package:loom_auth_session/src/auth_exceptions.dart';
import 'package:loom_auth_session/src/interactive_authorization.dart';
import 'package:openid_client/openid_client.dart';
import 'package:test/test.dart';

void main() {
  test('PKCE verifier has RFC 7636 length and unreserved encoding', () {
    final verifier = generatePkceCodeVerifier();

    expect(verifier, hasLength(43));
    expect(verifier, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
    expect(verifier, isNot(contains('=')));
  });

  test('S256 derivation matches the RFC 7636 known vector', () {
    const verifier = 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk';

    expect(
      derivePkceS256Challenge(verifier),
      'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM',
    );
  });

  test('authorization URL contains code, PKCE, state, and redirect data', () {
    const verifier = 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk';
    final redirectUri = Uri.parse('http://localhost:7357/');
    final request = LoomInteractiveAuthorizationRequest.create(
      client: _client(),
      redirectUri: redirectUri,
      state: 'csrf-state',
      codeVerifier: verifier,
    );

    expect(
      '${request.authorizationUri.origin}${request.authorizationUri.path}',
      'https://identity.test/realms/loom/protocol/openid-connect/auth',
    );
    expect(request.authorizationUri.queryParameters, {
      'response_type': 'code',
      'scope': 'openid profile email',
      'client_id': 'loom-test-client',
      'redirect_uri': redirectUri.toString(),
      'state': 'csrf-state',
      'code_challenge_method': 'S256',
      'code_challenge': 'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM',
    });
  });

  test('forged callback state is rejected before code exchange', () {
    expect(
      () => validateInteractiveLoginState(
        expectedState: 'expected-state',
        callbackState: 'forged-state',
      ),
      throwsA(isA<LoomAuthStateMismatchException>()),
    );
  });

  test('missing callback state is rejected before code exchange', () {
    expect(
      () => validateInteractiveLoginState(
        expectedState: 'expected-state',
        callbackState: null,
      ),
      throwsA(isA<LoomAuthStateMismatchException>()),
    );
  });
}

Client _client() => Client(
  Issuer(
    OpenIdProviderMetadata.fromJson({
      'issuer': 'https://identity.test/realms/loom',
      'authorization_endpoint':
          'https://identity.test/realms/loom/protocol/openid-connect/auth',
      'token_endpoint':
          'https://identity.test/realms/loom/protocol/openid-connect/token',
      'response_types_supported': ['code'],
      'subject_types_supported': ['public'],
      'id_token_signing_alg_values_supported': ['RS256'],
      'scopes_supported': ['openid', 'profile', 'email'],
    }),
  ),
  'loom-test-client',
);
