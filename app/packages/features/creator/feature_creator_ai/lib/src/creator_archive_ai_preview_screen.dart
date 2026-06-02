import 'package:flutter/material.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_design_system/loom_design_system.dart';

class CreatorArchiveAiPreviewScreen extends StatefulWidget {
  const CreatorArchiveAiPreviewScreen({
    required this.creatorId,
    required this.onBack,
    super.key,
  });

  final String creatorId;
  final VoidCallback onBack;

  @override
  State<CreatorArchiveAiPreviewScreen> createState() =>
      _CreatorArchiveAiPreviewScreenState();
}

class _CreatorArchiveAiPreviewScreenState
    extends State<CreatorArchiveAiPreviewScreen> {
  static const _question =
      'What should a new fan watch first if they want a practical solar setup?';

  late final AiGatewayApi _aiGatewayApi;
  ArchiveAnswer? _answer;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _aiGatewayApi = resolveAiGatewayApi();
  }

  Future<void> _ask() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    final answer = await _aiGatewayApi.askArchive(
      passportId: 'passport_demo_fan',
      creatorId: widget.creatorId,
      question: _question,
      policyRef: 'creator_preview_cited',
      idempotencyKey: 'p13-creator-ai-${widget.creatorId}',
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _answer = answer;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final answer = _answer;
    return ListView(
      key: const ValueKey('p13_creator_ai_preview_screen'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        Row(
          children: [
            IconButton(
              key: const ValueKey('p13_creator_ai_back_button'),
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: Text(
                'Archive AI',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: LoomSpacing.md),
        StudioArchiveAiPreview(
          question: _question,
          answer: answer?.answer,
          confidenceLabel: answer?.confidenceLabel,
          citations:
              answer?.citations
                  .map(
                    (citation) => ArchiveCitationView(
                      title: citation.title,
                      segment: citation.segment,
                      startLabel: citation.startLabel,
                      royaltyBasis: citation.royaltyBasis,
                    ),
                  )
                  .toList(growable: false) ??
              const [],
          busy: _busy,
          onAsk: _ask,
        ),
      ],
    );
  }
}
