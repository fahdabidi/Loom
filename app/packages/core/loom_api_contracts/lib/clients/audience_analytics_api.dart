import '../models/launch/launch_models.dart';

abstract class AudienceAnalyticsApi {
  Future<ConversionFunnel> getConversionFunnel({
    required String channelId,
    DateTime? startsAt,
    DateTime? endsAt,
  });
}
