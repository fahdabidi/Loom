import 'package:flutter/material.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_design_system/loom_design_system.dart';

class ArchiveQaScreen extends StatefulWidget {
  const ArchiveQaScreen({
    required this.creatorId,
    required this.onBack,
    super.key,
  });

  final String creatorId;
  final VoidCallback onBack;

  @override
  State<ArchiveQaScreen> createState() => _ArchiveQaScreenState();
}

class _ArchiveQaScreenState extends State<ArchiveQaScreen> {
  static const _passportId = 'passport_demo_fan';

  late final CreatorMetadataApi _metadataApi;
  late final AiGatewayApi _aiGatewayApi;
  late final TextEditingController _questionController;

  ChannelHome? _channel;
  AIContentPolicy? _policy;
  ArchiveAnswer? _answer;
  bool _loading = true;
  bool _asking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _metadataApi = resolveCreatorMetadataApi();
    _aiGatewayApi = resolveAiGatewayApi();
    _questionController = TextEditingController(
      text: 'What should I check before sizing a home battery?',
    );
    _load();
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final channel = await _metadataApi.getChannelHome(
        channelId: widget.creatorId,
        passportId: _passportId,
      );
      final policy = await _metadataApi.aiContentPolicy(widget.creatorId);
      setState(() {
        _channel = channel;
        _policy = policy;
      });
    } catch (error) {
      setState(() => _error = '$error');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _ask() async {
    final question = _questionController.text.trim();
    if (question.isEmpty || _asking) {
      return;
    }
    setState(() {
      _asking = true;
      _error = null;
    });
    try {
      final answer = await _aiGatewayApi.askArchive(
        passportId: _passportId,
        creatorId: widget.creatorId,
        question: question,
        policyRef: 'ai-policy:${widget.creatorId}',
        idempotencyKey: 'p5-archive-${widget.creatorId}-${question.hashCode}',
      );
      setState(() => _answer = answer);
    } catch (error) {
      setState(() => _error = '$error');
    } finally {
      setState(() => _asking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final channel = _channel;
    if (_error != null && channel == null) {
      return Center(child: Text(_error!));
    }

    return ListView(
      key: const ValueKey('p5_archive_qa_screen'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: [
        Row(
          children: [
            IconButton(
              key: const ValueKey('p5_archive_qa_back_button'),
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                channel?.displayName ?? 'Archive Q&A',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _PolicyCard(policy: _policy),
        const SizedBox(height: 14),
        TextField(
          key: const ValueKey('p5_question_field'),
          controller: _questionController,
          minLines: 2,
          maxLines: 4,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            labelText: 'Ask this creator archive',
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              key: const ValueKey('p5_suggested_prompt_button'),
              avatar: const Icon(Icons.bolt_rounded, size: 18),
              label: const Text('Battery sizing checks'),
              onPressed: () {
                _questionController.text =
                    'What should I check before sizing a home battery?';
              },
            ),
            FilledButton.icon(
              key: const ValueKey('p5_ask_button'),
              onPressed: _asking ? null : _ask,
              icon: _asking
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: const Text('Ask'),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: LoomColors.coral)),
        ],
        if (_answer != null) ...[
          const SizedBox(height: 16),
          QaAnswerCard(
            key: const ValueKey('p5_answer_card'),
            question: _answer!.question,
            answer: _answer!.answer,
            confidenceLabel: _answer!.confidenceLabel,
            citations: _answer!.citations
                .map(
                  (citation) => QaCitationView(
                    contentId: citation.contentId,
                    title: citation.title,
                    startLabel: citation.startLabel,
                    segment: citation.segment,
                    royaltyBasis: citation.royaltyBasis,
                  ),
                )
                .toList(growable: false),
            onCitationTap: _showCitation,
          ),
          const SizedBox(height: 14),
          for (final receipt in _answer!.receipts)
            ListTile(
              key: ValueKey(_receiptKey(receipt)),
              leading: const Icon(Icons.receipt_long_rounded),
              title: Text(_receiptLabel(receipt.type)),
              subtitle: Text(receipt.summary),
            ),
        ],
      ],
    );
  }

  void _showCitation(QaCitationView citation) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              citation.title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(citation.segment),
            const SizedBox(height: 10),
            Text(
              citation.royaltyBasis,
              key: const ValueKey('p5_citation_royalty_basis'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: LoomColors.moss,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({required this.policy});

  final AIContentPolicy? policy;

  @override
  Widget build(BuildContext context) {
    final enabled = policy?.archiveQaEnabled ?? true;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LoomColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          enabled ? Icons.verified_user_rounded : Icons.block_rounded,
          color: enabled ? LoomColors.moss : LoomColors.coral,
        ),
        title: const Text(
          'Cited archive answers',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          enabled
              ? 'Only cited transcript segments are returned; source receipts are emitted.'
              : 'Archive Q&A is disabled for this creator.',
        ),
      ),
    );
  }
}

String _receiptLabel(ReceiptType type) {
  switch (type) {
    case ReceiptType.aiUsage:
      return 'AI usage receipt';
    case ReceiptType.sourceAttribution:
      return 'Source-attribution receipt';
    case ReceiptType.playback:
      return 'Playback receipt';
    case ReceiptType.adImpression:
      return 'Ad receipt';
    case ReceiptType.payment:
      return 'Payment receipt';
    case ReceiptType.membership:
      return 'Membership receipt';
    case ReceiptType.premiumNoAd:
      return 'No-ad premium receipt';
  }
}

String _receiptKey(ReceiptView receipt) {
  if (receipt.type == ReceiptType.aiUsage) {
    return 'p5_receipt_aiUsage';
  }
  return 'p5_receipt_${receipt.type.name}_${receipt.contentId}';
}
