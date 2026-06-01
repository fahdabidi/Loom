enum ConsentGrantState { pending, approved, denied, revoked }

class DataConsentGrant {
  const DataConsentGrant({
    required this.id,
    required this.requestId,
    required this.passportId,
    required this.creatorId,
    required this.creatorName,
    required this.fields,
    required this.purpose,
    required this.retention,
    required this.valueExchange,
    required this.state,
    required this.updatedAt,
  });

  final String id;
  final String requestId;
  final String passportId;
  final String creatorId;
  final String creatorName;
  final List<String> fields;
  final String purpose;
  final String retention;
  final String valueExchange;
  final ConsentGrantState state;
  final DateTime updatedAt;
}

class CategoryDefault {
  const CategoryDefault({
    required this.id,
    required this.passportId,
    required this.category,
    required this.state,
    required this.updatedAt,
  });

  final String id;
  final String passportId;
  final String category;
  final ConsentGrantState state;
  final DateTime updatedAt;
}

class DataAccessReceipt {
  const DataAccessReceipt({
    required this.id,
    required this.passportId,
    required this.creatorId,
    required this.creatorName,
    required this.grantId,
    required this.fields,
    required this.purpose,
    required this.accessedAt,
  });

  final String id;
  final String passportId;
  final String creatorId;
  final String creatorName;
  final String grantId;
  final List<String> fields;
  final String purpose;
  final DateTime accessedAt;
}

class TombstoneRequest {
  const TombstoneRequest({
    required this.id,
    required this.passportId,
    required this.creatorId,
    required this.createdAt,
  });

  final String id;
  final String passportId;
  final String creatorId;
  final DateTime createdAt;
}
