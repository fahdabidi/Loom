class CreatorChannelManifest {
  const CreatorChannelManifest({
    required this.channelId,
    required this.displayName,
    required this.handle,
    required this.description,
    required this.category,
    required this.createdAt,
  });

  final String channelId;
  final String displayName;
  final String handle;
  final String description;
  final String category;
  final DateTime createdAt;
}
