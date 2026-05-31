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
  int get schemaVersion => 2;

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

List<String> _decodeStringList(String value) {
  final decoded = jsonDecode(value);
  if (decoded is! List) {
    return const [];
  }
  return decoded.whereType<String>().toList(growable: false);
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
