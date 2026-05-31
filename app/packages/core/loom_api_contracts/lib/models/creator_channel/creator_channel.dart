class CreatorChannel {
  const CreatorChannel({
    required this.id,
    required this.ownerPassportId,
    required this.displayName,
    required this.handle,
    required this.vertical,
    required this.createdAt,
  });

  final String id;
  final String ownerPassportId;
  final String displayName;
  final String handle;
  final String vertical;
  final DateTime createdAt;
}
