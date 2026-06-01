import 'package:flutter/material.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_design_system/loom_design_system.dart';

class RecommendationBuilderScreen extends StatefulWidget {
  const RecommendationBuilderScreen({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  State<RecommendationBuilderScreen> createState() =>
      _RecommendationBuilderScreenState();
}

class _RecommendationBuilderScreenState
    extends State<RecommendationBuilderScreen> {
  static const _sourceCreatorId = 'creator_solar_sarah';
  static const _destinationCreatorId = 'creator_city_ferments';
  static const _contentId = 'content_ferment_001';
  static const _note =
      'City Ferments is a strong fit for fans planning resilient home routines.';

  late final RecommendationReferralApi _api;
  late final SettlementEngineApi _settlementApi;

  RecommendationManifest? _manifest;
  ReferralTerms? _terms;
  CreatorReferralReceipt? _referral;
  String? _message;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _api = resolveRecommendationReferralApi();
    _settlementApi = resolveSettlementEngineApi();
  }

  Future<void> _publishRecommendation() async {
    await _run(() async {
      _manifest = await _api.publishRecommendationManifest(
        sourceCreatorId: _sourceCreatorId,
        destinationCreatorId: _destinationCreatorId,
        contentId: _contentId,
        note: _note,
        idempotencyKey: 'p8-recommendation-city-ferments',
      );
      _message = 'Recommendation manifest published to fan discovery.';
    });
  }

  Future<void> _publishTerms() async {
    await _run(() async {
      _terms = await _api.publishReferralTerms(
        sourceCreatorId: _sourceCreatorId,
        destinationCreatorId: _destinationCreatorId,
        windowDays: 14,
        capCents: 5000,
        rewardCents: 350,
        idempotencyKey: 'p8-referral-terms-city-ferments',
      );
      _message = 'Referral terms published with a 14-day window.';
    });
  }

  Future<void> _simulateReferral() async {
    await _run(() async {
      final manifest =
          _manifest ??
          await _api.publishRecommendationManifest(
            sourceCreatorId: _sourceCreatorId,
            destinationCreatorId: _destinationCreatorId,
            contentId: _contentId,
            note: _note,
            idempotencyKey: 'p8-recommendation-city-ferments',
          );
      final terms =
          _terms ??
          await _api.publishReferralTerms(
            sourceCreatorId: _sourceCreatorId,
            destinationCreatorId: _destinationCreatorId,
            windowDays: 14,
            capCents: 5000,
            rewardCents: 350,
            idempotencyKey: 'p8-referral-terms-city-ferments',
          );
      final discovery = await _api.recordDiscovery(
        manifestId: manifest.id,
        passportId: 'passport_demo_fan',
        idempotencyKey: 'p8-referral-discovery',
      );
      _referral = await _api.recordReferralConversion(
        discoveryReceiptId: discovery.id,
        termsId: terms.id,
        idempotencyKey: 'p8-referral-conversion',
      );
      await _settlementApi.runSettlement(idempotencyKey: 'p8-referral-run');
      _manifest = manifest;
      _terms = terms;
      _message = 'Referral conversion settled to creator revenue.';
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    await action();
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('p8_recommendation_builder_screen'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        Row(
          children: [
            IconButton(
              key: const ValueKey('p8_recommendations_back_button'),
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: Text(
                'Recommendations',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_message != null) ...[
          DataDashboardRow(
            key: _referral == null
                ? const ValueKey('p8_recommendation_published')
                : const ValueKey('p8_referral_settled'),
            icon: Icons.verified_rounded,
            title: _message!,
            subtitle: 'Manifest, terms, receipt, and settlement are auditable.',
          ),
          const SizedBox(height: 12),
        ],
        StudioRecommendationBuilder(
          sourceCreatorName: 'Solar Sarah',
          destinationCreatorName: 'City Ferments',
          contentTitle: 'Apartment kimchi without the drama',
          note: _note,
          manifestLabel: _manifest == null
              ? null
              : 'Manifest v${_manifest!.version}',
          termsLabel: _terms == null ? null : 'Terms v${_terms!.version}',
          referralLabel: _referral == null
              ? null
              : 'Referral ${_money(_referral!.amountCents)}',
          onPublishRecommendation: _busy ? null : _publishRecommendation,
          onPublishTerms: _busy ? null : _publishTerms,
          onSimulateReferral: _busy ? null : _simulateReferral,
        ),
      ],
    );
  }
}

String _money(int cents) {
  final dollars = cents ~/ 100;
  final remainder = (cents % 100).toString().padLeft(2, '0');
  return '\$$dollars.$remainder';
}
