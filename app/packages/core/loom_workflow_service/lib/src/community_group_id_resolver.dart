import 'dart:async';
import 'dart:convert';

/// Resolves the App Access group belonging to one canonical community id.
///
/// A community id and community handle are separate registry/package fields,
/// and real packages prove that one cannot be derived from the other. Callers
/// must therefore supply an explicit mapping instead of guessing a group id.
abstract interface class CommunityGroupIdResolver {
  FutureOr<String?> resolveGroupId(String communityId);
}

/// An explicit canonical-community-id to App-Access-group-id mapping.
class MapCommunityGroupIdResolver implements CommunityGroupIdResolver {
  MapCommunityGroupIdResolver(Map<String, String> groupIdsByCommunityId)
    : _groupIdsByCommunityId = Map.unmodifiable(groupIdsByCommunityId);

  factory MapCommunityGroupIdResolver.fromJson(String encoded) {
    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException {
      throw const FormatException(
        'LOOM_COMMUNITY_GROUP_IDS must be a JSON object.',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'LOOM_COMMUNITY_GROUP_IDS must be a JSON object.',
      );
    }

    final mapping = <String, String>{};
    for (final entry in decoded.entries) {
      final groupId = entry.value;
      if (entry.key.trim().isEmpty ||
          groupId is! String ||
          groupId.trim().isEmpty) {
        throw const FormatException(
          'LOOM_COMMUNITY_GROUP_IDS must map non-empty ids to non-empty group ids.',
        );
      }
      mapping[entry.key] = groupId;
    }
    return MapCommunityGroupIdResolver(mapping);
  }

  final Map<String, String> _groupIdsByCommunityId;

  @override
  String? resolveGroupId(String communityId) =>
      _groupIdsByCommunityId[communityId];
}
