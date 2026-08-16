/// Minimal secure key/value storage needed by [LoomAuthSession].
///
/// Keeping this as an interface lets unit tests use an in-memory fake while
/// production Flutter code supplies [FlutterSecureStorageBackend].
abstract interface class LoomAuthSecureStorageBackend {
  Future<String?> read({required String key});

  Future<void> write({required String key, required String value});

  Future<void> delete({required String key});
}
