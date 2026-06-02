enum PurchaseKind { noAdsPremium, creatorMembership, extensionHype }

enum PaymentIntentStatus { requiresConfirmation, succeeded }

class Wallet {
  const Wallet({
    required this.passportId,
    required this.currency,
    required this.simulatedBalanceCents,
    required this.hasNoAdsPremium,
    required this.subscriptions,
    required this.updatedAt,
  });

  final String passportId;
  final String currency;
  final int simulatedBalanceCents;
  final bool hasNoAdsPremium;
  final List<Subscription> subscriptions;
  final DateTime updatedAt;
}

class PaymentIntent {
  const PaymentIntent({
    required this.id,
    required this.passportId,
    required this.kind,
    required this.amountCents,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.creatorId,
    this.creatorName,
    this.tierId,
    this.tierName,
    this.confirmedAt,
  });

  final String id;
  final String passportId;
  final PurchaseKind kind;
  final String? creatorId;
  final String? creatorName;
  final String? tierId;
  final String? tierName;
  final int amountCents;
  final String currency;
  final PaymentIntentStatus status;
  final DateTime createdAt;
  final DateTime? confirmedAt;
}

class Subscription {
  const Subscription({
    required this.id,
    required this.passportId,
    required this.creatorId,
    required this.creatorName,
    required this.tierId,
    required this.tierName,
    required this.monthlyPriceCents,
    required this.active,
    required this.startedAt,
  });

  final String id;
  final String passportId;
  final String creatorId;
  final String creatorName;
  final String tierId;
  final String tierName;
  final int monthlyPriceCents;
  final bool active;
  final DateTime startedAt;
}
