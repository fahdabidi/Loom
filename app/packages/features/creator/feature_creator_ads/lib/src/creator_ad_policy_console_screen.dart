import 'package:flutter/material.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_design_system/loom_design_system.dart';

class CreatorAdPolicyConsoleScreen extends StatefulWidget {
  const CreatorAdPolicyConsoleScreen({
    required this.channelId,
    required this.onBack,
    super.key,
  });

  final String channelId;
  final VoidCallback onBack;

  @override
  State<CreatorAdPolicyConsoleScreen> createState() =>
      _CreatorAdPolicyConsoleScreenState();
}

class _CreatorAdPolicyConsoleScreenState
    extends State<CreatorAdPolicyConsoleScreen> {
  late final CreatorMetadataApi _metadataApi;
  late final AdDecisionApi _adDecisionApi;

  CreatorAdPolicy? _policy;
  AdDecision? _decision;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _metadataApi = resolveCreatorMetadataApi();
    _adDecisionApi = resolveAdDecisionApi();
    _load();
  }

  Future<void> _load() async {
    final policy = await _metadataApi.creatorAdPolicy(widget.channelId);
    if (!mounted) {
      return;
    }
    setState(() {
      _policy = policy;
      _loading = false;
    });
  }

  Future<void> _saveAndVerify(StudioAdPolicySelection selection) async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    final policy = await _metadataApi.setCreatorAdPolicy(
      channelId: widget.channelId,
      allowedCategories: selection.allowedCategories,
      blockedCategories: selection.blockedCategories,
      formats: const ['pre_roll', 'sponsor_card'],
      surfaces: const ['watch', 'channel'],
      idempotencyKey: 'p13-ad-policy-${widget.channelId}',
    );
    final decision = await _adDecisionApi.decideAds(
      contentId: 'content_solar_001',
      adPosture: 'standard',
      entitlementState: EntitlementState.adSupported.name,
      idempotencyKey: 'p13-ad-decision-${widget.channelId}',
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _policy = policy;
      _decision = decision;
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final policy = _policy;
    return ListView(
      key: const ValueKey('p13_ad_policy_console'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Ad policy',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: LoomSpacing.md),
        StudioAdPolicyEditor(
          initialAllowedCategories:
              policy?.allowedCategories ?? const ['sustainable_living'],
          initialBlockedCategories:
              policy?.blockedCategories ??
              const ['home_energy', 'gambling', 'alcohol'],
          savedLabel: policy == null
              ? 'Draft blocks home energy ads before verification.'
              : 'Saved ${_date(policy.updatedAt)} - allows ${policy.allowedCategories.join(', ')}; blocks ${policy.blockedCategories.join(', ')}',
          onSavePolicy: _saveAndVerify,
        ),
        const SizedBox(height: LoomSpacing.md),
        if (_saving) const Center(child: CircularProgressIndicator()),
        if (_decision != null) _DecisionPanel(decision: _decision!),
      ],
    );
  }
}

class _DecisionPanel extends StatelessWidget {
  const _DecisionPanel({required this.decision});

  final AdDecision decision;

  @override
  Widget build(BuildContext context) {
    final categories = decision.ads.map((ad) => ad.category).join(', ');
    return DataDashboardRow(
      key: const ValueKey('p13_ad_decision_verification'),
      icon: Icons.policy_outlined,
      title: 'Ad decision policy ${decision.policyVersion}',
      subtitle: categories.isEmpty
          ? 'No ad selected after policy filter.'
          : 'Selected categories: $categories',
    );
  }
}

String _date(DateTime value) => '${value.month}/${value.day}/${value.year}';
