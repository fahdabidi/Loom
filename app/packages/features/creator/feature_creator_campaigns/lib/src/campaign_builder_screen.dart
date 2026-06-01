import 'package:flutter/material.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_design_system/loom_design_system.dart';

class CreatorCampaignBuilderScreen extends StatefulWidget {
  const CreatorCampaignBuilderScreen({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  State<CreatorCampaignBuilderScreen> createState() =>
      _CreatorCampaignBuilderScreenState();
}

class _CreatorCampaignBuilderScreenState
    extends State<CreatorCampaignBuilderScreen> {
  late final CampaignApi _campaignApi;
  late final SponsorCampaignApi _sponsorApi;

  Campaign? _campaign;
  SponsorProposal? _proposal;
  FanDataGrantOffer? _offer;
  String? _message;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _campaignApi = resolveCampaignApi();
    _sponsorApi = resolveSponsorCampaignApi();
  }

  Future<void> _createCampaign() async {
    await _run(() async {
      _campaign = await _campaignApi.createCampaign(
        creatorId: 'creator_solar_sarah',
        title: 'Clean Energy Setup Giveaway',
        description:
            'Fans enter for a home energy starter kit while every entry and reward remains receipt-backed.',
        rewardLabel: 'Home energy kit',
        endsAt: DateTime.now().toUtc().add(const Duration(days: 14)),
        idempotencyKey: 'p8-clean-energy-campaign',
      );
      _message = 'Campaign published to the fan campaigns surface.';
    });
  }

  Future<void> _attachOffer() async {
    await _run(() async {
      final campaign =
          _campaign ??
          await _campaignApi.createCampaign(
            creatorId: 'creator_solar_sarah',
            title: 'Clean Energy Setup Giveaway',
            description:
                'Fans enter for a home energy starter kit while every entry and reward remains receipt-backed.',
            rewardLabel: 'Home energy kit',
            endsAt: DateTime.now().toUtc().add(const Duration(days: 14)),
            idempotencyKey: 'p8-clean-energy-campaign',
          );
      _proposal = await _sponsorApi.createProposal(
        sponsorName: 'Gridwise Home',
        creatorId: campaign.creatorId,
        campaignId: campaign.id,
        title: 'Energy category insight exchange',
        valueExchange:
            'Fans can opt in to share approved interest fields for an extra giveaway entry.',
        idempotencyKey: 'p8-gridwise-proposal-${campaign.id}',
      );
      _offer = await _sponsorApi.attachFanDataGrantOffer(
        proposalId: _proposal!.id,
        fields: const ['interest_categories', 'interest_tokens'],
        purpose: 'Sponsor fit for home energy giveaway rewards',
        valueExchange: 'Extra giveaway entry and transparent access receipt.',
        idempotencyKey: 'p8-gridwise-offer-${_proposal!.id}',
      );
      _campaign = campaign;
      _message = 'Sponsor data-for-value offer attached.';
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
      key: const ValueKey('p8_campaign_builder_screen'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        Row(
          children: [
            IconButton(
              key: const ValueKey('p8_campaign_builder_back_button'),
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: Text(
                'Campaigns',
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
            key: _offer == null
                ? const ValueKey('p8_campaign_published')
                : const ValueKey('p8_sponsor_offer_attached'),
            icon: Icons.verified_rounded,
            title: _message!,
            subtitle:
                'Campaign state is shared with the fan app for entry validation.',
          ),
          const SizedBox(height: 12),
        ],
        StudioCampaignBuilder(
          title: 'Clean Energy Setup Giveaway',
          description:
              'A compact creator campaign modeled after modern social entry flows: visible reward, one primary entry action, and clear data exchange terms.',
          rewardLabel: 'Home energy kit',
          campaignLabel: _campaign == null
              ? null
              : '${_campaign!.entryCount} entries',
          offerLabel: _offer == null ? null : 'Sponsor offer attached',
          onCreateCampaign: _busy ? null : _createCampaign,
          onAttachOffer: _busy ? null : _attachOffer,
        ),
      ],
    );
  }
}
