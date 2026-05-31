import '../models/ai_gateway/summary_draft.dart';

abstract class AiGatewayApi {
  Future<SummaryDraft> generateSummaryDraft({
    required String title,
    required String sourceNote,
  });
}
