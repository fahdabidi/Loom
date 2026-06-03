import 'package:flutter/material.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_design_system/loom_design_system.dart';

class CreatorMembershipSetupScreen extends StatefulWidget {
  const CreatorMembershipSetupScreen({
    required this.channelId,
    required this.onBack,
    super.key,
  });

  final String channelId;
  final VoidCallback onBack;

  @override
  State<CreatorMembershipSetupScreen> createState() =>
      _CreatorMembershipSetupScreenState();
}

class _CreatorMembershipSetupScreenState
    extends State<CreatorMembershipSetupScreen> {
  late final CreatorMetadataApi _metadataApi;
  late final EntitlementLedgerApi _entitlementLedgerApi;

  List<MembershipTier> _tiers = const [];
  List<EntitlementDefinition> _entitlements = const [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _metadataApi = resolveCreatorMetadataApi();
    _entitlementLedgerApi = resolveEntitlementLedgerApi();
    _load();
  }

  Future<void> _load() async {
    final tiers = await _metadataApi.membershipTiers(widget.channelId);
    final entitlements = await _entitlementLedgerApi.entitlementDefinitions(
      widget.channelId,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _tiers = tiers;
      _entitlements = entitlements;
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    final tiers = await _metadataApi.defineMembershipTiers(
      channelId: widget.channelId,
      tiers: const [
        MembershipTierDraft(
          name: 'Supporter',
          monthlyPriceCents: 500,
          benefits: ['Member posts', 'Monthly notes'],
          entitlementCode: 'member.supporter',
        ),
        MembershipTierDraft(
          name: 'Lab Insider',
          monthlyPriceCents: 1200,
          benefits: ['Member videos', 'Early checklists'],
          entitlementCode: 'member.lab_insider',
        ),
      ],
      idempotencyKey: 'p13-membership-${widget.channelId}',
    );
    final entitlements = await _entitlementLedgerApi
        .registerMembershipTierDefinitions(
          channelId: widget.channelId,
          tiers: tiers,
          idempotencyKey: 'p13-entitlements-${widget.channelId}',
        );
    await _metadataApi.updateMonetizationManifest(
      channelId: widget.channelId,
      membershipsEnabled: true,
      memberOnlyContentIds: const ['content_solar_002'],
      idempotencyKey: 'p13-monetization-${widget.channelId}',
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _tiers = tiers;
      _entitlements = entitlements;
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      key: const ValueKey('p13_membership_setup_screen'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Memberships',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: LoomSpacing.md),
        const DataDashboardRow(
          key: ValueKey('p13_membership_validation'),
          icon: Icons.rule_rounded,
          title: 'Validation preview',
          subtitle:
              'Tier names, prices, benefits, and entitlement codes are saved together.',
        ),
        const SizedBox(height: LoomSpacing.md),
        StudioMonetizationEditor(
          tierCount: _tiers.length,
          entitlementCount: _entitlements.length,
          onDefineTiers: _saving ? () {} : _save,
        ),
        const SizedBox(height: LoomSpacing.md),
        for (final tier in _tiers) ...[
          _TierPreview(tier: tier),
          const SizedBox(height: LoomSpacing.sm),
        ],
        if (_saving) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _TierPreview extends StatelessWidget {
  const _TierPreview({required this.tier});

  final MembershipTier tier;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('p13_membership_tier_${tier.id}'),
      padding: const EdgeInsets.all(LoomSpacing.md),
      decoration: BoxDecoration(
        color: LoomColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LoomColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tier.name, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(
            '\$${(tier.monthlyPriceCents / 100).toStringAsFixed(0)}/mo · ${tier.entitlementCode}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: LoomColors.mutedInk,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final benefit in tier.benefits) Chip(label: Text(benefit)),
            ],
          ),
        ],
      ),
    );
  }
}
