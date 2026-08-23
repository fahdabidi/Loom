class FanPassportClaim {
  const FanPassportClaim({
    required this.id,
    required this.displayName,
    required this.activeFanProfileId,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final String activeFanProfileId;
  final DateTime createdAt;
}
