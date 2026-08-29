part of '../loom_communities_app_shell.dart';

/// A channel through which a notification can reach a member.
///
/// `inbox` is the in-app record; `push` is the device interruption channel.
/// A muted preference retains `inbox` so a member can still read the record
/// when they choose to look at it.
enum NotificationChannel {
  inbox,
  push;

  String get wireValue => switch (this) {
    NotificationChannel.inbox => 'inbox',
    NotificationChannel.push => 'push',
  };

  static NotificationChannel fromWireValue(Object? value) => switch (value) {
    'inbox' => NotificationChannel.inbox,
    'push' => NotificationChannel.push,
    _ => throw const FormatException('Unknown notification channel.'),
  };
}

/// Whether a community preference is a member's choice or the live platform
/// default supplied because they have not made one yet.
enum NotificationPreferenceSource {
  member,
  defaultValue;

  String get wireValue => switch (this) {
    NotificationPreferenceSource.member => 'member',
    NotificationPreferenceSource.defaultValue => 'default',
  };

  static NotificationPreferenceSource fromWireValue(Object? value) =>
      switch (value) {
        'member' => NotificationPreferenceSource.member,
        'default' => NotificationPreferenceSource.defaultValue,
        _ => throw const FormatException(
          'Unknown notification preference source.',
        ),
      };
}

/// A stored preference for one workflow-community id.
///
/// A [source] of [NotificationPreferenceSource.defaultValue] is possible in a
/// response where the service represents an effective preference. The list
/// endpoint normally returns only stored entries, while [platformDefault]
/// separately supplies the value to use when an entry is absent.
final class CommunityNotificationPreference {
  CommunityNotificationPreference({
    required this.communityId,
    required List<NotificationChannel> channels,
    required this.muted,
    required this.source,
    this.updatedAt,
  }) : channels = List<NotificationChannel>.unmodifiable(channels) {
    if (communityId.isEmpty) {
      throw ArgumentError.value(
        communityId,
        'communityId',
        'must not be empty',
      );
    }
    _validateNotificationChannels(channels);
  }

  factory CommunityNotificationPreference.fromJson(Map<String, Object?> json) {
    final updatedAtValue = json['updatedAt'];
    final updatedAt = updatedAtValue is String
        ? DateTime.tryParse(updatedAtValue)?.toUtc()
        : null;
    if (json['communityId'] is! String ||
        json['muted'] is! bool ||
        updatedAtValue != null && updatedAt == null) {
      throw const FormatException(
        'Community notification preference has an invalid response shape.',
      );
    }
    return CommunityNotificationPreference(
      communityId: json['communityId']! as String,
      channels: _notificationChannelsFromJson(json['channels']),
      muted: json['muted']! as bool,
      source: NotificationPreferenceSource.fromWireValue(json['source']),
      updatedAt: updatedAt,
    );
  }

  /// The workflow service's underscored community key.
  final String communityId;
  final List<NotificationChannel> channels;
  final bool muted;
  final NotificationPreferenceSource source;

  /// Absent when nothing has been stored for the member.
  final DateTime? updatedAt;
}

/// The value applied where a member has no stored community preference.
///
/// This deliberately has no `communityId`: it is a platform-wide default, not
/// a pseudo-preference for a fabricated community.
final class PlatformNotificationDefault {
  PlatformNotificationDefault({
    required List<NotificationChannel> channels,
    required this.muted,
  }) : channels = List<NotificationChannel>.unmodifiable(channels) {
    _validateNotificationChannels(channels);
  }

  factory PlatformNotificationDefault.fromJson(Map<String, Object?> json) {
    if (json['muted'] is! bool) {
      throw const FormatException(
        'Platform notification default has an invalid response shape.',
      );
    }
    return PlatformNotificationDefault(
      channels: _notificationChannelsFromJson(json['channels']),
      muted: json['muted']! as bool,
    );
  }

  final List<NotificationChannel> channels;
  final bool muted;
}

/// The caller's stored preferences and the platform fallback for all others.
final class NotificationPreferenceSet {
  NotificationPreferenceSet({
    required this.fanId,
    required List<CommunityNotificationPreference> preferences,
    required this.platformDefault,
  }) : preferences = List<CommunityNotificationPreference>.unmodifiable(
         preferences,
       ) {
    if (fanId.isEmpty) {
      throw ArgumentError.value(fanId, 'fanId', 'must not be empty');
    }
  }

