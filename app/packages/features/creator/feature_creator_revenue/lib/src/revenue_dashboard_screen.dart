import 'package:flutter/material.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_design_system/loom_design_system.dart';

class CreatorRevenueDashboardScreen extends StatefulWidget {
  const CreatorRevenueDashboardScreen({
    required this.creatorId,
    required this.onBack,
    super.key,
  });

  final String creatorId;
  final VoidCallback onBack;

  @override
  State<CreatorRevenueDashboardScreen> createState() =>
      _CreatorRevenueDashboardScreenState();
}

class _CreatorRevenueDashboardScreenState
    extends State<CreatorRevenueDashboardScreen> {
  late final SettlementEngineApi _settlementApi;
  CreatorPayoutStatement? _statement;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _settlementApi = resolveSettlementEngineApi();
    _load();
  }

  Future<void> _load() async {
    await _settlementApi.runSettlement(
      idempotencyKey: 'p6-revenue-${widget.creatorId}',
    );
    final statement = await _settlementApi.getCreatorPayoutStatement(
      creatorId: widget.creatorId,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _statement = statement;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _statement == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final statement = _statement!;
    return ListView(
      key: const ValueKey('p6_revenue_dashboard'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        Row(
          children: [
            IconButton(
              key: const ValueKey('p6_revenue_back_button'),
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: Text(
                'Revenue',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 14),
        StudioRevenueDashboard(
          totalLabel: _money(statement.totalCents),
          sourceRows: statement.bySource
              .map(
                (row) => RevenueDashboardRow(
                  label: row.label,
                  value: _money(row.amountCents),
                ),
              )
              .toList(growable: false),
          intentRows: statement.byIntent
              .map(
                (row) => RevenueDashboardRow(
                  label: row.label,
                  value: _money(row.amountCents),
                  subtitle: 'Returned in the same payout statement.',
                ),
              )
              .toList(growable: false),
          receiptRows: statement.recentReceipts
              .map(
                (receipt) => RevenueDashboardRow(
                  label: _receiptTitle(receipt.type),
                  value: _dateLabel(receipt.createdAt),
                  subtitle: receipt.summary,
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

String _receiptTitle(ReceiptType type) {
  switch (type) {
    case ReceiptType.membership:
      return 'Membership receipt';
    case ReceiptType.premiumNoAd:
      return 'No-ad pool receipt';
    case ReceiptType.payment:
      return 'Payment receipt';
    case ReceiptType.adImpression:
      return 'Ad receipt';
    case ReceiptType.aiUsage:
      return 'AI usage receipt';
    case ReceiptType.sourceAttribution:
      return 'Source receipt';
    case ReceiptType.playback:
      return 'Playback receipt';
  }
}

String _dateLabel(DateTime value) {
  return '${value.month}/${value.day}/${value.year}';
}

String _money(int cents) {
  final dollars = cents ~/ 100;
  final remainder = (cents % 100).toString().padLeft(2, '0');
  return '\$$dollars.$remainder';
}
