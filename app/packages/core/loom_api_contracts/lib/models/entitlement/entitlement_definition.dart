class EntitlementDefinition {
  const EntitlementDefinition({
    required this.id,
    required this.channelId,
    required this.tierId,
    required this.code,
    required this.createdAt,
  });

  final String id;
  final String channelId;
  final String tierId;
  final String code;
  final DateTime createdAt;
}