  factory NotificationPreferenceSet.fromJson(Map<String, Object?> json) {
    final preferencesValue = json['preferences'];
    if (json['fanId'] is! String || preferencesValue is! List) {
      throw const FormatException(
        'Notification preference set has an invalid response shape.',
      );
    }
    return NotificationPreferenceSet(
      fanId: json['fanId']! as String,
      preferences: preferencesValue
          .map(
            (preference) => CommunityNotificationPreference.fromJson(
              _notificationPreferencesObject(
                preference,
                'NotificationPreferenceSet.preferences',
              ),
            ),
          )
          .toList(growable: false),
      platformDefault: PlatformNotificationDefault.fromJson(
        _notificationPreferencesObject(
          json['platformDefault'],
          'NotificationPreferenceSet.platformDefault',
        ),
      ),
    );
  }

  final String fanId;
  final List<CommunityNotificationPreference> preferences;
  final PlatformNotificationDefault platformDefault;

  /// Returns the stored entry for [communityId], if the member has one.
  CommunityNotificationPreference? storedForCommunity(String communityId) {
    for (final preference in preferences) {
      if (preference.communityId == communityId) return preference;
    }
    return null;
  }
}

/// Client for the Fan Passport notification-preference operations.
///
/// Preferences belong to the signed-in member's passport. This client does
/// not enumerate communities and never makes a local or pseudo-community
/// fallback when the service is unavailable.
final class LoomNotificationPreferencesClient {
  LoomNotificationPreferencesClient({
    required Uri fanPassportServiceBaseUri,
    required LoomAuthSession session,
    http.Client? httpClient,
  }) : _baseUri = _normaliseBaseUri(fanPassportServiceBaseUri),
       _session = session,
       _httpClient = httpClient ?? http.Client();

  final Uri _baseUri;
  final LoomAuthSession _session;
  final http.Client _httpClient;

  /// Lists only the caller's stored preferences plus the current fallback.
  Future<NotificationPreferenceSet> listNotificationPreferences({
    required String fanId,
  }) async {
    final response = await _send('GET', _preferencesUri(fanId));
    return NotificationPreferenceSet.fromJson(
      _decodeNotificationPreferencesObject(response),
    );
  }

  /// Stores the member's explicit choice for exactly one community.
  ///
  /// An empty channel list is rejected here before a request is made. The API
  /// assigns a distinct meaning to no stored preference, so silence is always
  /// written as `channels: [inbox]` with `muted: true`.
  Future<CommunityNotificationPreference> setCommunityNotificationPreference({
    required String fanId,
    required String communityId,
    required List<NotificationChannel> channels,
    required bool muted,
  }) async {
    if (communityId.isEmpty) {
      throw ArgumentError.value(
        communityId,
        'communityId',
        'must not be empty',
      );
    }
    _validateNotificationChannels(channels);
    final response = await _send(
      'PUT',
      _preferencesUri(fanId),
      body: jsonEncode(<String, Object?>{
        'communityId': communityId,
        'channels': <String>[for (final channel in channels) channel.wireValue],
        'muted': muted,
      }),
    );
    return CommunityNotificationPreference.fromJson(
      _decodeNotificationPreferencesObject(response),
    );
  }

  void close() => _httpClient.close();

  Uri _preferencesUri(String fanId) => _baseUri.resolve(
    'v1/fan-passports/${Uri.encodeComponent(fanId)}/notification-preferences',
  );

  Future<http.Response> _send(String method, Uri uri, {String? body}) async {
    final accessToken = await _session.currentAccessToken();
    final request = http.Request(method, uri)
      ..headers.addAll(<String, String>{
        'authorization': 'Bearer $accessToken',
        'accept': 'application/json',
        // Fan Passport requires an RFC 4122 v4 correlation id on both
        // operations; a readable/composed value is rejected by the service.
        'x-loom-correlation-id': _newUuidV4(),
      });
    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = body;
    }

    late final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _httpClient.send(request),
      );
    } on Exception catch (error) {
      throw NotificationPreferencesException.unavailable(
        '$method $uri could not reach Fan Passport: $error',
      );
    }
    if (response.statusCode != 200) {
      throw NotificationPreferencesException(
        '$method $uri failed',
        statusCode: response.statusCode,
        body: response.body,
      );
    }
    return response;
  }
}

