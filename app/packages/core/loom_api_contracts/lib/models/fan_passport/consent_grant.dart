class ConsentGrant {
  const ConsentGrant({
    required this.id,
    required this.passportId,
    required this.grantType,
    required this.createdAt,
  });

  final String id;
  final String passportId;
  final String grantType;
  final DateTime createdAt;
}
