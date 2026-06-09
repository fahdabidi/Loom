import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_fake_backend/loom_fake_backend.dart';
import 'package:loom_local_store/a1_foundation_store_schema.dart';
import 'package:loom_seed_data/community_foundation_seed_data.dart';
import 'package:test/test.dart';

void main() {
  group('A1 foundation validation tests', () {
    test('vt_passport-ledger_create-resolve', () async {
      final backend = CommunityFoundationFakeBackend();
      final created = await backend.passport.createPassport(
        displayName: 'Ada Owner',
        actorId: communityFoundationSeed.ownerActorId,
        idempotencyKey: 'passport-create-1',
      );
      final repeated = await backend.passport.createPassport(
        displayName: 'Ada Owner',
        actorId: communityFoundationSeed.ownerActorId,
        idempotencyKey: 'passport-create-1',
      );
      final resolved = await backend.passport.resolvePassport(
        created.passportId,
      );

      expect(repeated.passportId, created.passportId);
      expect(resolved?.displayName, 'Ada Owner');
      expect(created.version, 1);
      expect(created.auditId, startsWith('audit_'));
    });

    test('vt_role-policy_effective-permission', () async {
      final backend = CommunityFoundationFakeBackend();
      final grant = await backend.rolePolicy.grantPermission(
        actorId: 'owner_ada',
        communityId: communityFoundationSeed.communityId,
        permission: 'protected.read',
        grantedBy: 'system',
        idempotencyKey: 'grant-protected-read',
      );
      final decision = await backend.rolePolicy.effectivePermission(
        actorId: 'owner_ada',
        communityId: communityFoundationSeed.communityId,
        permission: 'protected.read',
      );

      expect(grant.allowed, isTrue);
      expect(decision.allowed, isTrue);
      expect(decision.version, grant.version);
    });

    test('vt_core-vault_preferences', () async {
      final backend = CommunityFoundationFakeBackend();
      final saved = await backend.coreVault.setPreference(
        passportId: communityFoundationSeed.memberPassportId,
        key: 'theme',
        value: 'system',
        idempotencyKey: 'pref-theme',
      );
      final loaded = await backend.coreVault.getPreference(
        passportId: communityFoundationSeed.memberPassportId,
        key: 'theme',
      );

      expect(saved.version, 1);
      expect(loaded?.value, 'system');
    });

    test('vt_protected-vault_read-gated', () async {
      final backend = CommunityFoundationFakeBackend();
      final record = await backend.protectedVault.writeProtectedRecord(
        passportId: communityFoundationSeed.memberPassportId,
        field: 'care-request',
        value: 'needs weekday rides',
        visibility: CommunityProtectedVisibility.permissionGated,
        actorId: communityFoundationSeed.memberPassportId,
        idempotencyKey: 'protected-care',
      );
      final denied = await backend.protectedVault.readProtectedRecord(
        recordId: record.recordId,
        actorId: 'volunteer_1',
        communityId: communityFoundationSeed.communityId,
        requiredPermission: 'protected.read',
      );
      await backend.rolePolicy.grantPermission(
        actorId: 'volunteer_1',
        communityId: communityFoundationSeed.communityId,
        permission: 'protected.read',
        grantedBy: 'owner_ada',
        idempotencyKey: 'grant-volunteer-read',
      );
      final allowed = await backend.protectedVault.readProtectedRecord(
        recordId: record.recordId,
        actorId: 'volunteer_1',
        communityId: communityFoundationSeed.communityId,
        requiredPermission: 'protected.read',
      );

      expect(denied, isNull);
      expect(allowed?.redactedValue, 'n***');
      expect(record.auditId, startsWith('audit_'));
    });

    test('vt_connections_invite-permission', () async {
      final backend = CommunityFoundationFakeBackend();
      final invite = await backend.connections.invite(
        requesterPassportId: 'passport_a',
        targetPassportId: 'passport_b',
        idempotencyKey: 'invite-a-b',
      );
      await backend.connections.block(
        requesterPassportId: 'passport_a',
        targetPassportId: 'passport_b',
        idempotencyKey: 'block-a-b',
      );
      final canInvite = await backend.connections.canInvite(
        requesterPassportId: 'passport_a',
        targetPassportId: 'passport_b',
      );

      expect(invite.state, CommunityConnectionState.invited);
      expect(canInvite, isFalse);
    });

    test('vt_receipt-ledger_append', () async {
      final backend = CommunityFoundationFakeBackend();
      final receipt = await backend.receiptLedger.appendReceipt(
        passportId: communityFoundationSeed.memberPassportId,
        kind: 'dues.payment',
        amountCents: 2500,
        currency: 'USD',
        summary: 'June dues',
        idempotencyKey: 'receipt-june-dues',
      );
      final repeated = await backend.receiptLedger.appendReceipt(
        passportId: communityFoundationSeed.memberPassportId,
        kind: 'dues.payment',
        amountCents: 2500,
        currency: 'USD',
        summary: 'June dues',
        idempotencyKey: 'receipt-june-dues',
      );
      final receipts = await backend.receiptLedger.listReceipts(
        communityFoundationSeed.memberPassportId,
      );

      expect(repeated.receiptId, receipt.receiptId);
      expect(receipts, hasLength(1));
      expect(receipts.single.amountCents, 2500);
    });

    test('vt_event-bus_publish', () async {
      final backend = CommunityFoundationFakeBackend();
      final event = await backend.eventBus.publish(
        type: 'community.member.joined',
        sourceComponent: 'passport-ledger',
        subjectId: communityFoundationSeed.memberPassportId,
        payload: {'communityId': communityFoundationSeed.communityId},
        idempotencyKey: 'event-member-joined',
      );
      final replay = await backend.eventBus.replay(
        type: 'community.member.joined',
      );

      expect(event.version, 1);
      expect(replay.map((item) => item.eventId), contains(event.eventId));
    });

    test('vt_builder-app-id_signing-scope', () async {
      final backend = CommunityFoundationFakeBackend();
      final app = await backend.builderAppIds.registerBuilderApp(
        builderId: 'builder_ada',
        signingScope: 'community.extension.sign',
        idempotencyKey: 'builder-app-1',
      );
      final verified = await backend.builderAppIds.verifySigningScope(
        appId: app.appId,
        signingScope: 'community.extension.sign',
      );
      final wrongScope = await backend.builderAppIds.verifySigningScope(
        appId: app.appId,
        signingScope: 'payments.sign',
      );

      expect(verified, isTrue);
      expect(wrongScope, isFalse);
      expect(app.keyId, startsWith('key_'));
    });

    test('loom-local-store owned table manifest is disjoint', () {
      final tableNames = A1FoundationStoreSchema.tables
          .map((table) => table.tableName)
          .toSet();
      final componentIds = A1FoundationStoreSchema.tables
          .map((table) => table.componentId)
          .toSet();

      expect(tableNames, hasLength(A1FoundationStoreSchema.tables.length));
      expect(componentIds, contains('passport-ledger'));
      expect(componentIds, contains('builder-app-id-service'));
    });
  });

  group('A1 provider-authored consumer-contract kits', () {
    test(
      'ct_role-policy__extension-runtime_effective-permission',
      () {},
      skip: 'extension-runtime-bridge is built in A5',
    );
    test(
      'ct_protected-vault__ads_no-fill-sensitive',
      () {},
      skip: 'ad-decision-service is built in A4b',
    );
    test(
      'ct_receipt-ledger__wallet_append-payment',
      () {},
      skip: 'wallet-dues-donations is built in A4b',
    );
    test(
      'ct_event-bus__rule-engine_publish-replay',
      () {},
      skip: 'rule-engine is built in A5',
    );
    test(
      'ct_connections__invitation_blocked-path',
      () {},
      skip: 'invitation-service is built in A2',
    );
    test(
      'ct_builder-app-id__extension-registry_signing-scope',
      () {},
      skip: 'extension-registry is built in A2',
    );
  });
}
