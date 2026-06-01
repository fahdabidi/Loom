import '../data_rights/data_rights_models.dart';

class DataGrantRequest {
  const DataGrantRequest({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    required this.passportId,
    required this.fields,
    required this.purpose,
    required this.retention,
    required this.valueExchange,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String creatorId;
  final String creatorName;
  final String passportId;
  final List<String> fields;
  final String purpose;
  final String retention;
  final String valueExchange;
  final ConsentGrantState state;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class PermissionedInterestData {
  const PermissionedInterestData({
    required this.creatorId,
    required this.passportId,
    required this.fields,
    required this.values,
    required this.receipt,
  });

  final String creatorId;
  final String passportId;
  final List<String> fields;
  final Map<String, List<String>> values;
  final DataAccessReceipt receipt;
}

class AudienceInsight {
  const AudienceInsight({
    required this.creatorId,
    required this.approvedFanCount,
    required this.topCategories,
    required this.permissionStatus,
    required this.updatedAt,
  });

  final String creatorId;
  final int approvedFanCount;
  final List<String> topCategories;
  final String permissionStatus;
  final DateTime updatedAt;
}
