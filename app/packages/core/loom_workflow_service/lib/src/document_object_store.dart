import 'dart:async';
import 'dart:typed_data';

import 'package:minio/minio.dart';

/// Where a document's bytes live.
///
/// An interface rather than the MinIO client directly, so the access-control
/// tests can run without object storage. Those tests are about who may read a
/// document, and a test that needs a running MinIO to answer that question
/// would be skipped exactly when the storage is down -- which is when an
/// authorization regression is most likely to ship.
abstract interface class DocumentObjectStore {
  /// Stores [bytes] under [key], overwriting any existing object.
  Future<void> put({
    required String key,
    required List<int> bytes,
    required String contentType,
  });

  /// Reads the bytes, or `null` when the object is absent.
  ///
  /// Absent is a real state rather than an error: the metadata row and the
  /// object are written in that order, so a crash between them leaves a
  /// document whose bytes never arrived. The caller reports that honestly
  /// instead of serving an empty file.
  Future<Uint8List?> get(String key);

  /// Removes the object. Removing one that is already gone is not an error.
  Future<void> delete(String key);
}

/// Object storage backed by MinIO, or any S3-compatible endpoint.
class MinioDocumentObjectStore implements DocumentObjectStore {
  MinioDocumentObjectStore({required Minio client, required String bucket})
    : _client = client,
      _bucket = bucket;

  /// Builds a store from the deployment's configuration.
  ///
  /// [endpoint] is a host, not a URL -- the MinIO client takes the scheme
  /// separately through [useSsl]. Passing "http://minio:9000" here produces a
  /// client that resolves a host literally named "http://minio", which fails as
  /// a DNS error rather than as a configuration one.
  factory MinioDocumentObjectStore.fromConfiguration({
    required String endpoint,
    required int port,
    required String accessKey,
    required String secretKey,
    required String bucket,
    bool useSsl = false,
  }) => MinioDocumentObjectStore(
    client: Minio(
      endPoint: endpoint,
      port: port,
      accessKey: accessKey,
      secretKey: secretKey,
      useSSL: useSsl,
    ),
    bucket: bucket,
  );

  final Minio _client;
  final String _bucket;

  /// Creates the bucket when it does not exist yet.
  ///
  /// Called at startup rather than on first upload. A bucket created lazily
  /// would make the first upload after a fresh deployment slower and racier
  /// than every later one, and would surface a misconfigured endpoint as a
  /// failed member action instead of a failed boot.
  Future<void> ensureBucket() async {
    if (await _client.bucketExists(_bucket)) return;
    await _client.makeBucket(_bucket);
  }

  @override
  Future<void> put({
    required String key,
    required List<int> bytes,
    required String contentType,
  }) async {
    await _client.putObject(
      _bucket,
      key,
      Stream<Uint8List>.value(Uint8List.fromList(bytes)),
      size: bytes.length,
      metadata: {'content-type': contentType},
    );
  }

  @override
  Future<Uint8List?> get(String key) async {
    final MinioByteStream stream;
    try {
      stream = await _client.getObject(_bucket, key);
    } on MinioError catch (error) {
      if (_isNotFound(error)) return null;
      rethrow;
    }
    final builder = BytesBuilder(copy: false);
    await for (final chunk in stream) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _client.removeObject(_bucket, key);
    } on MinioError catch (error) {
      if (_isNotFound(error)) return;
      rethrow;
    }
  }

  // MinioError does not model "no such key" as a distinct type, so the message
  // is all there is to match on. Kept narrow deliberately: treating every
  // MinioError as absence would turn a credentials failure into a silent 404
  // and make a broken deployment look like an empty library.
  static bool _isNotFound(MinioError error) {
    final message = error.message?.toLowerCase() ?? '';
    return message.contains('not exist') ||
        message.contains('nosuchkey') ||
        message.contains('not found');
  }
}

/// The object key for a document.
///
/// Built only from ids the service generated. The uploaded filename never
/// appears: a member chooses it, and a member-chosen string in a path is how a
/// key ends up somewhere the community it belongs to cannot reach, or somewhere
/// another community can.
String documentObjectKey({
  required String communityId,
  required String instanceId,
  required String documentId,
}) => 'communities/$communityId/instances/$instanceId/$documentId';
