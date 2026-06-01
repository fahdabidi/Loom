import '../models/receipt/receipt_models.dart';

abstract class ReceiptLedgerApi {
  Future<List<ReceiptView>> ingestReceipts({
    required List<ReceiptView> receipts,
    required String idempotencyKey,
  });

  Future<List<ReceiptView>> receiptsForPassport(String passportId);

  Future<List<ReceiptView>> receiptsForContent(String contentId);
}
