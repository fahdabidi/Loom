import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart'
    show DemoLocalStore, ReceiptRecord;

class ReceiptLedgerFake implements ReceiptLedgerApi {
  const ReceiptLedgerFake(
    this._store, {
    this.latency = const Duration(milliseconds: 80),
  });

  final DemoLocalStore _store;
  final Duration latency;

  @override
  Future<List<ReceiptView>> ingestReceipts({
    required List<ReceiptView> receipts,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final records = await _store.ingestReceipts(
      records: receipts.map(_toRecord).toList(growable: false),
      idempotencyKey: idempotencyKey,
    );
    return records.map(_mapReceipt).toList(growable: false);
  }

  @override
  Future<List<ReceiptView>> receiptsForContent(String contentId) async {
    await Future<void>.delayed(latency);
    final records = await _store.receiptsForContent(contentId);
    return records.map(_mapReceipt).toList(growable: false);
  }

  @override
  Future<List<ReceiptView>> receiptsForPassport(String passportId) async {
    await Future<void>.delayed(latency);
    final records = await _store.receiptsForPassport(passportId);
    return records.map(_mapReceipt).toList(growable: false);
  }
}

ReceiptRecord _toRecord(ReceiptView view) {
  return ReceiptRecord(
    id: view.id,
    type: view.type == ReceiptType.adImpression ? 'adImpression' : 'playback',
    passportId: view.passportId,
    contentId: view.contentId,
    authorizationId: view.authorizationId,
    summary: view.summary,
    createdAt: view.createdAt,
  );
}

ReceiptView _mapReceipt(ReceiptRecord record) {
  return ReceiptView(
    id: record.id,
    type: record.type == 'adImpression'
        ? ReceiptType.adImpression
        : ReceiptType.playback,
    passportId: record.passportId,
    contentId: record.contentId,
    authorizationId: record.authorizationId,
    summary: record.summary,
    createdAt: record.createdAt,
  );
}
