import 'package:flutter/material.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_design_system/loom_design_system.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({
    required this.onBack,
    this.passportId = 'passport_demo_fan',
    super.key,
  });

  final String passportId;
  final VoidCallback onBack;

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late final FanWalletApi _walletApi;
  late final SettlementEngineApi _settlementApi;
  Wallet? _wallet;
  FanSubscriptionAllocationStatement? _allocation;
  PaymentIntent? _lastIntent;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _walletApi = resolveFanWalletApi();
    _settlementApi = resolveSettlementEngineApi();
    _load();
  }

  Future<void> _load() async {
    final wallet = await _walletApi.getWallet(widget.passportId);
    final allocation = await _settlementApi.getFanSubscriptionAllocation(
      passportId: widget.passportId,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _wallet = wallet;
      _allocation = allocation;
      _loading = false;
    });
  }

  Future<void> _startPurchase(PurchaseKind kind) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    final intent = await _walletApi.createPaymentIntent(
      passportId: widget.passportId,
      kind: kind,
      creatorId: kind == PurchaseKind.creatorMembership
          ? 'creator_solar_sarah'
          : null,
      idempotencyKey: 'p6-${widget.passportId}-${kind.name}',
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _lastIntent = intent;
      _busy = false;
    });
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => PurchaseSheet(
        title: kind == PurchaseKind.noAdsPremium
            ? 'No-ad premium'
            : intent.tierName ?? 'Creator membership',
        subtitle: kind == PurchaseKind.noAdsPremium
            ? 'Simulated platform purchase for eligible no-ad playback.'
            : 'Simulated membership support for ${intent.creatorName ?? 'Solar Sarah'}.',
        amountLabel: _money(intent.amountCents),
        benefits: kind == PurchaseKind.noAdsPremium
            ? const [
                'Skip contextual ad slots on eligible playback',
                'Keep creator receipt transparency',
                'Manage entitlement from wallet',
              ]
            : const [
                'Unlock member-support entitlement',
                'Support creator-owned content and hosting',
                'Show allocation statement in wallet',
              ],
        onConfirm: () async {
          await _confirmPurchase(intent.id);
          if (sheetContext.mounted) {
            Navigator.of(sheetContext).pop();
          }
        },
      ),
    );
  }

  Future<void> _confirmPurchase(String paymentIntentId) async {
    setState(() => _busy = true);
    final confirmed = await _walletApi.confirmPaymentIntent(
      paymentIntentId: paymentIntentId,
      idempotencyKey: 'confirm-$paymentIntentId',
    );
    await _settlementApi.runSettlement(
      idempotencyKey: 'p6-settle-${widget.passportId}-${confirmed.id}',
    );
    final wallet = await _walletApi.getWallet(widget.passportId);
    final allocation = await _settlementApi.getFanSubscriptionAllocation(
      passportId: widget.passportId,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _lastIntent = confirmed;
      _wallet = wallet;
      _allocation = allocation;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _wallet == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final wallet = _wallet!;
    final allocation = _allocation;

    return ListView(
      key: const ValueKey('p6_wallet_screen'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        Row(
          children: [
            TextButton.icon(
              key: const ValueKey('p6_wallet_back_button'),
              onPressed: widget.onBack,
              icon: const Icon(Icons.home_rounded),
              label: const Text('Return to Feed'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Wallet',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            Text(
              _money(wallet.simulatedBalanceCents),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 14),
        WalletRow(
          icon: Icons.workspace_premium_rounded,
          title: 'No-ad premium',
          subtitle:
              'Simulated entitlement for eligible playback across the Fan App.',
          badge: wallet.hasNoAdsPremium ? 'Active' : 'Available',
          trailing: FilledButton.icon(
            key: const ValueKey('p6_buy_no_ad_button'),
            onPressed: wallet.hasNoAdsPremium || _busy
                ? null
                : () => _startPurchase(PurchaseKind.noAdsPremium),
            icon: const Icon(Icons.flash_on_rounded),
            label: const Text('Buy'),
          ),
        ),
        const SizedBox(height: 12),
        EntitlementRow(
          key: const ValueKey('p6_no_ad_entitlement'),
          title: 'PremiumNoAdEntitlement',
          subtitle: wallet.hasNoAdsPremium
              ? 'Ads are skipped for eligible playback.'
              : 'Buy no-ad premium to activate.',
          active: wallet.hasNoAdsPremium,
        ),
        const SizedBox(height: 18),
        WalletRow(
          icon: Icons.favorite_rounded,
          title: 'Solar Sarah membership',
          subtitle: 'Support creator-owned hosting and member posts.',
          badge: wallet.subscriptions.isEmpty ? 'Available' : 'Active',
          trailing: FilledButton.tonalIcon(
            key: const ValueKey('p6_buy_membership_button'),
            onPressed: wallet.subscriptions.isEmpty && !_busy
                ? () => _startPurchase(PurchaseKind.creatorMembership)
                : null,
            icon: const Icon(Icons.card_membership_rounded),
            label: const Text('Join'),
          ),
        ),
        const SizedBox(height: 12),
        for (final subscription in wallet.subscriptions)
          EntitlementRow(
            key: ValueKey('p6_membership_subscription_${subscription.id}'),
            title: subscription.tierName,
            subtitle:
                '${subscription.creatorName} membership at ${_money(subscription.monthlyPriceCents)} simulated monthly.',
            active: subscription.active,
          ),
        if (wallet.subscriptions.isEmpty)
          const EntitlementRow(
            title: 'Creator membership',
            subtitle: 'Join Solar Sarah to activate member access.',
            active: false,
          ),
        const SizedBox(height: 18),
        ReceiptStatement(
          key: const ValueKey('p6_allocation_statement'),
          title: 'How your support is allocated',
          emptyLabel: 'No active creator allocations yet.',
          rows:
              allocation?.allocations
                  .map(
                    (line) => ReceiptStatementRow(
                      icon: Icons.paid_rounded,
                      title: line.creatorName,
                      subtitle: line.reason,
                      trailing: _money(line.amountCents),
                    ),
                  )
                  .toList(growable: false) ??
              const [],
        ),
        const SizedBox(height: 18),
        SupportedCreatorsView(
          totalLabel: allocation == null
              ? 'No settled allocation yet'
              : '${_money(allocation.totalCents)} reconciled from receipts',
          rows:
              allocation?.allocations
                  .map(
                    (line) => SupportedCreatorRow(
                      creatorName: line.creatorName,
                      reason: line.reason,
                      amountLabel: _money(line.amountCents),
                    ),
                  )
                  .toList(growable: false) ??
              const [],
        ),
        if (_lastIntent != null) ...[
          const SizedBox(height: 14),
          ReceiptStatement(
            key: const ValueKey('p6_latest_purchase_receipt'),
            title: 'Latest purchase receipt',
            rows: [
              ReceiptStatementRow(
                icon: Icons.receipt_long_rounded,
                title: _lastIntent!.status == PaymentIntentStatus.succeeded
                    ? 'Confirmed'
                    : 'Pending confirmation',
                subtitle:
                    '${_lastIntent!.kind == PurchaseKind.noAdsPremium ? 'No-ad premium' : 'Creator membership'} payment intent ${_lastIntent!.id}',
                trailing: _money(_lastIntent!.amountCents),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

String _money(int cents) {
  final dollars = cents ~/ 100;
  final remainder = (cents % 100).toString().padLeft(2, '0');
  return '\$$dollars.$remainder';
}
