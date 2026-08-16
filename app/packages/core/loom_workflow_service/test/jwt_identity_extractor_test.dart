import 'package:jose/jose.dart';
import 'package:loom_workflow_service/loom_workflow_service.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const _expectedIssuer = 'https://identity.test/realms/loom';

void main() {
  late JsonWebKey trustedKey;
  late JsonWebKey otherKey;
  late JsonWebKey rotatedKey;
  late List<JsonWebKey> servedKeys;
  late int jwksRequestCount;
  late JwtWorkflowIdentityExtractor extractor;

  setUpAll(() {
    trustedKey = _generateRsaKey('trusted-key');
    otherKey = _generateRsaKey('other-key');
    rotatedKey = _generateRsaKey('rotated-key');
  });

  setUp(() {
    servedKeys = <JsonWebKey>[trustedKey];
    jwksRequestCount = 0;
    extractor = JwtWorkflowIdentityExtractor(
      jwksUri: Uri.parse('https://identity.test/realms/loom/certs'),
      expectedIssuer: _expectedIssuer,
      jwksFetcher: (uri) async {
        jwksRequestCount++;
        return {'keys': servedKeys.map(_publicJwk).toList()};
      },
    );
  });

  tearDown(() {
    extractor.close(force: true);
  });

  test('accepts a valid token and extracts its fanId claim', () async {
    final token = _token(trustedKey, _validClaims(fanId: 'fan_88ecc45f-test'));

    final identity = await extractor.extract(_request(token));

    expect(identity?.fanId, 'fan_88ecc45f-test');
  });

  test('returns null for a validly-signed token with no fanId claim', () async {
    final token = _token(trustedKey, _validClaims());

    final identity = await extractor.extract(_request(token));

    expect(identity, isNull);
  });

  test(
    'returns null for a validly-signed token with an empty fanId claim',
    () async {
      final token = _token(trustedKey, _validClaims(fanId: ''));

      final identity = await extractor.extract(_request(token));

      expect(identity, isNull);
    },
  );

  test('returns null for an expired token', () async {
    final now = DateTime.now();
    final token = _token(
      trustedKey,
      _validClaims(
        fanId: 'fan_expired',
        expiry: now.subtract(const Duration(minutes: 1)),
        notBefore: now.subtract(const Duration(minutes: 10)),
      ),
    );

    final identity = await extractor.extract(_request(token));

    expect(identity, isNull);
  });

  test('returns null for a not-yet-valid token', () async {
    final now = DateTime.now();
    final token = _token(
      trustedKey,
      _validClaims(
        fanId: 'fan_too_early',
        expiry: now.add(const Duration(minutes: 10)),
        notBefore: now.add(const Duration(minutes: 5)),
      ),
    );

    final identity = await extractor.extract(_request(token));

    expect(identity, isNull);
  });

  test('returns null for a token signed with a different key', () async {
    final wrongSigningKey = _copyWithKeyId(otherKey, trustedKey.keyId!);
    final token = _token(
      wrongSigningKey,
      _validClaims(fanId: 'fan_bad_signature'),
    );

    final identity = await extractor.extract(_request(token));

    expect(identity, isNull);
  });

  test('returns null for a token with the wrong issuer', () async {
    final token = _token(
      trustedKey,
      _validClaims(
        fanId: 'fan_wrong_issuer',
        issuer: 'https://identity.test/realms/not-loom',
      ),
    );

    final identity = await extractor.extract(_request(token));

    expect(identity, isNull);
  });

  test('returns null when the Authorization header is absent', () async {
    final request = Request('GET', Uri.parse('http://workflow.test/guarded'));

    final identity = await extractor.extract(request);

    expect(identity, isNull);
  });

  test('returns null when the Authorization header is malformed', () async {
    final request = Request(
      'GET',
      Uri.parse('http://workflow.test/guarded'),
      headers: const {'authorization': 'Basic definitely-not-a-jwt'},
    );

    final identity = await extractor.extract(request);

    expect(identity, isNull);
  });

  test('returns null for a malformed bearer token', () async {
    final identity = await extractor.extract(_request('not-a-jwt'));

    expect(identity, isNull);
    expect(jwksRequestCount, 0);
  });

  test('reuses a cached JWKS for repeated requests', () async {
    final token = _token(trustedKey, _validClaims(fanId: 'fan_cached'));

    final first = await extractor.extract(_request(token));
    final second = await extractor.extract(_request(token));

    expect(first?.fanId, 'fan_cached');
    expect(second?.fanId, 'fan_cached');
    expect(jwksRequestCount, 1);
  });

  test('refreshes a fresh JWKS cache when kid is unknown', () async {
    final initialToken = _token(
      trustedKey,
      _validClaims(fanId: 'fan_before_rotation'),
    );
    final rotatedToken = _token(
      rotatedKey,
      _validClaims(fanId: 'fan_after_rotation'),
    );
    final initialIdentity = await extractor.extract(_request(initialToken));
    servedKeys = <JsonWebKey>[rotatedKey];
    final rotatedIdentity = await extractor.extract(_request(rotatedToken));

    expect(initialIdentity?.fanId, 'fan_before_rotation');
    expect(rotatedIdentity?.fanId, 'fan_after_rotation');
    expect(jwksRequestCount, 2);
  });
}

JsonWebKey _generateRsaKey(String keyId) {
  final generated = JsonWebKey.generate('RS256');
  return _copyWithKeyId(generated, keyId);
}

JsonWebKey _copyWithKeyId(JsonWebKey key, String keyId) {
  return JsonWebKey.fromJson({
    ...key.toJson(),
    'kid': keyId,
    'alg': 'RS256',
    'use': 'sig',
  });
}

Map<String, dynamic> _publicJwk(JsonWebKey key) {
  final json = key.toJson();
  return {
    'kty': json['kty'],
    'kid': json['kid'],
    'alg': json['alg'],
    'use': json['use'],
    'n': json['n'],
    'e': json['e'],
  };
}

Map<String, dynamic> _validClaims({
  String? fanId,
  String issuer = _expectedIssuer,
  DateTime? expiry,
  DateTime? notBefore,
}) {
  final now = DateTime.now();
  return {
    'iss': issuer,
    // This deliberately exists in the no-fanId case to prove there is no
    // fallback from Keycloak's internal subject to Loom's fan identity.
    'sub': 'keycloak-internal-user-uuid',
    'exp': _secondsSinceEpoch(expiry ?? now.add(const Duration(minutes: 5))),
    'nbf': _secondsSinceEpoch(
      notBefore ?? now.subtract(const Duration(minutes: 1)),
    ),
    if (fanId != null) 'fanId': fanId,
  };
}

int _secondsSinceEpoch(DateTime value) =>
    value.millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond;

String _token(JsonWebKey signingKey, Map<String, dynamic> claims) {
  final builder = JsonWebSignatureBuilder()
    ..jsonContent = claims
    ..setProtectedHeader('typ', 'JWT')
    ..addRecipient(signingKey, algorithm: 'RS256');
  return builder.build().toCompactSerialization();
}

Request _request(String token) {
  return Request(
    'GET',
    Uri.parse('http://workflow.test/guarded'),
    headers: {'authorization': 'Bearer $token'},
  );
}