/// A refusal, unavailable service, or malformed response from Fan Passport.
final class NotificationPreferencesException implements Exception {
  const NotificationPreferencesException(
    this.message, {
    required this.statusCode,
    required this.body,
  });

  const NotificationPreferencesException.unavailable(this.message)
    : statusCode = null,
      body = '';

  final String message;
  final int? statusCode;
  final String body;

  bool get isUnavailable => statusCode == null || statusCode! >= 500;

  @override
  String toString() =>
      'NotificationPreferencesException(${statusCode ?? 'unavailable'}): '
      '$message${body.isEmpty ? '' : ' -- $body'}';
}

List<NotificationChannel> _notificationChannelsFromJson(Object? value) {
  if (value is! List) {
    throw const FormatException('Notification channels must be an array.');
  }
  final channels = value
      .map(NotificationChannel.fromWireValue)
      .toList(growable: false);
  _validateNotificationChannels(channels);
  return channels;
}

void _validateNotificationChannels(List<NotificationChannel> channels) {
  if (channels.isEmpty) {
    throw ArgumentError.value(
      channels,
      'channels',
      'must not be empty; use inbox with muted: true for silence',
    );
  }
  if (channels.toSet().length != channels.length) {
    throw ArgumentError.value(
      channels,
      'channels',
      'must not contain duplicates',
    );
  }
}

Map<String, Object?> _notificationPreferencesObject(
  Object? value,
  String source,
) {
  if (value is Map) return Map<String, Object?>.from(value);
  throw FormatException('$source must be a JSON object.');
}

Map<String, Object?> _decodeNotificationPreferencesObject(
  http.Response response,
) {
  final Object? decoded;
  try {
    decoded = jsonDecode(response.body);
  } on FormatException {
    throw const FormatException(
      'Notification preferences response contains malformed JSON.',
    );
  }
  return _notificationPreferencesObject(
    decoded,
    'Notification preferences response',
  );
}

/// A self-contained picker for one community's notification preference.
///
/// It reads the caller's stored entries and the platform fallback itself. If
/// the community has no entry, the displayed values are from
/// [PlatformNotificationDefault], while the copy makes the still-unset state
/// explicit. No platform default is converted into a pseudo-community model.
final class CommunityNotificationPreferenceControl extends StatefulWidget {
  const CommunityNotificationPreferenceControl({
    super.key,
    required this.client,
    required this.fanId,
    required this.communityId,
  });

  final LoomNotificationPreferencesClient client;
  final String fanId;
  final String communityId;

  @override
  State<CommunityNotificationPreferenceControl> createState() =>
      _CommunityNotificationPreferenceControlState();
}

final class _CommunityNotificationPreferenceControlState
    extends State<CommunityNotificationPreferenceControl> {
  late Future<NotificationPreferenceSet> _load;
  bool _saving = false;
  CommunityNotificationPreference? _storedPreference;
  PlatformNotificationDefault? _platformDefault;

  @override
  void initState() {
    super.initState();
    _load = widget.client.listNotificationPreferences(fanId: widget.fanId);
  }

  @override
  void didUpdateWidget(
    covariant CommunityNotificationPreferenceControl oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.client != widget.client ||
        oldWidget.fanId != widget.fanId ||
        oldWidget.communityId != widget.communityId) {
      _storedPreference = null;
      _platformDefault = null;
      _load = widget.client.listNotificationPreferences(fanId: widget.fanId);
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<NotificationPreferenceSet>(
    future: _load,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(
          child: CircularProgressIndicator(
            key: ValueKey('notification-preferences-loading'),
          ),
        );
      }
      if (snapshot.hasError || !snapshot.hasData) {
        return const _NotificationPreferencesUnavailable();
      }

      final loaded = snapshot.data!;
      final stored =
          _storedPreference ?? loaded.storedForCommunity(widget.communityId);
      final platformDefault = _platformDefault ?? loaded.platformDefault;
      final channels = stored?.channels ?? platformDefault.channels;
      final muted = stored?.muted ?? platformDefault.muted;
      final source =
          stored?.source ?? NotificationPreferenceSource.defaultValue;
      final style = _NotificationPreferenceStyle.tryFrom(channels, muted);
      if (style == null) return const _NotificationPreferencesUnavailable();

      return Column(
        key: const ValueKey('community-notification-preference-control'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Notifications',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            source == NotificationPreferenceSource.defaultValue
                ? 'You have not chosen. You are following the platform default.'
                : 'This is your chosen notification setting.',
            key: ValueKey('notification-preference-source-${source.wireValue}'),
          ),
          const SizedBox(height: 12),
          if (_saving)
            const _NotificationPreferenceSaving()
          else
            SingleItemPreferenceControl(
              options: _NotificationPreferenceStyle.options,
              selectedValue: style.value,
              onChanged: _saveStyle,
              direction: Axis.vertical,
            ),
          if (!_saving && source == NotificationPreferenceSource.defaultValue)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton(
                key: const ValueKey('make-notification-default-my-choice'),
                onPressed: () => _saveStyle(style.value),
                child: const Text('Make this my choice'),
              ),
            ),
        ],
      );
    },
  );

  Future<void> _saveStyle(String value) async {
    final style = _NotificationPreferenceStyle.byValue(value);
    setState(() => _saving = true);
    try {
      final stored = await widget.client.setCommunityNotificationPreference(
        fanId: widget.fanId,
        communityId: widget.communityId,
        channels: style.channels,
        muted: style.muted,
      );
      if (!mounted) return;
      setState(() {
        _storedPreference = stored;
        _saving = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _load = Future<NotificationPreferenceSet>.error(
          const NotificationPreferencesException.unavailable(
            'Notification preference update failed.',
          ),
        );
      });
    }
  }
}

