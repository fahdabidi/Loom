import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart'
    hide PaymentIntent, Subscription, Wallet;

class FanWalletFake implements FanWalletApi {
  const FanWalletFake(
    this._store, {
    this.latency = const Duration(milliseconds: 100),
  });

  final DemoLocalStore _store;
  final Duration latency;

  @override
  Future<Wallet> getWallet(String passportId) async {
    await Future<void>.delayed(latency);
    return _mapWallet(await _store.wallet(passportId));
  }

  @override
  Future<PaymentIntent> createPaymentIntent({
    required String passportId,
    required PurchaseKind kind,
    String? creatorId,
    String? tierId,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final record = await _store.createPaymentIntent(
      passportId: passportId,
      kind: _purchaseKindValue(kind),
      creatorId: creatorId,
      tierId: tierId,
      idempotencyKey: idempotencyKey,
    );
    return _mapPaymentIntent(record);
  }

  @override
  Future<PaymentIntent> confirmPaymentIntent({
    required String paymentIntentId,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final record = await _store.confirmPaymentIntent(
      paymentIntentId: paymentIntentId,
      idempotencyKey: idempotencyKey,
    );
    return _mapPaymentIntent(record);
  }

  @override
  Future<List<Subscription>> listSubscriptions(String passportId) async {
    await Future<void>.delayed(latency);
    final records = await _store.subscriptionsForPassport(passportId);
    return records.map(_mapSubscription).toList(growable: false);
  }
}

Wallet _mapWallet(WalletRecord record) {
  return Wallet(
    passportId: record.passportId,
    currency: record.currency,
    simulatedBalanceCents: record.simulatedBalanceCents,
    hasNoAdsPremium: record.hasNoAdsPremium,
    subscriptions: record.subscriptions.map(_mapSubscription).toList(),
    updatedAt: record.updatedAt,
  );
}

PaymentIntent _mapPaymentIntent(PaymentIntentRecord record) {
  return PaymentIntent(
    id: record.id,
    passportId: record.passportId,
    kind: _purchaseKind(record.kind),
    creatorId: record.creatorId,
    creatorName: record.creatorName,
    tierId: record.tierId,
    tierName: record.tierName,
    amountCents: record.amountCents,
    currency: record.currency,
    status: _paymentStatus(record.status),
    createdAt: record.createdAt,
    confirmedAt: record.confirmedAt,
  );
}

Subscription _mapSubscription(SubscriptionRecord record) {
  return Subscription(
    id: record.id,
    passportId: record.passportId,
    creatorId: record.creatorId,
    creatorName: record.creatorName,
    tierId: record.tierId,
    tierName: record.tierName,
    monthlyPriceCents: record.monthlyPriceCents,
    active: record.active,
    startedAt: record.startedAt,
  );
}

String _purchaseKindValue(PurchaseKind kind) {
  switch (kind) {
    case PurchaseKind.noAdsPremium:
      return 'noAdsPremium';
    case PurchaseKind.creatorMembership:
      return 'creatorMembership';
  }
}

PurchaseKind _purchaseKind(String value) {
  switch (value) {
    case 'creatorMembership':
      return PurchaseKind.creatorMembership;
    case 'noAdsPremium':
    default:
      return PurchaseKind.noAdsPremium;
  }
}

PaymentIntentStatus _paymentStatus(String value) {
  switch (value) {
    case 'succeeded':
      return PaymentIntentStatus.succeeded;
    case 'requiresConfirmation':
    default:
      return PaymentIntentStatus.requiresConfirmation;
  }
}
