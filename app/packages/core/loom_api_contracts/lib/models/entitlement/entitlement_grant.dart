class EntitlementGrant {
  const EntitlementGrant({
    required this.id,
    required this.passportId,
    required this.code,
    required this.sourcePaymentIntentId,
    required this.active,
    required this.grantedAt,
    this.creatorId,
  });

  final String id;
  final String passportId;
  final String code;
  final String? creatorId;
  final String sourcePaymentIntentId;
  final bool active;
  final DateTime grantedAt;
}

class EntitlementCheckResult {
  const EntitlementCheckResult({
    required this.passportId,
    required this.activeCodes,
    required this.checkedAt,
  });

  final String passportId;
  final Set<String> activeCodes;
  final DateTime checkedAt;

  bool has(String code) => activeCodes.contains(code);
}
