import '../models/wallet/wallet_models.dart';

abstract class FanWalletApi {
  Future<Wallet> getWallet(String passportId);

  Future<PaymentIntent> createPaymentIntent({
    required String passportId,
    required PurchaseKind kind,
    String? creatorId,
    String? tierId,
    required String idempotencyKey,
  });

  Future<PaymentIntent> confirmPaymentIntent({
    required String paymentIntentId,
    required String idempotencyKey,
  });

  Future<List<Subscription>> listSubscriptions(String passportId);
}
