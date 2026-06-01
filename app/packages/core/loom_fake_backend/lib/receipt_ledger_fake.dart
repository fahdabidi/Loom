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
    type: _receiptTypeValue(view.type),
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
    type: _receiptType(record.type),
    passportId: record.passportId,
    contentId: record.contentId,
    authorizationId: record.authorizationId,
    summary: record.summary,
    createdAt: record.createdAt,
  );
}

String _receiptTypeValue(ReceiptType type) {
  switch (type) {
    case ReceiptType.playback:
      return 'playback';
    case ReceiptType.adImpression:
      return 'adImpression';
    case ReceiptType.aiUsage:
      return 'aiUsage';
    case ReceiptType.sourceAttribution:
      return 'sourceAttribution';
    case ReceiptType.payment:
      return 'payment';
    case ReceiptType.membership:
      return 'membership';
    case ReceiptType.premiumNoAd:
      return 'premiumNoAd';
  }
}

ReceiptType _receiptType(String value) {
  switch (value) {
    case 'playback':
      return ReceiptType.playback;
    case 'adImpression':
      return ReceiptType.adImpression;
    case 'aiUsage':
      return ReceiptType.aiUsage;
    case 'sourceAttribution':
      return ReceiptType.sourceAttribution;
    case 'payment':
      return ReceiptType.payment;
    case 'membership':
      return ReceiptType.membership;
    case 'premiumNoAd':
      return ReceiptType.premiumNoAd;
  }
  return ReceiptType.playback;
}
