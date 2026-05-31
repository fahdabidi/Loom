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

class KvMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [Creators, ContentItems, KvMeta])
class LoomDatabase extends _$LoomDatabase {
  LoomDatabase(super.executor);

  @override
  int get schemaVersion => 1;
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

class DemoLocalStore {
  DemoLocalStore._(this._db);

  final LoomDatabase _db;

  static Future<DemoLocalStore> open({
    required File databaseFile,
    SeedWorld? seed,
  }) async {
    final store = DemoLocalStore._(
      LoomDatabase(NativeDatabase.createInBackground(databaseFile)),
    );
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

        batch.insertAll(_db.kvMeta, [
          KvMetaCompanion.insert(key: 'seedVersion', value: 'v1'),
          KvMetaCompanion.insert(key: 'storage', value: 'drift-sqlite'),
        ]);
      });
    });
  }

  Future<CreatorRecord?> creatorById(String id) async {
    final row = await (_db.select(
      _db.creators,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (row == null) {
      return null;
    }

    return CreatorRecord(
      id: row.id,
      handle: row.handle,
      displayName: row.displayName,
      vertical: row.vertical,
      avatarRef: row.avatarRef,
    );
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
}
