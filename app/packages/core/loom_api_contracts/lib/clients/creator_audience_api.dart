import '../models/creator_audience/audience_models.dart';
import '../models/data_rights/data_rights_models.dart';

abstract class CreatorAudienceApi {
  Future<DataGrantRequest> createDataGrantRequest({
    required String creatorId,
    required String passportId,
    required List<String> fields,
    required String purpose,
    required String retention,
    required String valueExchange,
    required String idempotencyKey,
  });

  Future<List<DataGrantRequest>> pendingGrantRequests(String passportId);

  Future<PermissionedInterestData> queryPermissionedInterestData({
    required String creatorId,
    required String passportId,
    required String purpose,
    required String idempotencyKey,
  });

  Future<AudienceInsight> getAudienceInsights({required String creatorId});

  Future<List<DataAccessReceipt>> dataAccessReceipts(String passportId);
}
