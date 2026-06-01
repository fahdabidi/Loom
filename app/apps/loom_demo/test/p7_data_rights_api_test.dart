import 'package:flutter_test/flutter_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_fake_backend/loom_fake_backend.dart';
import 'package:loom_local_store/loom_local_store.dart';

void main() {
  test(
    'approved grants return only narrowed fields and emit a receipt',
    () async {
      final store = await DemoLocalStore.seeded();
      addTearDown(store.close);
      final audience = CreatorAudienceFake(store, latency: Duration.zero);
      final passport = FanPassportFake(store, latency: Duration.zero);

      final request = await audience.createDataGrantRequest(
        creatorId: 'creator_solar_sarah',
        passportId: 'passport_demo_fan',
        fields: const ['interest_categories', 'interest_tokens'],
        purpose: 'Audience planning',
        retention: 'Demo only',
        valueExchange: 'Better creator-owned recommendations',
        idempotencyKey: 'p7-api-request',
      );
      final approved = await passport.reviewDataGrantRequest(
        requestId: request.id,
        passportId: 'passport_demo_fan',
        state: ConsentGrantState.approved,
        approvedFields: request.fields,
        idempotencyKey: 'p7-api-approve',
      );
      await passport.narrowGrant(
        grantId: approved.id,
        approvedFields: const ['interest_categories'],
        idempotencyKey: 'p7-api-narrow',
      );

      final data = await audience.queryPermissionedInterestData(
        creatorId: 'creator_solar_sarah',
        passportId: 'passport_demo_fan',
        purpose: 'Audience planning read',
        idempotencyKey: 'p7-api-query',
      );
      final receipts = await audience.dataAccessReceipts('passport_demo_fan');

      expect(data.fields, const ['interest_categories']);
      expect(data.values.keys, contains('interest_categories'));
      expect(data.values.keys, isNot(contains('interest_tokens')));
      expect(receipts, hasLength(1));
      expect(receipts.single.fields, const ['interest_categories']);
    },
  );

  test(
    'revoked grants block future access without emitting receipts',
    () async {
      final store = await DemoLocalStore.seeded();
      addTearDown(store.close);
      final audience = CreatorAudienceFake(store, latency: Duration.zero);
      final passport = FanPassportFake(store, latency: Duration.zero);

      final request = await audience.createDataGrantRequest(
        creatorId: 'creator_solar_sarah',
        passportId: 'passport_demo_fan',
        fields: const ['interest_categories'],
        purpose: 'Audience planning',
        retention: 'Demo only',
        valueExchange: 'Visible receipts',
        idempotencyKey: 'p7-api-revoke-request',
      );
      final grant = await passport.reviewDataGrantRequest(
        requestId: request.id,
        passportId: 'passport_demo_fan',
        state: ConsentGrantState.approved,
        approvedFields: request.fields,
        idempotencyKey: 'p7-api-revoke-approve',
      );
      await audience.queryPermissionedInterestData(
        creatorId: 'creator_solar_sarah',
        passportId: 'passport_demo_fan',
        purpose: 'Before revoke',
        idempotencyKey: 'p7-api-revoke-query-before',
      );
      await passport.revokeGrant(
        grantId: grant.id,
        idempotencyKey: 'p7-api-revoke',
      );

      final after = await audience.queryPermissionedInterestData(
        creatorId: 'creator_solar_sarah',
        passportId: 'passport_demo_fan',
        purpose: 'After revoke',
        idempotencyKey: 'p7-api-revoke-query-after',
      );
      final receipts = await audience.dataAccessReceipts('passport_demo_fan');

      expect(after.fields, isEmpty);
      expect(receipts, hasLength(1));
    },
  );

  test('category defaults auto-deny new matching grant requests', () async {
    final store = await DemoLocalStore.seeded();
    addTearDown(store.close);
    final audience = CreatorAudienceFake(store, latency: Duration.zero);
    final passport = FanPassportFake(store, latency: Duration.zero);

    await passport.setCategoryDefault(
      passportId: 'passport_demo_fan',
      category: 'home-energy',
      state: ConsentGrantState.denied,
      idempotencyKey: 'p7-api-default-deny',
    );
    final request = await audience.createDataGrantRequest(
      creatorId: 'creator_solar_sarah',
      passportId: 'passport_demo_fan',
      fields: const ['interest_categories'],
      purpose: 'Default denied request',
      retention: 'Demo only',
      valueExchange: 'Visible default behavior',
      idempotencyKey: 'p7-api-default-request',
    );

    expect(request.state, ConsentGrantState.denied);
    expect(await audience.pendingGrantRequests('passport_demo_fan'), isEmpty);
  });

  test(
    'relationship controls make contact private and record tombstones',
    () async {
      final store = await DemoLocalStore.seeded();
      addTearDown(store.close);
      final passport = FanPassportFake(store, latency: Duration.zero);

      final contact = await passport.revokeDirectContact(
        passportId: 'passport_demo_fan',
        creatorId: 'creator_solar_sarah',
        idempotencyKey: 'p7-api-contact-private',
      );
      final tombstone = await passport.requestTombstone(
        passportId: 'passport_demo_fan',
        creatorId: 'creator_solar_sarah',
        idempotencyKey: 'p7-api-tombstone',
      );

      expect(contact.visibility, FollowVisibility.private);
      expect(contact.blocked, isFalse);
      expect(tombstone.creatorId, 'creator_solar_sarah');
    },
  );
}
