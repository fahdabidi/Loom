import 'package:flutter_test/flutter_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_fake_backend/loom_fake_backend.dart';
import 'package:loom_local_store/loom_local_store.dart';

void main() {
  test(
    'payment intents are idempotent and grants are not duplicated',
    () async {
      final store = await DemoLocalStore.seeded();
      addTearDown(store.close);
      final wallet = FanWalletFake(store, latency: Duration.zero);

      final first = await wallet.createPaymentIntent(
        passportId: 'passport_demo_fan',
        kind: PurchaseKind.noAdsPremium,
        idempotencyKey: 'p6-idempotent-no-ad',
      );
      final second = await wallet.createPaymentIntent(
        passportId: 'passport_demo_fan',
        kind: PurchaseKind.noAdsPremium,
        idempotencyKey: 'p6-idempotent-no-ad',
      );

      expect(second.id, first.id);

      final confirmed = await wallet.confirmPaymentIntent(
        paymentIntentId: first.id,
        idempotencyKey: 'p6-confirm-no-ad',
      );
      final repeated = await wallet.confirmPaymentIntent(
        paymentIntentId: first.id,
        idempotencyKey: 'p6-confirm-no-ad-again',
      );
      final result = await wallet.getWallet('passport_demo_fan');

      expect(confirmed.status, PaymentIntentStatus.succeeded);
      expect(repeated.status, PaymentIntentStatus.succeeded);
      expect(result.hasNoAdsPremium, isTrue);
    },
  );

  test('entitlement checks are batched', () async {
    final store = await DemoLocalStore.seeded();
    addTearDown(store.close);
    final ledger = EntitlementLedgerFake(store, latency: Duration.zero);

    await ledger.grantEntitlement(
      passportId: 'passport_demo_fan',
      code: 'premium_no_ads',
      sourcePaymentIntentId: 'pi_test',
      idempotencyKey: 'p6-grant-premium',
    );
    final result = await ledger.checkEntitlements(
      passportId: 'passport_demo_fan',
      codes: const ['premium_no_ads', 'membership:creator_solar_sarah'],
    );

    expect(result.has('premium_no_ads'), isTrue);
    expect(result.has('membership:creator_solar_sarah'), isFalse);
  });

  test('creator payout includes source and intent breakdowns', () async {
    final store = await DemoLocalStore.seeded();
    addTearDown(store.close);
    final settlement = SettlementEngineFake(store, latency: Duration.zero);

    await settlement.runSettlement(idempotencyKey: 'p6-settlement-api-test');
    final statement = await settlement.getCreatorPayoutStatement(
      creatorId: 'creator_solar_sarah',
    );

    expect(statement.totalCents, greaterThan(0));
    expect(statement.bySource.map((row) => row.label), contains('Memberships'));
    expect(statement.byIntent.map((row) => row.label), contains('Support'));
    expect(statement.recentReceipts, isNotEmpty);
  });

  test('fan allocation statement reflects membership support', () async {
    final store = await DemoLocalStore.seeded();
    addTearDown(store.close);
    final wallet = FanWalletFake(store, latency: Duration.zero);
    final settlement = SettlementEngineFake(store, latency: Duration.zero);

    final intent = await wallet.createPaymentIntent(
      passportId: 'passport_demo_fan',
      kind: PurchaseKind.creatorMembership,
      creatorId: 'creator_solar_sarah',
      idempotencyKey: 'p6-membership-api-test',
    );
    await wallet.confirmPaymentIntent(
      paymentIntentId: intent.id,
      idempotencyKey: 'p6-membership-confirm-api-test',
    );
    await settlement.runSettlement(idempotencyKey: 'p6-allocation-api-test');
    final statement = await settlement.getFanSubscriptionAllocation(
      passportId: 'passport_demo_fan',
    );

    expect(statement.totalCents, 799);
    expect(statement.allocations.single.creatorName, 'Solar Sarah');
  });
}
