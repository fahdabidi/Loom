import 'package:loom_api_contracts/loom_api_contracts.dart';

class AiGatewayFake implements AiGatewayApi {
  const AiGatewayFake({this.latency = const Duration(milliseconds: 100)});

  final Duration latency;

  @override
  Future<SummaryDraft> generateSummaryDraft({
    required String title,
    required String sourceNote,
  }) async {
    await Future<void>.delayed(latency);
    return SummaryDraft(
      title: title,
      summary:
          'A creator-approved draft summary for "$title" that explains the setup, audience value, and why the content is ready for discovery.',
    );
  }
}
