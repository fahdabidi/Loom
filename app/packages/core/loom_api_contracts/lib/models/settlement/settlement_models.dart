import '../receipt/receipt_models.dart';

class RevenueBreakdown {
  const RevenueBreakdown({required this.label, required this.amountCents});

  final String label;
  final int amountCents;
}

class CreatorPayoutStatement {
  const CreatorPayoutStatement({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    required this.totalCents,
    required this.bySource,
    required this.byIntent,
    required this.recentReceipts,
    required this.updatedAt,
  });

  final String id;
  final String creatorId;
  final String creatorName;
  final int totalCents;
  final List<RevenueBreakdown> bySource;
  final List<RevenueBreakdown> byIntent;
  final List<ReceiptView> recentReceipts;
  final DateTime updatedAt;
}

class AllocationLine {
  const AllocationLine({
    required this.creatorId,
    required this.creatorName,
    required this.amountCents,
    required this.reason,
  });

  final String creatorId;
  final String creatorName;
  final int amountCents;
  final String reason;
}

class FanSubscriptionAllocationStatement {
  const FanSubscriptionAllocationStatement({
    required this.id,
    required this.passportId,
    required this.totalCents,
    required this.allocations,
    required this.updatedAt,
  });

  final String id;
  final String passportId;
  final int totalCents;
  final List<AllocationLine> allocations;
  final DateTime updatedAt;
}
