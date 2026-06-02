import 'package:flutter/material.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_design_system/loom_design_system.dart';

class CreatorConversionAnalyticsScreen extends StatefulWidget {
  const CreatorConversionAnalyticsScreen({
    required this.creatorId,
    required this.onBack,
    super.key,
  });

  final String creatorId;
  final VoidCallback onBack;

  @override
  State<CreatorConversionAnalyticsScreen> createState() =>
      _CreatorConversionAnalyticsScreenState();
}

class _CreatorConversionAnalyticsScreenState
    extends State<CreatorConversionAnalyticsScreen> {
  late final AudienceAnalyticsApi _analyticsApi;
  ConversionFunnel? _funnel;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _analyticsApi = resolveAudienceAnalyticsApi();
    _load();
  }

  Future<void> _load() async {
    final funnel = await _analyticsApi.getConversionFunnel(
      channelId: widget.creatorId,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _funnel = funnel;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _funnel == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final funnel = _funnel!;
    return ListView(
      key: const ValueKey('p13_conversion_analytics_screen'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        Row(
          children: [
            IconButton(
              key: const ValueKey('p13_conversion_back_button'),
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: Text(
                'Conversion',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: LoomSpacing.md),
        ConversionFunnelCard(
          aggregateOnly: funnel.aggregateOnly,
          dateRangeLabel:
              '${_date(funnel.startsAt)} to ${_date(funnel.endsAt)}',
          stages: _stages(funnel),
          sourceBreakdown: funnel.byChannelSource.entries
              .map(
                (entry) => MiniBarDatum(label: entry.key, value: entry.value),
              )
              .toList(growable: false),
          onRefresh: _load,
        ),
      ],
    );
  }
}

List<FunnelStageView> _stages(ConversionFunnel funnel) {
  final maxCount = funnel.stages.fold<int>(
    1,
    (max, stage) => stage.count > max ? stage.count : max,
  );
  return funnel.stages
      .map(
        (stage) => FunnelStageView(
          label: _stageLabel(stage.stage),
          countLabel: '${stage.count}',
          ratio: stage.count / maxCount,
          detail: stage.conversionFromPrevious == null
              ? 'Audience reached'
              : '${(stage.conversionFromPrevious! * 100).toStringAsFixed(0)}% from prior stage',
        ),
      )
      .toList(growable: false);
}

String _stageLabel(String stage) {
  return switch (stage) {
    'reached' => 'Audience reached',
    'capture_link' => 'Capture links',
    're_followed' => 'Re-followed',
    'member' => 'Members',
    'premium' => 'Premium no-ad',
    'member_or_premium' => 'Member or premium',
    _ => stage,
  };
}

String _date(DateTime value) => '${value.month}/${value.day}/${value.year}';
