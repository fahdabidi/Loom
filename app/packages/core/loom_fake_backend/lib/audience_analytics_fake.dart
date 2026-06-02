import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart'
    show ConversionFunnelRecord, ConversionStageRecord, DemoLocalStore;

class AudienceAnalyticsFake implements AudienceAnalyticsApi {
  const AudienceAnalyticsFake(
    this._store, {
    this.latency = const Duration(milliseconds: 100),
  });

  final DemoLocalStore _store;
  final Duration latency;

  @override
  Future<ConversionFunnel> getConversionFunnel({
    required String channelId,
    DateTime? startsAt,
    DateTime? endsAt,
  }) async {
    await Future<void>.delayed(latency);
    return _mapFunnel(
      await _store.conversionFunnel(
        channelId: channelId,
        startsAt: startsAt,
        endsAt: endsAt,
      ),
    );
  }
}

ConversionFunnel _mapFunnel(ConversionFunnelRecord record) {
  return ConversionFunnel(
    channelId: record.channelId,
    aggregateOnly: true,
    startsAt: record.startsAt,
    endsAt: record.endsAt,
    stages: record.stages.map(_mapStage).toList(growable: false),
    byChannelSource: record.byChannelSource,
  );
}

ConversionStage _mapStage(ConversionStageRecord record) {
  return ConversionStage(
    stage: record.stage,
    count: record.count,
    conversionFromPrevious: record.conversionFromPrevious,
  );
}
