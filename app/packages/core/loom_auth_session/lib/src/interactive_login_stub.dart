import 'package:http/http.dart' as http;

import 'interactive_authorization.dart';

final class InteractiveLoginPlatform {
  InteractiveLoginPlatform({
    required Uri? issuerUri,
    required String clientId,
    required http.Client httpClient,
    required Future<void> Function(Map<String, dynamic>) persistTokens,
  });

  Future<void> start({List<String> scopes = defaultInteractiveLoginScopes}) =>
      Future<void>.error(
        UnsupportedError(
          'Interactive Loom login is currently supported only on Flutter Web.',
        ),
      );

  Future<bool> complete() => Future<bool>.error(
    UnsupportedError(
      'Interactive Loom login is currently supported only on Flutter Web.',
    ),
  );
}
