part of '../loom_communities_app_shell.dart';

/// A member's recorded place in an item's queue.
final class LoomItemQueueEntry {
  const LoomItemQueueEntry({
    required this.fanId,
    required this.position,
    required this.joinedAt,
    this.offeredAt,
    this.offerExpiresAt,
  });

  factory LoomItemQueueEntry.fromJson(Map<String, Object?> json) {
    final joinedAt = DateTime.tryParse(json['joinedAt'] as String? ?? '');
    final offeredAt = _optionalQueueDateTime(json['offeredAt']);
    final offerExpiresAt = _optionalQueueDateTime(json['offerExpiresAt']);
    if (json['fanId'] is! String ||
        json['position'] is! num ||
        joinedAt == null ||
        (json.containsKey('offeredAt') && offeredAt == null) ||
        (json.containsKey('offerExpiresAt') && offerExpiresAt == null)) {
      throw const FormatException('QueueEntry has an invalid response shape.');
    }
    return LoomItemQueueEntry(
      fanId: json['fanId']! as String,
      position: (json['position']! as num).toInt(),
      joinedAt: joinedAt.toUtc(),
      offeredAt: offeredAt?.toUtc(),
      offerExpiresAt: offerExpiresAt?.toUtc(),
    );
  }

  final String fanId;
  final int position;
  final DateTime joinedAt;
  final DateTime? offeredAt;
  final DateTime? offerExpiresAt;
}

/// The queue shape visible for one item.
///
/// [entries] remains nullable on purpose: the service omits it for callers
/// who do not administer the item. An empty list therefore means an
/// administrator has confirmed that nobody is waiting; null means that the
/// caller is not allowed to see who is waiting.
final class LoomItemQueue {
  const LoomItemQueue({
    required this.instanceId,
    required this.length,
    required this.viewerPosition,
    this.entries,
  });

  factory LoomItemQueue.fromJson(Map<String, Object?> json) {
    final entriesValue = json['entries'];
    if (json['instanceId'] is! String ||
        json['length'] is! num ||
        json['viewerPosition'] is! num ||
        (entriesValue != null && entriesValue is! List)) {
      throw const FormatException('ItemQueue has an invalid response shape.');
    }
    final entries = entriesValue as List?;
    return LoomItemQueue(
      instanceId: json['instanceId']! as String,
      length: (json['length']! as num).toInt(),
      viewerPosition: (json['viewerPosition']! as num).toInt(),
      entries: entries == null
          ? null
          : entries
                .map(
                  (entry) => LoomItemQueueEntry.fromJson(
                    _queueObject(entry, 'ItemQueue.entries'),
                  ),
                )
                .toList(growable: false),
    );
  }

  final String instanceId;
  final int length;

  /// The caller's one-based place, or zero when they are not queued.
  final int viewerPosition;
  final List<LoomItemQueueEntry>? entries;
}

/// A queue membership in the caller's cross-item queue view.
final class LoomQueueMembership {
  const LoomQueueMembership({
    required this.instanceId,
    required this.position,
    required this.joinedAt,
    this.itemTitle,
    this.length,
  });

  factory LoomQueueMembership.fromJson(Map<String, Object?> json) {
    final joinedAt = DateTime.tryParse(json['joinedAt'] as String? ?? '');
    if (json['instanceId'] is! String ||
        json['position'] is! num ||
        joinedAt == null ||
        (json.containsKey('itemTitle') && json['itemTitle'] is! String) ||
        (json.containsKey('length') && json['length'] is! num)) {
      throw const FormatException(
        'QueueMembership has an invalid response shape.',
      );
    }
    return LoomQueueMembership(
      instanceId: json['instanceId']! as String,
      position: (json['position']! as num).toInt(),
      joinedAt: joinedAt.toUtc(),
      itemTitle: json['itemTitle'] as String?,
      length: (json['length'] as num?)?.toInt(),
    );
  }

  final String instanceId;
  final String? itemTitle;
  final int position;
  final int? length;
  final DateTime joinedAt;
}

/// The caller and every item they are currently waiting for.
final class LoomQueueMemberships {
  const LoomQueueMemberships({required this.fanId, required this.memberships});

  factory LoomQueueMemberships.fromJson(Map<String, Object?> json) {
    final memberships = json['memberships'];
    if (json['fanId'] is! String || memberships is! List) {
      throw const FormatException(
        'Queue memberships have an invalid response shape.',
      );
    }
    return LoomQueueMemberships(
      fanId: json['fanId']! as String,
      memberships: memberships
          .map(
            (membership) => LoomQueueMembership.fromJson(
              _queueObject(membership, 'Queue memberships'),
            ),
          )
          .toList(growable: false),
    );
  }

  final String fanId;
  final List<LoomQueueMembership> memberships;
}

/// Client for the queue operations exposed by the Listing & Loan API.
///
/// Queue membership belongs to the workflow service, not the in-memory engine:
/// it is shared between members and records its durable order and join time.
/// `advanceItemQueue` is intentionally absent. Offering an item to the head of
/// a queue without notification delivery would create an invisible handoff.
final class LoomItemQueueClient {
  LoomItemQueueClient({
    required Uri workflowServiceBaseUri,
    required LoomAuthSession session,
    http.Client? httpClient,
  }) : _baseUri = _normaliseBaseUri(workflowServiceBaseUri),
       _session = session,
       _httpClient = httpClient ?? http.Client();

