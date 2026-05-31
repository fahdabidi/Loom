enum FollowVisibility { public, private }

extension FollowVisibilityLabel on FollowVisibility {
  String get label {
    switch (this) {
      case FollowVisibility.public:
        return 'Public';
      case FollowVisibility.private:
        return 'Private';
    }
  }
}

class FollowView {
  const FollowView({
    required this.id,
    required this.passportId,
    required this.creatorId,
    required this.creatorDisplayName,
    required this.visibility,
    required this.blocked,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String passportId;
  final String creatorId;
  final String creatorDisplayName;
  final FollowVisibility visibility;
  final bool blocked;
  final DateTime createdAt;
  final DateTime updatedAt;
}
