import 'package:flutter/material.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_design_system/loom_design_system.dart';

class PlaybackScreen extends StatefulWidget {
  const PlaybackScreen({
    required this.contentId,
    required this.onBack,
    this.passportId = 'passport_demo_fan',
    super.key,
  });

  final String contentId;
  final String passportId;
  final VoidCallback onBack;

  @override
  State<PlaybackScreen> createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends State<PlaybackScreen> {
  late final CreatorMetadataApi _metadataApi;
  late final PlaybackAuthorizationApi _playbackApi;
  ContentDetail? _detail;
  PlaybackAuthorization? _authorization;
  List<ReceiptView> _receipts = const [];
  bool _loading = true;
  bool _complete = false;

  @override
  void initState() {
    super.initState();
    _metadataApi = resolveCreatorMetadataApi();
    _playbackApi = resolvePlaybackAuthorizationApi();
    _load();
  }

  Future<void> _load() async {
    final detail = await _metadataApi.getContentDetail(widget.contentId);
    final authorization = await _playbackApi.authorize(
      passportId: widget.passportId,
      contentId: widget.contentId,
      adContext: const AdContext(
        sessionIntentId: 'p4-manual-session',
        intentLabel: 'Watch',
        allowedCategories: ['home_energy', 'fermentation', 'mobility'],
      ),
      entitlementState: EntitlementState.adSupported,
      idempotencyKey: 'p4-auth-${widget.passportId}-${widget.contentId}',
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _detail = detail;
      _authorization = authorization;
      _loading = false;
    });
  }

  Future<void> _completePlayback() async {
    final authorization = _authorization;
    if (authorization == null) {
      return;
    }
    final completion = await _playbackApi.complete(
      authorizationId: authorization.id,
      idempotencyKey: 'p4-complete-${authorization.id}',
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _complete = true;
      _receipts = completion.receipts;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _detail == null || _authorization == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final detail = _detail!;
    final authorization = _authorization!;

    return ListView(
      key: const ValueKey('p4_player_screen'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        Row(
          children: [
            IconButton(
              key: const ValueKey('p4_playback_back_button'),
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: Text(
                detail.creatorDisplayName,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (detail.contentType == ContentType.video)
          PlayerChrome(
            title: detail.title,
            thumbnailRef: detail.thumbnailRef,
            isComplete: _complete,
            onComplete: _completePlayback,
          )
        else
          PostView(
            title: detail.title,
            body: detail.body,
            isComplete: _complete,
            onComplete: _completePlayback,
          ),
        const SizedBox(height: 14),
        if (authorization.adPlan.hasAd)
          AdSlot(
            brandName: authorization.adPlan.brandName,
            category: authorization.adPlan.category,
            disclosure: authorization.adPlan.disclosure,
          ),
        const SizedBox(height: 14),
        Text(
          detail.summary,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.32),
        ),
        const SizedBox(height: 18),
        for (final receipt in _receipts) _ReceiptRow(receipt: receipt),
      ],
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.receipt});

  final ReceiptView receipt;

  @override
  Widget build(BuildContext context) {
    final isAd = receipt.type == ReceiptType.adImpression;
    return ListTile(
      key: ValueKey(isAd ? 'p4_ad_receipt' : 'p4_playback_receipt'),
      contentPadding: EdgeInsets.zero,
      leading: Icon(isAd ? Icons.campaign_rounded : Icons.receipt_long),
      title: Text(isAd ? 'Ad impression receipt' : 'Playback receipt'),
      subtitle: Text(receipt.summary),
    );
  }
}
