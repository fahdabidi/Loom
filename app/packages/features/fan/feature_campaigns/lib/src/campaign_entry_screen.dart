import 'package:flutter/material.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_design_system/loom_design_system.dart';

class CampaignEntryScreen extends StatefulWidget {
  const CampaignEntryScreen({
    required this.onBack,
    this.passportId = 'passport_demo_fan',
    super.key,
  });

  final VoidCallback onBack;
  final String passportId;

  @override
  State<CampaignEntryScreen> createState() => _CampaignEntryScreenState();
}

class _CampaignEntryScreenState extends State<CampaignEntryScreen> {
  late final CampaignApi _campaignApi;
  late final SponsorCampaignApi _sponsorApi;
  late final CreatorAudienceApi _audienceApi;
  late final FanPassportApi _passportApi;

  Campaign? _campaign;
  CampaignEntry? _entry;
  Reward? _reward;
  FanDataGrantOffer? _offer;
  DataAccessReceipt? _dataReceipt;
  String? _message;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _campaignApi = resolveCampaignApi();
    _sponsorApi = resolveSponsorCampaignApi();
    _audienceApi = resolveCreatorAudienceApi();
    _passportApi = resolveFanPassportApi();
    _load();
  }

  Future<void> _load() async {
    final campaigns = await _campaignApi.listActiveCampaigns();
    final campaign = campaigns.first;
    var offers = await _sponsorApi.listOffersForCampaign(campaign.id);
    if (offers.isEmpty) {
      final proposal = await _sponsorApi.createProposal(
        sponsorName: 'Gridwise Home',
        creatorId: campaign.creatorId,
        campaignId: campaign.id,
        title: 'Energy category insight exchange',
        valueExchange:
            'Fans can opt in to share approved interest fields for an extra giveaway entry.',
        idempotencyKey: 'p8-default-proposal-${campaign.id}',
      );
      final offer = await _sponsorApi.attachFanDataGrantOffer(
        proposalId: proposal.id,
        fields: const ['interest_categories', 'interest_tokens'],
        purpose: 'Sponsor fit for home energy giveaway rewards',
        valueExchange: 'Extra giveaway entry and transparent access receipt.',
        idempotencyKey: 'p8-default-offer-${proposal.id}',
      );
      offers = [offer];
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _campaign = campaign;
      _offer = offers.first;
      _loading = false;
    });
  }

  Future<void> _enterCampaign() async {
    final campaign = _campaign;
    if (campaign == null) {
      return;
    }
    await _run(() async {
      _entry = await _campaignApi.participate(
        campaignId: campaign.id,
        passportId: widget.passportId,
        idempotencyKey: 'p8-entry-${campaign.id}-${widget.passportId}',
      );
      _message = 'Campaign entry recorded.';
    });
  }

  Future<void> _issueReward() async {
    final campaign = _campaign;
    final entry = _entry;
    if (campaign == null || entry == null) {
      return;
    }
    await _run(() async {
      _reward = await _campaignApi.issueReward(
        campaignId: campaign.id,
        entryId: entry.id,
        idempotencyKey: 'p8-reward-${entry.id}',
      );
      _message = 'Reward issued with visible campaign status.';
    });
  }

  Future<void> _acceptDataOffer() async {
    final offer = _offer;
    if (offer == null) {
      return;
    }
    await _run(() async {
      final request = await _audienceApi.createDataGrantRequest(
        creatorId: offer.creatorId,
        passportId: widget.passportId,
        fields: offer.fields,
        purpose: offer.purpose,
        retention: 'Demo session only',
        valueExchange: offer.valueExchange,
        idempotencyKey: 'p8-data-offer-request-${offer.id}',
      );
      await _passportApi.reviewDataGrantRequest(
        requestId: request.id,
        passportId: widget.passportId,
        state: ConsentGrantState.approved,
        approvedFields: offer.fields,
        idempotencyKey: 'p8-data-offer-approve-${request.id}',
      );
      final data = await _audienceApi.queryPermissionedInterestData(
        creatorId: offer.creatorId,
        passportId: widget.passportId,
        purpose: offer.purpose,
        idempotencyKey: 'p8-data-offer-query-${offer.id}',
      );
      final receipts = await _audienceApi.dataAccessReceipts(widget.passportId);
      _dataReceipt = receipts.isEmpty ? null : receipts.first;
      _message = data.fields.isEmpty
          ? 'Data offer approved, but no fields were returned.'
          : 'Data offer accepted and access receipt recorded.';
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
    if (_loading || _campaign == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final campaign = _campaign!;
    final offer = _offer;
    return ListView(
      key: const ValueKey('p8_campaign_entry_screen'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        Row(
          children: [
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
            key: _dataReceipt != null
                ? const ValueKey('p8_sponsor_data_receipt')
                : _reward != null
                ? const ValueKey('p8_reward_receipt')
                : const ValueKey('p8_campaign_entry_receipt'),
            icon: Icons.verified_rounded,
            title: _message!,
            subtitle: _dataReceipt == null
                ? 'Entry and reward status stay visible to the fan.'
                : '${_dataReceipt!.creatorName} accessed ${_dataReceipt!.fields.join(', ')}.',
          ),
          const SizedBox(height: 12),
        ],
        CampaignCard(
          creatorName: campaign.creatorName,
          title: campaign.title,
          description: campaign.description,
          rewardLabel: _reward?.label ?? campaign.rewardLabel,
          entryLabel: _entry == null ? 'Not entered' : 'Entry recorded',
          offerLabel: offer == null
              ? null
              : '${offer.sponsorName}: optional data exchange',
          onEnter: _busy || _entry != null ? null : _enterCampaign,
          onIssueReward: _busy || _entry == null || _reward != null
              ? null
              : _issueReward,
          onAcceptOffer: _busy || _dataReceipt != null
              ? null
              : _acceptDataOffer,
        ),
      ],
    );
  }
}