  final Uri _baseUri;
  final LoomAuthSession _session;
  final http.Client _httpClient;

  Future<LoomItemQueue> getItemQueue({
    required String communityId,
    required String instanceId,
  }) async {
    final response = await _send('GET', _itemQueueUri(communityId, instanceId));
    return LoomItemQueue.fromJson(_decodeQueueObject(response));
  }

  Future<LoomItemQueueEntry> joinItemQueue({
    required String communityId,
    required String instanceId,
  }) async {
    final response = await _send(
      'POST',
      _itemQueueUri(communityId, instanceId),
      expectedStatusCodes: const {200, 201},
    );
    return LoomItemQueueEntry.fromJson(_decodeQueueObject(response));
  }

  Future<void> leaveItemQueue({
    required String communityId,
    required String instanceId,
  }) => _send(
    'DELETE',
    _itemQueueUri(communityId, instanceId),
    expectedStatusCodes: const {204},
  );

  Future<void> removeFromItemQueue({
    required String communityId,
    required String instanceId,
    required String fanId,
  }) => _send(
    'DELETE',
    _itemQueueMemberUri(communityId, instanceId, fanId),
    expectedStatusCodes: const {204},
  );

  Future<LoomQueueMemberships> listMyQueueMemberships({
    required String communityId,
  }) async {
    final response = await _send('GET', _membershipsUri(communityId));
    return LoomQueueMemberships.fromJson(_decodeQueueObject(response));
  }

  void close() => _httpClient.close();

  Uri _itemQueueUri(String communityId, String instanceId) => _baseUri.resolve(
    'v1/communities/${Uri.encodeComponent(communityId)}/instances/'
    '${Uri.encodeComponent(instanceId)}/queue',
  );

  Uri _itemQueueMemberUri(
    String communityId,
    String instanceId,
    String fanId,
  ) => _baseUri.resolve(
    'v1/communities/${Uri.encodeComponent(communityId)}/instances/'
    '${Uri.encodeComponent(instanceId)}/queue/${Uri.encodeComponent(fanId)}',
  );

  Uri _membershipsUri(String communityId) => _baseUri.resolve(
    'v1/communities/${Uri.encodeComponent(communityId)}/queue-memberships',
  );

  Future<http.Response> _send(
    String method,
    Uri uri, {
    Set<int> expectedStatusCodes = const {200},
  }) async {
    final accessToken = await _session.currentAccessToken();
    final request = http.Request(method, uri)
      ..headers.addAll(<String, String>{
        'authorization': 'Bearer $accessToken',
        'accept': 'application/json',
        // The Listing & Loan API rejects composed/readable identifiers. This
        // shared helper emits an RFC 4122 version-four UUID for every call.
        'x-loom-correlation-id': _newUuidV4(),
      });
    final response = await http.Response.fromStream(
      await _httpClient.send(request),
    );
    if (!expectedStatusCodes.contains(response.statusCode)) {
      throw LoomItemQueueException(
        '$method $uri failed',
        statusCode: response.statusCode,
        body: response.body,
      );
    }
    return response;
  }
}

/// A refusal or unavailable Listing & Loan queue operation.
final class LoomItemQueueException implements Exception {
  const LoomItemQueueException(
    this.message, {
    required this.statusCode,
    required this.body,
  });

  final String message;
  final int statusCode;
  final String body;

  bool get isUnavailable => statusCode == 410 || statusCode >= 500;

  @override
  String toString() =>
      'LoomItemQueueException($statusCode): $message'
      '${body.isEmpty ? '' : ' -- $body'}';
}

DateTime? _optionalQueueDateTime(Object? value) {
  if (value == null) return null;
  if (value is! String) return null;
  return DateTime.tryParse(value);
}

Map<String, Object?> _queueObject(Object? value, String source) {
  if (value is Map) return Map<String, Object?>.from(value);
  throw FormatException('$source must be a JSON object.');
}

Map<String, Object?> _decodeQueueObject(http.Response response) {
  final decoded = jsonDecode(response.body);
  return _queueObject(decoded, 'Queue response');
}

LoomItemQueueClient? _itemQueueClientOverrideForTesting;

/// The item-queue client for this build, or null for an explicitly local build.
LoomItemQueueClient? resolveLoomItemQueueClient() {
  final override = _itemQueueClientOverrideForTesting;
  if (override != null) return override;
  final configuration = loomRemoteServiceConfiguration;
  if (configuration == null) return null;
  return LoomItemQueueClient(
    workflowServiceBaseUri: configuration.workflowServiceBaseUri,
    session: configuration.session,
  );
}

@visibleForTesting
void overrideLoomItemQueueClientForTesting(LoomItemQueueClient? client) {
  _itemQueueClientOverrideForTesting = client;
}

@visibleForTesting
void resetLoomItemQueueClientForTesting() {
  _itemQueueClientOverrideForTesting = null;
}
