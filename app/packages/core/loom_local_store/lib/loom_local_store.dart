import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:loom_seed_data/loom_seed_data.dart';

part 'loom_local_store.g.dart';

class Creators extends Table {
  TextColumn get id => text()();
  TextColumn get handle => text()();
  TextColumn get displayName => text()();
  TextColumn get vertical => text()();
  TextColumn get avatarRef => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ContentItems extends Table {
  TextColumn get id => text()();
  TextColumn get creatorId => text().references(Creators, #id)();
  TextColumn get contentType => text()();
  TextColumn get title => text()();
  TextColumn get summary => text()();
  TextColumn get thumbnailRef => text()();
  DateTimeColumn get createdAt => dateTime()();
  RealColumn get perfVelocity => real()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ContentManifests extends Table {
  TextColumn get id => text()();
  TextColumn get channelId => text()();
  TextColumn get contentType => text()();
  TextColumn get title => text()();
  TextColumn get summary => text()();
  TextColumn get accessMode => text()();
  TextColumn get monetizationMode => text()();
  TextColumn get thumbnailRef => text()();
  IntColumn get schemaVersion => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class MonetizationManifests extends Table {
  TextColumn get channelId => text()();
  BoolColumn get membershipsEnabled => boolean()();
  TextColumn get memberOnlyContentIdsJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {channelId};
}

class CreatorAdPolicies extends Table {
  TextColumn get channelId => text()();
  TextColumn get allowedCategoriesJson => text()();
  TextColumn get blockedCategoriesJson => text()();
  TextColumn get formatsJson => text()();
  TextColumn get surfacesJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {channelId};
}

class MembershipTiers extends Table {
  TextColumn get id => text()();
  TextColumn get channelId => text()();
  TextColumn get name => text()();
  IntColumn get monthlyPriceCents => integer()();
  TextColumn get benefitsJson => text()();
  TextColumn get entitlementCode => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AiContentPolicies extends Table {
  TextColumn get channelId => text()();
  BoolColumn get archiveQaEnabled => boolean()();
  BoolColumn get summariesEnabled => boolean()();
  BoolColumn get citationRequired => boolean()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {channelId};
}

class ImportJobs extends Table {
  TextColumn get id => text()();
  TextColumn get channelId => text()();
  TextColumn get sourcePlatform => text()();
  TextColumn get state => text()();
  IntColumn get pollCount => integer()();
  TextColumn get itemsJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ExternalContentRefs extends Table {
  TextColumn get id => text()();
  TextColumn get jobId => text()();
  TextColumn get channelId => text()();
  TextColumn get sourcePlatform => text()();
  TextColumn get externalId => text()();
  TextColumn get contentId => text()();
  TextColumn get title => text()();
  TextColumn get summary => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ContentPerf extends Table {
  TextColumn get contentId => text()();
  RealColumn get velocity => real()();
  RealColumn get completionRate => real()();
  IntColumn get saves => integer()();
  IntColumn get shares => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {contentId};
}

class EntitlementDefinitions extends Table {
  TextColumn get id => text()();
  TextColumn get channelId => text()();
  TextColumn get tierId => text()();
  TextColumn get code => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class FanPassports extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text()();
  TextColumn get activePersonaId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Personas extends Table {
  TextColumn get id => text()();
  TextColumn get passportId => text().references(FanPassports, #id)();
  TextColumn get label => text()();
  BoolColumn get isActive => boolean()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Follows extends Table {
  TextColumn get id => text()();
  TextColumn get passportId => text().references(FanPassports, #id)();
  TextColumn get creatorId => text().references(Creators, #id)();
  TextColumn get visibility => text()();
  BoolColumn get blocked => boolean()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ConsentGrants extends Table {
  TextColumn get id => text()();
  TextColumn get passportId => text().references(FanPassports, #id)();
  TextColumn get grantType => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class InterestTaxonomy extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();
  TextColumn get category => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class FanInterestProfiles extends Table {
  TextColumn get passportId => text().references(FanPassports, #id)();
  TextColumn get interestIdsJson => text()();
  TextColumn get dislikedInterestIdsJson => text()();
  TextColumn get dislikedCreatorIdsJson => text()();
  TextColumn get mutedProviderIdsJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {passportId};
}

class AdPreferences extends Table {
  TextColumn get passportId => text().references(FanPassports, #id)();
  BoolColumn get personalizedAds => boolean()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {passportId};
}

class CreatorChannels extends Table {
  TextColumn get id => text()();
  TextColumn get ownerPassportId => text()();
  TextColumn get displayName => text()();
  TextColumn get handle => text()();
  TextColumn get vertical => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ChannelManifests extends Table {
  TextColumn get channelId => text().references(CreatorChannels, #id)();
  TextColumn get displayName => text()();
  TextColumn get handle => text()();
  TextColumn get description => text()();
  TextColumn get category => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {channelId};
}

class HostingContracts extends Table {
  TextColumn get id => text()();
  TextColumn get channelId => text().references(CreatorChannels, #id)();
  TextColumn get provider => text()();
  TextColumn get status => text()();
  TextColumn get termsVersion => text()();
  DateTimeColumn get acceptedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class IdempotencyRecords extends Table {
  TextColumn get key => text()();
  TextColumn get targetType => text()();
  TextColumn get targetId => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class KvMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    Creators,
    ContentItems,
    ContentManifests,
    MonetizationManifests,
    CreatorAdPolicies,
    MembershipTiers,
    AiContentPolicies,
    ImportJobs,
    ExternalContentRefs,
    ContentPerf,
    EntitlementDefinitions,
    FanPassports,
    Personas,
    Follows,
    ConsentGrants,
    InterestTaxonomy,
    FanInterestProfiles,
    AdPreferences,
    CreatorChannels,
    ChannelManifests,
    HostingContracts,
    IdempotencyRecords,
    KvMeta,
  ],
)
class LoomDatabase extends _$LoomDatabase {
  LoomDatabase(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(fanPassports);
        await m.createTable(personas);
        await m.createTable(follows);
        await m.createTable(consentGrants);
        await m.createTable(interestTaxonomy);
        await m.createTable(fanInterestProfiles);
        await m.createTable(adPreferences);
        await m.createTable(creatorChannels);
        await m.createTable(channelManifests);
        await m.createTable(hostingContracts);
        await m.createTable(idempotencyRecords);
      }
      if (from < 3) {
        await m.createTable(contentManifests);
        await m.createTable(monetizationManifests);
        await m.createTable(creatorAdPolicies);
        await m.createTable(membershipTiers);
        await m.createTable(aiContentPolicies);
        await m.createTable(importJobs);
        await m.createTable(externalContentRefs);
        await m.createTable(contentPerf);
        await m.createTable(entitlementDefinitions);
      }
    },
  );
}

class CreatorRecord {
  const CreatorRecord({
    required this.id,
    required this.handle,
    required this.displayName,
    required this.vertical,
    required this.avatarRef,
  });

  final String id;
  final String handle;
  final String displayName;
  final String vertical;
  final String avatarRef;
}

class ContentRecord {
  const ContentRecord({
    required this.id,
    required this.creatorId,
    required this.contentType,
    required this.title,
    required this.summary,
    required this.thumbnailRef,
    required this.createdAt,
    required this.perfVelocity,
  });

  final String id;
  final String creatorId;
  final String contentType;
  final String title;
  final String summary;
  final String thumbnailRef;
  final DateTime createdAt;
  final double perfVelocity;
}

class FanPassportRecord {
  const FanPassportRecord({
    required this.id,
    required this.displayName,
    required this.activePersonaId,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final String activePersonaId;
  final DateTime createdAt;
}

class PersonaRecord {
  const PersonaRecord({
    required this.id,
    required this.passportId,
    required this.label,
    required this.isActive,
  });

  final String id;
  final String passportId;
  final String label;
  final bool isActive;
}

class FollowRecord {
  const FollowRecord({
    required this.id,
    required this.passportId,
    required this.creatorId,
    required this.creatorDisplayName,
    required this.visibility,
    required this.blocked,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String passportId;
  final String creatorId;
  final String creatorDisplayName;
  final String visibility;
  final bool blocked;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class ConsentGrantRecord {
  const ConsentGrantRecord({
    required this.id,
    required this.passportId,
    required this.grantType,
    required this.createdAt,
  });

  final String id;
  final String passportId;
  final String grantType;
  final DateTime createdAt;
}

class InterestTokenRecord {
  const InterestTokenRecord({
    required this.id,
    required this.label,
    required this.category,
  });

  final String id;
  final String label;
  final String category;
}

class InterestProfileRecord {
  const InterestProfileRecord({
    required this.passportId,
    required this.interests,
    required this.dislikedInterestIds,
    required this.dislikedCreatorIds,
    required this.mutedProviderIds,
    required this.updatedAt,
  });

  final String passportId;
  final List<InterestTokenRecord> interests;
  final List<String> dislikedInterestIds;
  final List<String> dislikedCreatorIds;
  final List<String> mutedProviderIds;
  final DateTime updatedAt;
}

class AdPreferencesRecord {
  const AdPreferencesRecord({
    required this.passportId,
    required this.personalizedAds,
    required this.updatedAt,
  });

  final String passportId;
  final bool personalizedAds;
  final DateTime updatedAt;
}

class CreatorChannelRecord {
  const CreatorChannelRecord({
    required this.id,
    required this.ownerPassportId,
    required this.displayName,
    required this.handle,
    required this.vertical,
    required this.createdAt,
  });

  final String id;
  final String ownerPassportId;
  final String displayName;
  final String handle;
  final String vertical;
  final DateTime createdAt;
}

class CreatorChannelManifestRecord {
  const CreatorChannelManifestRecord({
    required this.channelId,
    required this.displayName,
    required this.handle,
    required this.description,
    required this.category,
    required this.createdAt,
  });

  final String channelId;
  final String displayName;
  final String handle;
  final String description;
  final String category;
  final DateTime createdAt;
}

class HostingContractRecord {
  const HostingContractRecord({
    required this.id,
    required this.channelId,
    required this.provider,
    required this.status,
    required this.termsVersion,
    required this.acceptedAt,
  });

  final String id;
  final String channelId;
  final String provider;
  final String status;
  final String termsVersion;
  final DateTime acceptedAt;
}

class ContentManifestRecord {
  const ContentManifestRecord({
    required this.id,
    required this.channelId,
    required this.contentType,
    required this.title,
    required this.summary,
    required this.accessMode,
    required this.monetizationMode,
    required this.thumbnailRef,
    required this.schemaVersion,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String channelId;
  final String contentType;
  final String title;
  final String summary;
  final String accessMode;
  final String monetizationMode;
  final String thumbnailRef;
  final int schemaVersion;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class MonetizationManifestRecord {
  const MonetizationManifestRecord({
    required this.channelId,
    required this.membershipsEnabled,
    required this.memberOnlyContentIds,
    required this.updatedAt,
  });

  final String channelId;
  final bool membershipsEnabled;
  final List<String> memberOnlyContentIds;
  final DateTime updatedAt;
}

class CreatorAdPolicyRecord {
  const CreatorAdPolicyRecord({
    required this.channelId,
    required this.allowedCategories,
    required this.blockedCategories,
    required this.formats,
    required this.surfaces,
    required this.updatedAt,
  });

  final String channelId;
  final List<String> allowedCategories;
  final List<String> blockedCategories;
  final List<String> formats;
  final List<String> surfaces;
  final DateTime updatedAt;
}

class MembershipTierRecord {
  const MembershipTierRecord({
    required this.id,
    required this.channelId,
    required this.name,
    required this.monthlyPriceCents,
    required this.benefits,
    required this.entitlementCode,
    required this.createdAt,
  });

  final String id;
  final String channelId;
  final String name;
  final int monthlyPriceCents;
  final List<String> benefits;
  final String entitlementCode;
  final DateTime createdAt;
}

class AiContentPolicyRecord {
  const AiContentPolicyRecord({
    required this.channelId,
    required this.archiveQaEnabled,
    required this.summariesEnabled,
    required this.citationRequired,
    required this.updatedAt,
  });

  final String channelId;
  final bool archiveQaEnabled;
  final bool summariesEnabled;
  final bool citationRequired;
  final DateTime updatedAt;
}

class ExternalContentRefRecord {
  const ExternalContentRefRecord({
    required this.id,
    required this.jobId,
    required this.channelId,
    required this.sourcePlatform,
    required this.externalId,
    required this.contentId,
    required this.title,
    required this.summary,
    required this.createdAt,
  });

  final String id;
  final String jobId;
  final String channelId;
  final String sourcePlatform;
  final String externalId;
  final String contentId;
  final String title;
  final String summary;
  final DateTime createdAt;
}

class ImportJobRecord {
  const ImportJobRecord({
    required this.id,
    required this.channelId,
    required this.sourcePlatform,
    required this.state,
    required this.references,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String channelId;
  final String sourcePlatform;
  final String state;
  final List<ExternalContentRefRecord> references;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class ContentPerformanceRecord {
  const ContentPerformanceRecord({
    required this.contentId,
    required this.velocity,
    required this.completionRate,
    required this.saves,
    required this.shares,
    required this.updatedAt,
  });

  final String contentId;
  final double velocity;
  final double completionRate;
  final int saves;
  final int shares;
  final DateTime updatedAt;
}

class EntitlementDefinitionRecord {
  const EntitlementDefinitionRecord({
    required this.id,
    required this.channelId,
    required this.tierId,
    required this.code,
    required this.createdAt,
  });

  final String id;
  final String channelId;
  final String tierId;
  final String code;
  final DateTime createdAt;
}

class DemoLocalStore {
  DemoLocalStore._(this._db);

  final LoomDatabase _db;

  static Future<DemoLocalStore> open({
    required File databaseFile,
    SeedWorld? seed,
  }) async {
    final store = DemoLocalStore._(LoomDatabase(NativeDatabase(databaseFile)));
    await store.resetDemo(seed: seed);
    return store;
  }

  static Future<DemoLocalStore> seeded({SeedWorld? seed}) async {
    final store = DemoLocalStore._(LoomDatabase(NativeDatabase.memory()));
    await store.resetDemo(seed: seed);
    return store;
  }

  Future<void> close() => _db.close();

  Future<void> resetDemo({SeedWorld? seed}) async {
    final world = seed ?? seedV1;

    await _db.transaction(() async {
      await _db.delete(_db.entitlementDefinitions).go();
      await _db.delete(_db.contentPerf).go();
      await _db.delete(_db.externalContentRefs).go();
      await _db.delete(_db.importJobs).go();
      await _db.delete(_db.aiContentPolicies).go();
      await _db.delete(_db.membershipTiers).go();
      await _db.delete(_db.creatorAdPolicies).go();
      await _db.delete(_db.monetizationManifests).go();
      await _db.delete(_db.contentManifests).go();
      await _db.delete(_db.hostingContracts).go();
      await _db.delete(_db.channelManifests).go();
      await _db.delete(_db.creatorChannels).go();
      await _db.delete(_db.adPreferences).go();
      await _db.delete(_db.fanInterestProfiles).go();
      await _db.delete(_db.interestTaxonomy).go();
      await _db.delete(_db.consentGrants).go();
      await _db.delete(_db.follows).go();
      await _db.delete(_db.personas).go();
      await _db.delete(_db.fanPassports).go();
      await _db.delete(_db.idempotencyRecords).go();
      await _db.delete(_db.contentItems).go();
      await _db.delete(_db.creators).go();
      await _db.delete(_db.kvMeta).go();

      await _db.batch((batch) {
        batch.insertAll(
          _db.creators,
          world.creators.map(
            (creator) => CreatorsCompanion.insert(
              id: creator.id,
              handle: creator.handle,
              displayName: creator.displayName,
              vertical: creator.vertical,
              avatarRef: creator.avatarRef,
            ),
          ),
        );

        batch.insertAll(
          _db.contentItems,
          world.content.map(
            (content) => ContentItemsCompanion.insert(
              id: content.id,
              creatorId: content.creatorId,
              contentType: content.contentType,
              title: content.title,
              summary: content.summary,
              thumbnailRef: content.thumbnailRef,
              createdAt: content.createdAt,
              perfVelocity: content.perfVelocity,
            ),
          ),
        );

        batch.insertAll(
          _db.interestTaxonomy,
          world.interestTaxonomy.map(
            (token) => InterestTaxonomyCompanion.insert(
              id: token.id,
              label: token.label,
              category: token.category,
            ),
          ),
        );

        batch.insertAll(_db.kvMeta, [
          KvMetaCompanion.insert(key: 'seedVersion', value: 'v1'),
          KvMetaCompanion.insert(key: 'storage', value: 'drift-sqlite'),
          KvMetaCompanion.insert(
            key: 'managedHostingProvider',
            value: world.managedHostingProvider,
          ),
        ]);
      });
    });
  }

  Future<CreatorRecord?> creatorById(String id) async {
    final row = await (_db.select(
      _db.creators,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapCreator(row);
  }

  Future<List<ContentRecord>> publicCatalogForCreator(String creatorId) async {
    final rows =
        await (_db.select(_db.contentItems)
              ..where((tbl) => tbl.creatorId.equals(creatorId))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
            .get();

    return rows
        .map(
          (row) => ContentRecord(
            id: row.id,
            creatorId: row.creatorId,
            contentType: row.contentType,
            title: row.title,
            summary: row.summary,
            thumbnailRef: row.thumbnailRef,
            createdAt: row.createdAt,
            perfVelocity: row.perfVelocity,
          ),
        )
        .toList(growable: false);
  }

  Future<String?> metaValue(String key) async {
    final row = await (_db.select(
      _db.kvMeta,
    )..where((tbl) => tbl.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<FanPassportRecord> createPassport({
    required String displayName,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 'fan_passport');
    if (existing != null) {
      final passport = await fanPassportById(existing);
      if (passport != null) {
        return passport;
      }
    }

    final id = 'passport_${_slug(idempotencyKey)}';
    final personaId = 'persona_${_slug(idempotencyKey)}';
    final now = _now();

    await _db.transaction(() async {
      await _db
          .into(_db.fanPassports)
          .insertOnConflictUpdate(
            FanPassportsCompanion.insert(
              id: id,
              displayName: displayName,
              activePersonaId: personaId,
              createdAt: now,
            ),
          );
      await _db
          .into(_db.personas)
          .insertOnConflictUpdate(
            PersonasCompanion.insert(
              id: personaId,
              passportId: id,
              label: 'Everyday fan',
              isActive: true,
            ),
          );
      await _ensureInterestProfile(id);
      await _ensureAdPreferences(id);
      await _saveIdempotency(idempotencyKey, 'fan_passport', id);
    });

    return (await fanPassportById(id))!;
  }

  Future<FanPassportRecord?> fanPassportById(String id) async {
    final row = await (_db.select(
      _db.fanPassports,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapPassport(row);
  }

  Future<PersonaRecord> setPersona({
    required String passportId,
    required String label,
    required String idempotencyKey,
  }) async {
    final passport = await fanPassportById(passportId);
    if (passport == null) {
      throw StateError('No fan passport exists for $passportId');
    }

    final existing = await _idempotentTarget(idempotencyKey, 'persona');
    if (existing != null) {
      final row = await (_db.select(
        _db.personas,
      )..where((tbl) => tbl.id.equals(existing))).getSingleOrNull();
      if (row != null) {
        return _mapPersona(row);
      }
    }

    final id = 'persona_${_slug(idempotencyKey)}';
    await _db.transaction(() async {
      await (_db.update(_db.personas)
            ..where((tbl) => tbl.passportId.equals(passportId)))
          .write(const PersonasCompanion(isActive: Value(false)));
      await _db
          .into(_db.personas)
          .insertOnConflictUpdate(
            PersonasCompanion.insert(
              id: id,
              passportId: passportId,
              label: label,
              isActive: true,
            ),
          );
      await (_db.update(_db.fanPassports)
            ..where((tbl) => tbl.id.equals(passportId)))
          .write(FanPassportsCompanion(activePersonaId: Value(id)));
      await _saveIdempotency(idempotencyKey, 'persona', id);
    });

    final row = await (_db.select(
      _db.personas,
    )..where((tbl) => tbl.id.equals(id))).getSingle();
    return _mapPersona(row);
  }

  Future<ConsentGrantRecord> createConsentGrant({
    required String passportId,
    required String grantType,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 'consent_grant');
    if (existing != null) {
      final row = await (_db.select(
        _db.consentGrants,
      )..where((tbl) => tbl.id.equals(existing))).getSingleOrNull();
      if (row != null) {
        return _mapConsent(row);
      }
    }

    final id = 'consent_${_slug(idempotencyKey)}';
    await _db
        .into(_db.consentGrants)
        .insertOnConflictUpdate(
          ConsentGrantsCompanion.insert(
            id: id,
            passportId: passportId,
            grantType: grantType,
            createdAt: _now(),
          ),
        );
    await _saveIdempotency(idempotencyKey, 'consent_grant', id);

    final row = await (_db.select(
      _db.consentGrants,
    )..where((tbl) => tbl.id.equals(id))).getSingle();
    return _mapConsent(row);
  }

  Future<List<InterestTokenRecord>> interestTaxonomy() async {
    final rows =
        await (_db.select(_db.interestTaxonomy)..orderBy([
              (tbl) => OrderingTerm.asc(tbl.category),
              (tbl) => OrderingTerm.asc(tbl.label),
            ]))
            .get();
    return rows.map(_mapInterestToken).toList(growable: false);
  }

  Future<InterestProfileRecord> interestProfile(String passportId) async {
    await _ensureInterestProfile(passportId);
    final row = await (_db.select(
      _db.fanInterestProfiles,
    )..where((tbl) => tbl.passportId.equals(passportId))).getSingle();
    return _mapInterestProfile(row);
  }

  Future<InterestProfileRecord> putInterests({
    required String passportId,
    required List<String> interestIds,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'interest_profile',
    );
    if (existing != null) {
      return interestProfile(existing);
    }

    await _ensureInterestProfile(passportId);
    await (_db.update(
      _db.fanInterestProfiles,
    )..where((tbl) => tbl.passportId.equals(passportId))).write(
      FanInterestProfilesCompanion(
        interestIdsJson: Value(jsonEncode(interestIds)),
        updatedAt: Value(_now()),
      ),
    );
    await _saveIdempotency(idempotencyKey, 'interest_profile', passportId);
    return interestProfile(passportId);
  }

  Future<InterestProfileRecord> putDislikes({
    required String passportId,
    required List<String> dislikedInterestIds,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'interest_profile',
    );
    if (existing != null) {
      return interestProfile(existing);
    }

    await _ensureInterestProfile(passportId);
    await (_db.update(
      _db.fanInterestProfiles,
    )..where((tbl) => tbl.passportId.equals(passportId))).write(
      FanInterestProfilesCompanion(
        dislikedInterestIdsJson: Value(jsonEncode(dislikedInterestIds)),
        updatedAt: Value(_now()),
      ),
    );
    await _saveIdempotency(idempotencyKey, 'interest_profile', passportId);
    return interestProfile(passportId);
  }

  Future<AdPreferencesRecord> adPreferences(String passportId) async {
    await _ensureAdPreferences(passportId);
    final row = await (_db.select(
      _db.adPreferences,
    )..where((tbl) => tbl.passportId.equals(passportId))).getSingle();
    return AdPreferencesRecord(
      passportId: row.passportId,
      personalizedAds: row.personalizedAds,
      updatedAt: row.updatedAt,
    );
  }

  Future<FollowRecord> createFollow({
    required String passportId,
    required String creatorId,
    required String visibility,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 'follow');
    if (existing != null) {
      final follow = await followById(existing);
      if (follow != null) {
        return follow;
      }
    }

    final creator = await creatorById(creatorId);
    if (creator == null) {
      throw StateError('No creator exists for $creatorId');
    }

    final id = 'follow_${_slug(passportId)}_${_slug(creatorId)}';
    final now = _now();
    await _db
        .into(_db.follows)
        .insertOnConflictUpdate(
          FollowsCompanion.insert(
            id: id,
            passportId: passportId,
            creatorId: creatorId,
            visibility: visibility,
            blocked: false,
            createdAt: now,
            updatedAt: now,
          ),
        );
    await _saveIdempotency(idempotencyKey, 'follow', id);
    return (await followById(id))!;
  }

  Future<FollowRecord> setFollowVisibility({
    required String followId,
    required String visibility,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'follow_visibility',
    );
    if (existing != null) {
      final follow = await followById(existing);
      if (follow != null) {
        return follow;
      }
    }

    await (_db.update(
      _db.follows,
    )..where((tbl) => tbl.id.equals(followId))).write(
      FollowsCompanion(visibility: Value(visibility), updatedAt: Value(_now())),
    );
    await _saveIdempotency(idempotencyKey, 'follow_visibility', followId);
    return (await followById(followId))!;
  }

  Future<FollowRecord?> followById(String id) async {
    final follow = await (_db.select(
      _db.follows,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (follow == null) {
      return null;
    }
    final creator = await creatorById(follow.creatorId);
    return _mapFollow(follow, creatorDisplayName: creator?.displayName ?? '');
  }

  Future<List<FollowRecord>> followsForPassport(String passportId) async {
    final rows =
        await (_db.select(_db.follows)
              ..where((tbl) => tbl.passportId.equals(passportId))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
            .get();
    final records = <FollowRecord>[];
    for (final row in rows) {
      final creator = await creatorById(row.creatorId);
      records.add(
        _mapFollow(row, creatorDisplayName: creator?.displayName ?? ''),
      );
    }
    return records;
  }

  Future<CreatorChannelRecord> createChannel({
    required String ownerPassportId,
    required String displayName,
    required String vertical,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 'creator_channel');
    if (existing != null) {
      final channel = await creatorChannelById(existing);
      if (channel != null) {
        return channel;
      }
    }

    final id = 'channel_${_slug(idempotencyKey)}';
    await _db
        .into(_db.creatorChannels)
        .insertOnConflictUpdate(
          CreatorChannelsCompanion.insert(
            id: id,
            ownerPassportId: ownerPassportId,
            displayName: displayName,
            handle: '',
            vertical: vertical,
            createdAt: _now(),
          ),
        );
    await _db
        .into(_db.creators)
        .insertOnConflictUpdate(
          CreatorsCompanion.insert(
            id: id,
            handle: '',
            displayName: displayName,
            vertical: vertical,
            avatarRef: 'seed://avatars/$id',
          ),
        );
    await _saveIdempotency(idempotencyKey, 'creator_channel', id);
    return (await creatorChannelById(id))!;
  }

  Future<CreatorChannelRecord> bindHandle({
    required String channelId,
    required String handle,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 'channel_handle');
    if (existing != null) {
      final channel = await creatorChannelById(existing);
      if (channel != null) {
        return channel;
      }
    }

    await (_db.update(
      _db.creatorChannels,
    )..where((tbl) => tbl.id.equals(channelId))).write(
      CreatorChannelsCompanion(handle: Value(_normalizeHandle(handle))),
    );
    await (_db.update(_db.creators)..where((tbl) => tbl.id.equals(channelId)))
        .write(CreatorsCompanion(handle: Value(_normalizeHandle(handle))));
    await _saveIdempotency(idempotencyKey, 'channel_handle', channelId);
    return (await creatorChannelById(channelId))!;
  }

  Future<CreatorChannelRecord?> creatorChannelById(String id) async {
    final row = await (_db.select(
      _db.creatorChannels,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapCreatorChannel(row);
  }

  Future<CreatorChannelManifestRecord> createChannelProfile({
    required String channelId,
    required String displayName,
    required String handle,
    required String description,
    required String category,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'channel_manifest',
    );
    if (existing != null) {
      final manifest = await channelManifest(existing);
      if (manifest != null) {
        return manifest;
      }
    }

    await _db
        .into(_db.channelManifests)
        .insertOnConflictUpdate(
          ChannelManifestsCompanion.insert(
            channelId: channelId,
            displayName: displayName,
            handle: _normalizeHandle(handle),
            description: description,
            category: category,
            createdAt: _now(),
          ),
        );
    await _ensureCreatorForChannel(
      channelId: channelId,
      displayName: displayName,
      handle: handle,
      vertical: category,
    );
    await _saveIdempotency(idempotencyKey, 'channel_manifest', channelId);
    return (await channelManifest(channelId))!;
  }

  Future<CreatorChannelManifestRecord?> channelManifest(
    String channelId,
  ) async {
    final row = await (_db.select(
      _db.channelManifests,
    )..where((tbl) => tbl.channelId.equals(channelId))).getSingleOrNull();
    return row == null ? null : _mapChannelManifest(row);
  }

  Future<HostingContractRecord> attachHostingContract({
    required String channelId,
    required String provider,
    required String termsVersion,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'hosting_contract',
    );
    if (existing != null) {
      final contract = await hostingContract(existing);
      if (contract != null) {
        return contract;
      }
    }

    final id = 'hosting_${_slug(channelId)}';
    await _db
        .into(_db.hostingContracts)
        .insertOnConflictUpdate(
          HostingContractsCompanion.insert(
            id: id,
            channelId: channelId,
            provider: provider,
            status: 'accepted',
            termsVersion: termsVersion,
            acceptedAt: _now(),
          ),
        );
    await _saveIdempotency(idempotencyKey, 'hosting_contract', id);
    return (await hostingContract(id))!;
  }

  Future<HostingContractRecord?> hostingContract(String id) async {
    final row = await (_db.select(
      _db.hostingContracts,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapHostingContract(row);
  }

  Future<ContentManifestRecord> publishContent({
    required String channelId,
    required String contentType,
    required String title,
    required String summary,
    required String thumbnailRef,
    required String accessMode,
    required String monetizationMode,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'content_manifest',
    );
    if (existing != null) {
      final manifest = await contentManifestById(existing);
      if (manifest != null) {
        return manifest;
      }
    }

    final channel = await creatorChannelById(channelId);
    await _ensureCreatorForChannel(
      channelId: channelId,
      displayName: channel?.displayName ?? 'Demo Creator',
      handle: channel?.handle ?? channelId,
      vertical: channel?.vertical ?? 'creator',
    );

    final id = 'content_${_slug(idempotencyKey)}';
    final existingManifest = await contentManifestById(id);
    final schemaVersion = (existingManifest?.schemaVersion ?? 0) + 1;
    final now = _now();
    await _db.transaction(() async {
      await _db
          .into(_db.contentItems)
          .insertOnConflictUpdate(
            ContentItemsCompanion.insert(
              id: id,
              creatorId: channelId,
              contentType: contentType,
              title: title,
              summary: summary,
              thumbnailRef: thumbnailRef,
              createdAt: now,
              perfVelocity: 0.54,
            ),
          );
      await _db
          .into(_db.contentManifests)
          .insertOnConflictUpdate(
            ContentManifestsCompanion.insert(
              id: id,
              channelId: channelId,
              contentType: contentType,
              title: title,
              summary: summary,
              accessMode: accessMode,
              monetizationMode: monetizationMode,
              thumbnailRef: thumbnailRef,
              schemaVersion: schemaVersion,
              createdAt: existingManifest?.createdAt ?? now,
              updatedAt: now,
            ),
          );
      await _db
          .into(_db.contentPerf)
          .insertOnConflictUpdate(
            ContentPerfCompanion.insert(
              contentId: id,
              velocity: 0.54,
              completionRate: 0.61,
              saves: 24,
              shares: 9,
              updatedAt: now,
            ),
          );
    });
    await _saveIdempotency(idempotencyKey, 'content_manifest', id);
    return (await contentManifestById(id))!;
  }

  Future<ContentManifestRecord?> contentManifestById(String id) async {
    final row = await (_db.select(
      _db.contentManifests,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapContentManifest(row);
  }

  Future<List<ContentManifestRecord>> contentManifests(String channelId) async {
    final rows =
        await (_db.select(_db.contentManifests)
              ..where((tbl) => tbl.channelId.equals(channelId))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
            .get();
    return rows.map(_mapContentManifest).toList(growable: false);
  }

  Future<MonetizationManifestRecord> updateMonetizationManifest({
    required String channelId,
    required bool membershipsEnabled,
    required List<String> memberOnlyContentIds,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'monetization_manifest',
    );
    if (existing != null) {
      final manifest = await monetizationManifest(existing);
      if (manifest != null) {
        return manifest;
      }
    }

    await _db
        .into(_db.monetizationManifests)
        .insertOnConflictUpdate(
          MonetizationManifestsCompanion.insert(
            channelId: channelId,
            membershipsEnabled: membershipsEnabled,
            memberOnlyContentIdsJson: jsonEncode(memberOnlyContentIds),
            updatedAt: _now(),
          ),
        );
    await _saveIdempotency(idempotencyKey, 'monetization_manifest', channelId);
    return (await monetizationManifest(channelId))!;
  }

  Future<MonetizationManifestRecord?> monetizationManifest(
    String channelId,
  ) async {
    final row = await (_db.select(
      _db.monetizationManifests,
    )..where((tbl) => tbl.channelId.equals(channelId))).getSingleOrNull();
    return row == null ? null : _mapMonetizationManifest(row);
  }

  Future<List<MembershipTierRecord>> defineMembershipTiers({
    required String channelId,
    required List<MembershipTierRecord> tiers,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'membership_tiers',
    );
    if (existing != null) {
      return membershipTiers(existing);
    }

    await _db.transaction(() async {
      await (_db.delete(
        _db.membershipTiers,
      )..where((tbl) => tbl.channelId.equals(channelId))).go();
      await _db.batch((batch) {
        batch.insertAll(
          _db.membershipTiers,
          tiers.map(
            (tier) => MembershipTiersCompanion.insert(
              id: tier.id,
              channelId: channelId,
              name: tier.name,
              monthlyPriceCents: tier.monthlyPriceCents,
              benefitsJson: jsonEncode(tier.benefits),
              entitlementCode: tier.entitlementCode,
              createdAt: tier.createdAt,
            ),
          ),
        );
      });
    });
    await _saveIdempotency(idempotencyKey, 'membership_tiers', channelId);
    return membershipTiers(channelId);
  }

  Future<List<MembershipTierRecord>> membershipTiers(String channelId) async {
    final rows =
        await (_db.select(_db.membershipTiers)
              ..where((tbl) => tbl.channelId.equals(channelId))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.monthlyPriceCents)]))
            .get();
    return rows.map(_mapMembershipTier).toList(growable: false);
  }

  Future<CreatorAdPolicyRecord> setCreatorAdPolicy({
    required String channelId,
    required List<String> allowedCategories,
    required List<String> blockedCategories,
    required List<String> formats,
    required List<String> surfaces,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'creator_ad_policy',
    );
    if (existing != null) {
      final policy = await creatorAdPolicy(existing);
      if (policy != null) {
        return policy;
      }
    }

    await _db
        .into(_db.creatorAdPolicies)
        .insertOnConflictUpdate(
          CreatorAdPoliciesCompanion.insert(
            channelId: channelId,
            allowedCategoriesJson: jsonEncode(allowedCategories),
            blockedCategoriesJson: jsonEncode(blockedCategories),
            formatsJson: jsonEncode(formats),
            surfacesJson: jsonEncode(surfaces),
            updatedAt: _now(),
          ),
        );
    await _saveIdempotency(idempotencyKey, 'creator_ad_policy', channelId);
    return (await creatorAdPolicy(channelId))!;
  }

  Future<CreatorAdPolicyRecord?> creatorAdPolicy(String channelId) async {
    final row = await (_db.select(
      _db.creatorAdPolicies,
    )..where((tbl) => tbl.channelId.equals(channelId))).getSingleOrNull();
    return row == null ? null : _mapCreatorAdPolicy(row);
  }

  Future<AiContentPolicyRecord> setAiContentPolicy({
    required String channelId,
    required bool archiveQaEnabled,
    required bool summariesEnabled,
    required bool citationRequired,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'ai_content_policy',
    );
    if (existing != null) {
      final policy = await aiContentPolicy(existing);
      if (policy != null) {
        return policy;
      }
    }

    await _db
        .into(_db.aiContentPolicies)
        .insertOnConflictUpdate(
          AiContentPoliciesCompanion.insert(
            channelId: channelId,
            archiveQaEnabled: archiveQaEnabled,
            summariesEnabled: summariesEnabled,
            citationRequired: citationRequired,
            updatedAt: _now(),
          ),
        );
    await _saveIdempotency(idempotencyKey, 'ai_content_policy', channelId);
    return (await aiContentPolicy(channelId))!;
  }

  Future<AiContentPolicyRecord?> aiContentPolicy(String channelId) async {
    final row = await (_db.select(
      _db.aiContentPolicies,
    )..where((tbl) => tbl.channelId.equals(channelId))).getSingleOrNull();
    return row == null ? null : _mapAiContentPolicy(row);
  }

  Future<ImportJobRecord> startImportJob({
    required String channelId,
    required String sourcePlatform,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(idempotencyKey, 'import_job');
    if (existing != null) {
      final job = await importJob(existing);
      if (job != null) {
        return job;
      }
    }

    final id = 'import_${_slug(idempotencyKey)}';
    final now = _now();
    await _db
        .into(_db.importJobs)
        .insertOnConflictUpdate(
          ImportJobsCompanion.insert(
            id: id,
            channelId: channelId,
            sourcePlatform: sourcePlatform,
            state: 'processing',
            pollCount: 0,
            itemsJson: jsonEncode(_sampleImportItems),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await _saveIdempotency(idempotencyKey, 'import_job', id);
    return (await importJob(id))!;
  }

  Future<ImportJobRecord?> importJob(String id) async {
    final row = await (_db.select(
      _db.importJobs,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (row == null) {
      return null;
    }
    final refs =
        await (_db.select(_db.externalContentRefs)
              ..where((tbl) => tbl.jobId.equals(id))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
            .get();
    return _mapImportJob(
      row,
      refs.map(_mapExternalRef).toList(growable: false),
    );
  }

  Future<ImportJobRecord> advanceImportJob(String id) async {
    final row = await (_db.select(
      _db.importJobs,
    )..where((tbl) => tbl.id.equals(id))).getSingle();
    if (row.state == 'complete') {
      return (await importJob(id))!;
    }

    final now = _now();
    await _db.transaction(() async {
      await (_db.update(
        _db.importJobs,
      )..where((tbl) => tbl.id.equals(id))).write(
        ImportJobsCompanion(
          state: const Value('complete'),
          pollCount: Value(row.pollCount + 1),
          updatedAt: Value(now),
        ),
      );
      final items = _decodeImportItems(row.itemsJson);
      for (final item in items) {
        final contentId = 'external_${_slug(id)}_${_slug(item.externalId)}';
        await _ensureCreatorForChannel(
          channelId: row.channelId,
          displayName: 'Demo Creator',
          handle: row.channelId,
          vertical: 'creator',
        );
        await _db
            .into(_db.contentItems)
            .insertOnConflictUpdate(
              ContentItemsCompanion.insert(
                id: contentId,
                creatorId: row.channelId,
                contentType: item.contentType,
                title: item.title,
                summary: item.summary,
                thumbnailRef: item.thumbnailRef,
                createdAt: now,
                perfVelocity: 0.49,
              ),
            );
        await _db
            .into(_db.contentManifests)
            .insertOnConflictUpdate(
              ContentManifestsCompanion.insert(
                id: contentId,
                channelId: row.channelId,
                contentType: item.contentType,
                title: item.title,
                summary: item.summary,
                accessMode: 'public',
                monetizationMode: 'free',
                thumbnailRef: item.thumbnailRef,
                schemaVersion: 1,
                createdAt: now,
                updatedAt: now,
              ),
            );
        await _db
            .into(_db.externalContentRefs)
            .insertOnConflictUpdate(
              ExternalContentRefsCompanion.insert(
                id: 'xref_${_slug(id)}_${_slug(item.externalId)}',
                jobId: id,
                channelId: row.channelId,
                sourcePlatform: row.sourcePlatform,
                externalId: item.externalId,
                contentId: contentId,
                title: item.title,
                summary: item.summary,
                createdAt: now,
              ),
            );
      }
    });
    return (await importJob(id))!;
  }

  Future<List<EntitlementDefinitionRecord>> registerEntitlements({
    required String channelId,
    required List<MembershipTierRecord> tiers,
    required String idempotencyKey,
  }) async {
    final existing = await _idempotentTarget(
      idempotencyKey,
      'entitlement_definitions',
    );
    if (existing != null) {
      return entitlementDefinitions(existing);
    }

    await _db.transaction(() async {
      await (_db.delete(
        _db.entitlementDefinitions,
      )..where((tbl) => tbl.channelId.equals(channelId))).go();
      await _db.batch((batch) {
        batch.insertAll(
          _db.entitlementDefinitions,
          tiers.map(
            (tier) => EntitlementDefinitionsCompanion.insert(
              id: 'ent_${_slug(tier.id)}',
              channelId: channelId,
              tierId: tier.id,
              code: tier.entitlementCode,
              createdAt: _now(),
            ),
          ),
        );
      });
    });
    await _saveIdempotency(
      idempotencyKey,
      'entitlement_definitions',
      channelId,
    );
    return entitlementDefinitions(channelId);
  }

  Future<List<EntitlementDefinitionRecord>> entitlementDefinitions(
    String channelId,
  ) async {
    final rows =
        await (_db.select(_db.entitlementDefinitions)
              ..where((tbl) => tbl.channelId.equals(channelId))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.code)]))
            .get();
    return rows.map(_mapEntitlementDefinition).toList(growable: false);
  }

  Future<ContentPerformanceRecord> contentPerformance(String contentId) async {
    final row = await (_db.select(
      _db.contentPerf,
    )..where((tbl) => tbl.contentId.equals(contentId))).getSingleOrNull();
    if (row != null) {
      return _mapContentPerformance(row);
    }
    return ContentPerformanceRecord(
      contentId: contentId,
      velocity: 0.42,
      completionRate: 0.58,
      saves: 0,
      shares: 0,
      updatedAt: _now(),
    );
  }

  Future<void> _ensureCreatorForChannel({
    required String channelId,
    required String displayName,
    required String handle,
    required String vertical,
  }) {
    return _db
        .into(_db.creators)
        .insertOnConflictUpdate(
          CreatorsCompanion.insert(
            id: channelId,
            handle: _normalizeHandle(handle),
            displayName: displayName,
            vertical: vertical,
            avatarRef: 'seed://avatars/$channelId',
          ),
        );
  }

  Future<void> _ensureInterestProfile(String passportId) async {
    await _db
        .into(_db.fanInterestProfiles)
        .insert(
          FanInterestProfilesCompanion.insert(
            passportId: passportId,
            interestIdsJson: '[]',
            dislikedInterestIdsJson: '[]',
            dislikedCreatorIdsJson: '[]',
            mutedProviderIdsJson: '[]',
            updatedAt: _now(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> _ensureAdPreferences(String passportId) async {
    await _db
        .into(_db.adPreferences)
        .insert(
          AdPreferencesCompanion.insert(
            passportId: passportId,
            personalizedAds: false,
            updatedAt: _now(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<String?> _idempotentTarget(String key, String targetType) async {
    final row = await (_db.select(
      _db.idempotencyRecords,
    )..where((tbl) => tbl.key.equals(key))).getSingleOrNull();
    if (row == null || row.targetType != targetType) {
      return null;
    }
    return row.targetId;
  }

  Future<void> _saveIdempotency(
    String key,
    String targetType,
    String targetId,
  ) {
    return _db
        .into(_db.idempotencyRecords)
        .insertOnConflictUpdate(
          IdempotencyRecordsCompanion.insert(
            key: key,
            targetType: targetType,
            targetId: targetId,
          ),
        );
  }

  Future<InterestProfileRecord> _mapInterestProfile(
    FanInterestProfile row,
  ) async {
    final ids = _decodeStringList(row.interestIdsJson);
    final tokens = await interestTaxonomy();
    final selected = tokens
        .where((token) => ids.contains(token.id))
        .toList(growable: false);
    return InterestProfileRecord(
      passportId: row.passportId,
      interests: selected,
      dislikedInterestIds: _decodeStringList(row.dislikedInterestIdsJson),
      dislikedCreatorIds: _decodeStringList(row.dislikedCreatorIdsJson),
      mutedProviderIds: _decodeStringList(row.mutedProviderIdsJson),
      updatedAt: row.updatedAt,
    );
  }
}

CreatorRecord _mapCreator(Creator row) {
  return CreatorRecord(
    id: row.id,
    handle: row.handle,
    displayName: row.displayName,
    vertical: row.vertical,
    avatarRef: row.avatarRef,
  );
}

FanPassportRecord _mapPassport(FanPassport row) {
  return FanPassportRecord(
    id: row.id,
    displayName: row.displayName,
    activePersonaId: row.activePersonaId,
    createdAt: row.createdAt,
  );
}

PersonaRecord _mapPersona(Persona row) {
  return PersonaRecord(
    id: row.id,
    passportId: row.passportId,
    label: row.label,
    isActive: row.isActive,
  );
}

ConsentGrantRecord _mapConsent(ConsentGrant row) {
  return ConsentGrantRecord(
    id: row.id,
    passportId: row.passportId,
    grantType: row.grantType,
    createdAt: row.createdAt,
  );
}

InterestTokenRecord _mapInterestToken(InterestTaxonomyData row) {
  return InterestTokenRecord(
    id: row.id,
    label: row.label,
    category: row.category,
  );
}

FollowRecord _mapFollow(Follow row, {required String creatorDisplayName}) {
  return FollowRecord(
    id: row.id,
    passportId: row.passportId,
    creatorId: row.creatorId,
    creatorDisplayName: creatorDisplayName,
    visibility: row.visibility,
    blocked: row.blocked,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

CreatorChannelRecord _mapCreatorChannel(CreatorChannel row) {
  return CreatorChannelRecord(
    id: row.id,
    ownerPassportId: row.ownerPassportId,
    displayName: row.displayName,
    handle: row.handle,
    vertical: row.vertical,
    createdAt: row.createdAt,
  );
}

CreatorChannelManifestRecord _mapChannelManifest(ChannelManifest row) {
  return CreatorChannelManifestRecord(
    channelId: row.channelId,
    displayName: row.displayName,
    handle: row.handle,
    description: row.description,
    category: row.category,
    createdAt: row.createdAt,
  );
}

HostingContractRecord _mapHostingContract(HostingContract row) {
  return HostingContractRecord(
    id: row.id,
    channelId: row.channelId,
    provider: row.provider,
    status: row.status,
    termsVersion: row.termsVersion,
    acceptedAt: row.acceptedAt,
  );
}

ContentManifestRecord _mapContentManifest(ContentManifest row) {
  return ContentManifestRecord(
    id: row.id,
    channelId: row.channelId,
    contentType: row.contentType,
    title: row.title,
    summary: row.summary,
    accessMode: row.accessMode,
    monetizationMode: row.monetizationMode,
    thumbnailRef: row.thumbnailRef,
    schemaVersion: row.schemaVersion,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

MonetizationManifestRecord _mapMonetizationManifest(MonetizationManifest row) {
  return MonetizationManifestRecord(
    channelId: row.channelId,
    membershipsEnabled: row.membershipsEnabled,
    memberOnlyContentIds: _decodeStringList(row.memberOnlyContentIdsJson),
    updatedAt: row.updatedAt,
  );
}

CreatorAdPolicyRecord _mapCreatorAdPolicy(CreatorAdPolicy row) {
  return CreatorAdPolicyRecord(
    channelId: row.channelId,
    allowedCategories: _decodeStringList(row.allowedCategoriesJson),
    blockedCategories: _decodeStringList(row.blockedCategoriesJson),
    formats: _decodeStringList(row.formatsJson),
    surfaces: _decodeStringList(row.surfacesJson),
    updatedAt: row.updatedAt,
  );
}

MembershipTierRecord _mapMembershipTier(MembershipTier row) {
  return MembershipTierRecord(
    id: row.id,
    channelId: row.channelId,
    name: row.name,
    monthlyPriceCents: row.monthlyPriceCents,
    benefits: _decodeStringList(row.benefitsJson),
    entitlementCode: row.entitlementCode,
    createdAt: row.createdAt,
  );
}

AiContentPolicyRecord _mapAiContentPolicy(AiContentPolicy row) {
  return AiContentPolicyRecord(
    channelId: row.channelId,
    archiveQaEnabled: row.archiveQaEnabled,
    summariesEnabled: row.summariesEnabled,
    citationRequired: row.citationRequired,
    updatedAt: row.updatedAt,
  );
}

ImportJobRecord _mapImportJob(
  ImportJob row,
  List<ExternalContentRefRecord> references,
) {
  return ImportJobRecord(
    id: row.id,
    channelId: row.channelId,
    sourcePlatform: row.sourcePlatform,
    state: row.state,
    references: references,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

ExternalContentRefRecord _mapExternalRef(ExternalContentRef row) {
  return ExternalContentRefRecord(
    id: row.id,
    jobId: row.jobId,
    channelId: row.channelId,
    sourcePlatform: row.sourcePlatform,
    externalId: row.externalId,
    contentId: row.contentId,
    title: row.title,
    summary: row.summary,
    createdAt: row.createdAt,
  );
}

ContentPerformanceRecord _mapContentPerformance(ContentPerfData row) {
  return ContentPerformanceRecord(
    contentId: row.contentId,
    velocity: row.velocity,
    completionRate: row.completionRate,
    saves: row.saves,
    shares: row.shares,
    updatedAt: row.updatedAt,
  );
}

EntitlementDefinitionRecord _mapEntitlementDefinition(
  EntitlementDefinition row,
) {
  return EntitlementDefinitionRecord(
    id: row.id,
    channelId: row.channelId,
    tierId: row.tierId,
    code: row.code,
    createdAt: row.createdAt,
  );
}

List<String> _decodeStringList(String value) {
  final decoded = jsonDecode(value);
  if (decoded is! List) {
    return const [];
  }
  return decoded.whereType<String>().toList(growable: false);
}

List<_ImportItem> _decodeImportItems(String value) {
  final decoded = jsonDecode(value);
  if (decoded is! List) {
    return const [];
  }
  return decoded
      .whereType<Map<String, Object?>>()
      .map(
        (item) => _ImportItem(
          externalId: item['externalId']! as String,
          contentType: item['contentType']! as String,
          title: item['title']! as String,
          summary: item['summary']! as String,
          thumbnailRef: item['thumbnailRef']! as String,
        ),
      )
      .toList(growable: false);
}

const _sampleImportItems = [
  {
    'externalId': 'yt-thermal-001',
    'contentType': 'video',
    'title': 'Imported attic thermal scan',
    'summary':
        'A previously published scan showing where insulation gaps change winter heating costs.',
    'thumbnailRef': 'seed://imports/thermal-001',
  },
  {
    'externalId': 'yt-battery-002',
    'contentType': 'post',
    'title': 'Imported battery sizing notes',
    'summary':
        'A concise imported post comparing backup loads, peak draw, and usable storage.',
    'thumbnailRef': 'seed://imports/battery-002',
  },
];

class _ImportItem {
  const _ImportItem({
    required this.externalId,
    required this.contentType,
    required this.title,
    required this.summary,
    required this.thumbnailRef,
  });

  final String externalId;
  final String contentType;
  final String title;
  final String summary;
  final String thumbnailRef;
}

String _normalizeHandle(String handle) {
  return handle
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

String _slug(String value) {
  final slug = _normalizeHandle(value);
  return slug.isEmpty ? 'demo' : slug;
}

DateTime _now() => DateTime.utc(2026, 5, 31, 12);