final class _NotificationPreferencesUnavailable extends StatelessWidget {
  const _NotificationPreferencesUnavailable();

  @override
  Widget build(BuildContext context) => const Text(
    'Notification preferences are unavailable.',
    key: ValueKey('notification-preferences-unavailable'),
  );
}

final class _NotificationPreferenceSaving extends StatelessWidget {
  const _NotificationPreferenceSaving();

  @override
  Widget build(BuildContext context) => const Row(
    children: <Widget>[
      SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      SizedBox(width: 8),
      Text('Saving notification preference…'),
    ],
  );
}

final class _NotificationPreferenceStyle {
  const _NotificationPreferenceStyle({
    required this.value,
    required this.label,
    required this.channels,
    required this.muted,
  });

  static const inAppAndDevice = _NotificationPreferenceStyle(
    value: 'in-app-and-device',
    label: 'In the app and on my device',
    channels: <NotificationChannel>[
      NotificationChannel.inbox,
      NotificationChannel.push,
    ],
    muted: false,
  );
  static const inAppOnly = _NotificationPreferenceStyle(
    value: 'in-app-only',
    label: 'In the app only',
    channels: <NotificationChannel>[NotificationChannel.inbox],
    muted: false,
  );
  static const deviceOnly = _NotificationPreferenceStyle(
    value: 'device-only',
    label: 'On my device only',
    channels: <NotificationChannel>[NotificationChannel.push],
    muted: false,
  );
  static const mutedStyle = _NotificationPreferenceStyle(
    value: 'muted',
    label: 'Muted',
    channels: <NotificationChannel>[NotificationChannel.inbox],
    muted: true,
  );

  static const styles = <_NotificationPreferenceStyle>[
    inAppAndDevice,
    inAppOnly,
    deviceOnly,
    mutedStyle,
  ];

  static final options = <SingleItemPreferenceOption>[
    for (final style in styles)
      SingleItemPreferenceOption(value: style.value, label: style.label),
  ];

  static _NotificationPreferenceStyle byValue(String value) {
    for (final style in styles) {
      if (style.value == value) return style;
    }
    throw ArgumentError.value(value, 'value', 'is not a notification style');
  }

  static _NotificationPreferenceStyle? tryFrom(
    List<NotificationChannel> channels,
    bool muted,
  ) {
    if (muted && _sameChannels(mutedStyle.channels, channels)) {
      return mutedStyle;
    }
    for (final style in styles) {
      if (!style.muted && _sameChannels(style.channels, channels)) return style;
    }
    // Never display a fabricated preference. If the service later introduces
    // a valid shape this control cannot present faithfully, it must be updated
    // with an explicit member-facing choice first.
    return null;
  }

  final String value;
  final String label;
  final List<NotificationChannel> channels;
  final bool muted;
}

bool _sameChannels(
  List<NotificationChannel> first,
  List<NotificationChannel> second,
) => first.length == second.length && first.toSet().containsAll(second);
