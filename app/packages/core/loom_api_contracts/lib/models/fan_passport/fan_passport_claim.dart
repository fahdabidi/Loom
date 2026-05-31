class FanPassportClaim {
  const FanPassportClaim({
    required this.id,
    required this.displayName,
    required this.activePersonaId,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final String activePersonaId;
  final DateTime createdAt;
}
