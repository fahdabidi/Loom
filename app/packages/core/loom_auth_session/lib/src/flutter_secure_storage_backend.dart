import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'secure_storage_backend.dart';

/// Production [LoomAuthSecureStorageBackend] backed by platform secure storage.
final class FlutterSecureStorageBackend
    implements LoomAuthSecureStorageBackend {
  const FlutterSecureStorageBackend(this.storage);

  final FlutterSecureStorage storage;

  @override
  Future<String?> read({required String key}) => storage.read(key: key);

  @override
  Future<void> write({required String key, required String value}) =>
      storage.write(key: key, value: value);

  @override
  Future<void> delete({required String key}) => storage.delete(key: key);
}
