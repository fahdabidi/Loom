import 'package:http/http.dart' as http;

import 'interactive_login_stub.dart';
import 'secure_storage_backend.dart';

export 'interactive_login_stub.dart' show InteractiveLoginPlatform;

const String interactiveLoginPlatformKind = 'unsupported';

InteractiveLoginPlatform createInteractiveLoginPlatform({
  required Uri? issuerUri,
  required String clientId,
  required http.Client httpClient,
  required Future<void> Function(Map<String, dynamic>) persistTokens,
  required LoomAuthSecureStorageBackend pendingTransactionStorage,
}) => InteractiveLoginPlatform(
  issuerUri: issuerUri,
  clientId: clientId,
  httpClient: httpClient,
  persistTokens: persistTokens,
);
