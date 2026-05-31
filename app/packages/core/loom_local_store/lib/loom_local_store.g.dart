// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loom_local_store.dart';

// ignore_for_file: type=lint
class $CreatorsTable extends Creators with TableInfo<$CreatorsTable, Creator> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CreatorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _handleMeta = const VerificationMeta('handle');
  @override
  late final GeneratedColumn<String> handle = GeneratedColumn<String>(
    'handle',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _verticalMeta = const VerificationMeta(
    'vertical',
  );
  @override
  late final GeneratedColumn<String> vertical = GeneratedColumn<String>(
    'vertical',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avatarRefMeta = const VerificationMeta(
    'avatarRef',
  );
  @override
  late final GeneratedColumn<String> avatarRef = GeneratedColumn<String>(
    'avatar_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    handle,
    displayName,
    vertical,
    avatarRef,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'creators';
  @override
  VerificationContext validateIntegrity(
    Insertable<Creator> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('handle')) {
      context.handle(
        _handleMeta,
        handle.isAcceptableOrUnknown(data['handle']!, _handleMeta),
      );
    } else if (isInserting) {
      context.missing(_handleMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('vertical')) {
      context.handle(
        _verticalMeta,
        vertical.isAcceptableOrUnknown(data['vertical']!, _verticalMeta),
      );
    } else if (isInserting) {
      context.missing(_verticalMeta);
    }
    if (data.containsKey('avatar_ref')) {
      context.handle(
        _avatarRefMeta,
        avatarRef.isAcceptableOrUnknown(data['avatar_ref']!, _avatarRefMeta),
      );
    } else if (isInserting) {
      context.missing(_avatarRefMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Creator map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Creator(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      handle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}handle'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      vertical: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vertical'],
      )!,
      avatarRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_ref'],
      )!,
    );
  }

  @override
  $CreatorsTable createAlias(String alias) {
    return $CreatorsTable(attachedDatabase, alias);
  }
}

class Creator extends DataClass implements Insertable<Creator> {
  final String id;
  final String handle;
  final String displayName;
  final String vertical;
  final String avatarRef;
  const Creator({
    required this.id,
    required this.handle,
    required this.displayName,
    required this.vertical,
    required this.avatarRef,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['handle'] = Variable<String>(handle);
    map['display_name'] = Variable<String>(displayName);
    map['vertical'] = Variable<String>(vertical);
    map['avatar_ref'] = Variable<String>(avatarRef);
    return map;
  }

  CreatorsCompanion toCompanion(bool nullToAbsent) {
    return CreatorsCompanion(
      id: Value(id),
      handle: Value(handle),
      displayName: Value(displayName),
      vertical: Value(vertical),
      avatarRef: Value(avatarRef),
    );
  }

  factory Creator.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Creator(
      id: serializer.fromJson<String>(json['id']),
      handle: serializer.fromJson<String>(json['handle']),
      displayName: serializer.fromJson<String>(json['displayName']),
      vertical: serializer.fromJson<String>(json['vertical']),
      avatarRef: serializer.fromJson<String>(json['avatarRef']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'handle': serializer.toJson<String>(handle),
      'displayName': serializer.toJson<String>(displayName),
      'vertical': serializer.toJson<String>(vertical),
      'avatarRef': serializer.toJson<String>(avatarRef),
    };
  }

  Creator copyWith({
    String? id,
    String? handle,
    String? displayName,
    String? vertical,
    String? avatarRef,
  }) => Creator(
    id: id ?? this.id,
    handle: handle ?? this.handle,
    displayName: displayName ?? this.displayName,
    vertical: vertical ?? this.vertical,
    avatarRef: avatarRef ?? this.avatarRef,
  );
  Creator copyWithCompanion(CreatorsCompanion data) {
    return Creator(
      id: data.id.present ? data.id.value : this.id,
      handle: data.handle.present ? data.handle.value : this.handle,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      vertical: data.vertical.present ? data.vertical.value : this.vertical,
      avatarRef: data.avatarRef.present ? data.avatarRef.value : this.avatarRef,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Creator(')
          ..write('id: $id, ')
          ..write('handle: $handle, ')
          ..write('displayName: $displayName, ')
          ..write('vertical: $vertical, ')
          ..write('avatarRef: $avatarRef')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, handle, displayName, vertical, avatarRef);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Creator &&
          other.id == this.id &&
          other.handle == this.handle &&
          other.displayName == this.displayName &&
          other.vertical == this.vertical &&
          other.avatarRef == this.avatarRef);
}

class CreatorsCompanion extends UpdateCompanion<Creator> {
  final Value<String> id;
  final Value<String> handle;
  final Value<String> displayName;
  final Value<String> vertical;
  final Value<String> avatarRef;
  final Value<int> rowid;
  const CreatorsCompanion({
    this.id = const Value.absent(),
    this.handle = const Value.absent(),
    this.displayName = const Value.absent(),
    this.vertical = const Value.absent(),
    this.avatarRef = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CreatorsCompanion.insert({
    required String id,
    required String handle,
    required String displayName,
    required String vertical,
    required String avatarRef,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       handle = Value(handle),
       displayName = Value(displayName),
       vertical = Value(vertical),
       avatarRef = Value(avatarRef);
  static Insertable<Creator> custom({
    Expression<String>? id,
    Expression<String>? handle,
    Expression<String>? displayName,
    Expression<String>? vertical,
    Expression<String>? avatarRef,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (handle != null) 'handle': handle,
      if (displayName != null) 'display_name': displayName,
      if (vertical != null) 'vertical': vertical,
      if (avatarRef != null) 'avatar_ref': avatarRef,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CreatorsCompanion copyWith({
    Value<String>? id,
    Value<String>? handle,
    Value<String>? displayName,
    Value<String>? vertical,
    Value<String>? avatarRef,
    Value<int>? rowid,
  }) {
    return CreatorsCompanion(
      id: id ?? this.id,
      handle: handle ?? this.handle,
      displayName: displayName ?? this.displayName,
      vertical: vertical ?? this.vertical,
      avatarRef: avatarRef ?? this.avatarRef,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (handle.present) {
      map['handle'] = Variable<String>(handle.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (vertical.present) {
      map['vertical'] = Variable<String>(vertical.value);
    }
    if (avatarRef.present) {
      map['avatar_ref'] = Variable<String>(avatarRef.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CreatorsCompanion(')
          ..write('id: $id, ')
          ..write('handle: $handle, ')
          ..write('displayName: $displayName, ')
          ..write('vertical: $vertical, ')
          ..write('avatarRef: $avatarRef, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContentItemsTable extends ContentItems
    with TableInfo<$ContentItemsTable, ContentItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContentItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _creatorIdMeta = const VerificationMeta(
    'creatorId',
  );
  @override
  late final GeneratedColumn<String> creatorId = GeneratedColumn<String>(
    'creator_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES creators (id)',
    ),
  );
  static const VerificationMeta _contentTypeMeta = const VerificationMeta(
    'contentType',
  );
  @override
  late final GeneratedColumn<String> contentType = GeneratedColumn<String>(
    'content_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbnailRefMeta = const VerificationMeta(
    'thumbnailRef',
  );
  @override
  late final GeneratedColumn<String> thumbnailRef = GeneratedColumn<String>(
    'thumbnail_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _perfVelocityMeta = const VerificationMeta(
    'perfVelocity',
  );
  @override
  late final GeneratedColumn<double> perfVelocity = GeneratedColumn<double>(
    'perf_velocity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    creatorId,
    contentType,
    title,
    summary,
    thumbnailRef,
    createdAt,
    perfVelocity,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'content_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContentItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('creator_id')) {
      context.handle(
        _creatorIdMeta,
        creatorId.isAcceptableOrUnknown(data['creator_id']!, _creatorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_creatorIdMeta);
    }
    if (data.containsKey('content_type')) {
      context.handle(
        _contentTypeMeta,
        contentType.isAcceptableOrUnknown(
          data['content_type']!,
          _contentTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentTypeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    } else if (isInserting) {
      context.missing(_summaryMeta);
    }
    if (data.containsKey('thumbnail_ref')) {
      context.handle(
        _thumbnailRefMeta,
        thumbnailRef.isAcceptableOrUnknown(
          data['thumbnail_ref']!,
          _thumbnailRefMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_thumbnailRefMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('perf_velocity')) {
      context.handle(
        _perfVelocityMeta,
        perfVelocity.isAcceptableOrUnknown(
          data['perf_velocity']!,
          _perfVelocityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_perfVelocityMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ContentItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContentItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      creatorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creator_id'],
      )!,
      contentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      thumbnailRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_ref'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      perfVelocity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}perf_velocity'],
      )!,
    );
  }

  @override
  $ContentItemsTable createAlias(String alias) {
    return $ContentItemsTable(attachedDatabase, alias);
  }
}

class ContentItem extends DataClass implements Insertable<ContentItem> {
  final String id;
  final String creatorId;
  final String contentType;
  final String title;
  final String summary;
  final String thumbnailRef;
  final DateTime createdAt;
  final double perfVelocity;
  const ContentItem({
    required this.id,
    required this.creatorId,
    required this.contentType,
    required this.title,
    required this.summary,
    required this.thumbnailRef,
    required this.createdAt,
    required this.perfVelocity,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['creator_id'] = Variable<String>(creatorId);
    map['content_type'] = Variable<String>(contentType);
    map['title'] = Variable<String>(title);
    map['summary'] = Variable<String>(summary);
    map['thumbnail_ref'] = Variable<String>(thumbnailRef);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['perf_velocity'] = Variable<double>(perfVelocity);
    return map;
  }

  ContentItemsCompanion toCompanion(bool nullToAbsent) {
    return ContentItemsCompanion(
      id: Value(id),
      creatorId: Value(creatorId),
      contentType: Value(contentType),
      title: Value(title),
      summary: Value(summary),
      thumbnailRef: Value(thumbnailRef),
      createdAt: Value(createdAt),
      perfVelocity: Value(perfVelocity),
    );
  }

  factory ContentItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContentItem(
      id: serializer.fromJson<String>(json['id']),
      creatorId: serializer.fromJson<String>(json['creatorId']),
      contentType: serializer.fromJson<String>(json['contentType']),
      title: serializer.fromJson<String>(json['title']),
      summary: serializer.fromJson<String>(json['summary']),
      thumbnailRef: serializer.fromJson<String>(json['thumbnailRef']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      perfVelocity: serializer.fromJson<double>(json['perfVelocity']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'creatorId': serializer.toJson<String>(creatorId),
      'contentType': serializer.toJson<String>(contentType),
      'title': serializer.toJson<String>(title),
      'summary': serializer.toJson<String>(summary),
      'thumbnailRef': serializer.toJson<String>(thumbnailRef),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'perfVelocity': serializer.toJson<double>(perfVelocity),
    };
  }

  ContentItem copyWith({
    String? id,
    String? creatorId,
    String? contentType,
    String? title,
    String? summary,
    String? thumbnailRef,
    DateTime? createdAt,
    double? perfVelocity,
  }) => ContentItem(
    id: id ?? this.id,
    creatorId: creatorId ?? this.creatorId,
    contentType: contentType ?? this.contentType,
    title: title ?? this.title,
    summary: summary ?? this.summary,
    thumbnailRef: thumbnailRef ?? this.thumbnailRef,
    createdAt: createdAt ?? this.createdAt,
    perfVelocity: perfVelocity ?? this.perfVelocity,
  );
  ContentItem copyWithCompanion(ContentItemsCompanion data) {
    return ContentItem(
      id: data.id.present ? data.id.value : this.id,
      creatorId: data.creatorId.present ? data.creatorId.value : this.creatorId,
      contentType: data.contentType.present
          ? data.contentType.value
          : this.contentType,
      title: data.title.present ? data.title.value : this.title,
      summary: data.summary.present ? data.summary.value : this.summary,
      thumbnailRef: data.thumbnailRef.present
          ? data.thumbnailRef.value
          : this.thumbnailRef,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      perfVelocity: data.perfVelocity.present
          ? data.perfVelocity.value
          : this.perfVelocity,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContentItem(')
          ..write('id: $id, ')
          ..write('creatorId: $creatorId, ')
          ..write('contentType: $contentType, ')
          ..write('title: $title, ')
          ..write('summary: $summary, ')
          ..write('thumbnailRef: $thumbnailRef, ')
          ..write('createdAt: $createdAt, ')
          ..write('perfVelocity: $perfVelocity')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    creatorId,
    contentType,
    title,
    summary,
    thumbnailRef,
    createdAt,
    perfVelocity,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContentItem &&
          other.id == this.id &&
          other.creatorId == this.creatorId &&
          other.contentType == this.contentType &&
          other.title == this.title &&
          other.summary == this.summary &&
          other.thumbnailRef == this.thumbnailRef &&
          other.createdAt == this.createdAt &&
          other.perfVelocity == this.perfVelocity);
}

class ContentItemsCompanion extends UpdateCompanion<ContentItem> {
  final Value<String> id;
  final Value<String> creatorId;
  final Value<String> contentType;
  final Value<String> title;
  final Value<String> summary;
  final Value<String> thumbnailRef;
  final Value<DateTime> createdAt;
  final Value<double> perfVelocity;
  final Value<int> rowid;
  const ContentItemsCompanion({
    this.id = const Value.absent(),
    this.creatorId = const Value.absent(),
    this.contentType = const Value.absent(),
    this.title = const Value.absent(),
    this.summary = const Value.absent(),
    this.thumbnailRef = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.perfVelocity = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContentItemsCompanion.insert({
    required String id,
    required String creatorId,
    required String contentType,
    required String title,
    required String summary,
    required String thumbnailRef,
    required DateTime createdAt,
    required double perfVelocity,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       creatorId = Value(creatorId),
       contentType = Value(contentType),
       title = Value(title),
       summary = Value(summary),
       thumbnailRef = Value(thumbnailRef),
       createdAt = Value(createdAt),
       perfVelocity = Value(perfVelocity);
  static Insertable<ContentItem> custom({
    Expression<String>? id,
    Expression<String>? creatorId,
    Expression<String>? contentType,
    Expression<String>? title,
    Expression<String>? summary,
    Expression<String>? thumbnailRef,
    Expression<DateTime>? createdAt,
    Expression<double>? perfVelocity,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (creatorId != null) 'creator_id': creatorId,
      if (contentType != null) 'content_type': contentType,
      if (title != null) 'title': title,
      if (summary != null) 'summary': summary,
      if (thumbnailRef != null) 'thumbnail_ref': thumbnailRef,
      if (createdAt != null) 'created_at': createdAt,
      if (perfVelocity != null) 'perf_velocity': perfVelocity,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContentItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? creatorId,
    Value<String>? contentType,
    Value<String>? title,
    Value<String>? summary,
    Value<String>? thumbnailRef,
    Value<DateTime>? createdAt,
    Value<double>? perfVelocity,
    Value<int>? rowid,
  }) {
    return ContentItemsCompanion(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      contentType: contentType ?? this.contentType,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      thumbnailRef: thumbnailRef ?? this.thumbnailRef,
      createdAt: createdAt ?? this.createdAt,
      perfVelocity: perfVelocity ?? this.perfVelocity,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (creatorId.present) {
      map['creator_id'] = Variable<String>(creatorId.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String>(contentType.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (thumbnailRef.present) {
      map['thumbnail_ref'] = Variable<String>(thumbnailRef.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (perfVelocity.present) {
      map['perf_velocity'] = Variable<double>(perfVelocity.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContentItemsCompanion(')
          ..write('id: $id, ')
          ..write('creatorId: $creatorId, ')
          ..write('contentType: $contentType, ')
          ..write('title: $title, ')
          ..write('summary: $summary, ')
          ..write('thumbnailRef: $thumbnailRef, ')
          ..write('createdAt: $createdAt, ')
          ..write('perfVelocity: $perfVelocity, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KvMetaTable extends KvMeta with TableInfo<$KvMetaTable, KvMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KvMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kv_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<KvMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KvMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KvMetaData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $KvMetaTable createAlias(String alias) {
    return $KvMetaTable(attachedDatabase, alias);
  }
}

class KvMetaData extends DataClass implements Insertable<KvMetaData> {
  final String key;
  final String value;
  const KvMetaData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  KvMetaCompanion toCompanion(bool nullToAbsent) {
    return KvMetaCompanion(key: Value(key), value: Value(value));
  }

  factory KvMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KvMetaData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  KvMetaData copyWith({String? key, String? value}) =>
      KvMetaData(key: key ?? this.key, value: value ?? this.value);
  KvMetaData copyWithCompanion(KvMetaCompanion data) {
    return KvMetaData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KvMetaData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KvMetaData &&
          other.key == this.key &&
          other.value == this.value);
}

class KvMetaCompanion extends UpdateCompanion<KvMetaData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const KvMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KvMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<KvMetaData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KvMetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return KvMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KvMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LoomDatabase extends GeneratedDatabase {
  _$LoomDatabase(QueryExecutor e) : super(e);
  $LoomDatabaseManager get managers => $LoomDatabaseManager(this);
  late final $CreatorsTable creators = $CreatorsTable(this);
  late final $ContentItemsTable contentItems = $ContentItemsTable(this);
  late final $KvMetaTable kvMeta = $KvMetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    creators,
    contentItems,
    kvMeta,
  ];
}

typedef $$CreatorsTableCreateCompanionBuilder =
    CreatorsCompanion Function({
      required String id,
      required String handle,
      required String displayName,
      required String vertical,
      required String avatarRef,
      Value<int> rowid,
    });
typedef $$CreatorsTableUpdateCompanionBuilder =
    CreatorsCompanion Function({
      Value<String> id,
      Value<String> handle,
      Value<String> displayName,
      Value<String> vertical,
      Value<String> avatarRef,
      Value<int> rowid,
    });

final class $$CreatorsTableReferences
    extends BaseReferences<_$LoomDatabase, $CreatorsTable, Creator> {
  $$CreatorsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ContentItemsTable, List<ContentItem>>
  _contentItemsRefsTable(_$LoomDatabase db) => MultiTypedResultKey.fromTable(
    db.contentItems,
    aliasName: $_aliasNameGenerator(db.creators.id, db.contentItems.creatorId),
  );

  $$ContentItemsTableProcessedTableManager get contentItemsRefs {
    final manager = $$ContentItemsTableTableManager(
      $_db,
      $_db.contentItems,
    ).filter((f) => f.creatorId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_contentItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CreatorsTableFilterComposer
    extends Composer<_$LoomDatabase, $CreatorsTable> {
  $$CreatorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get handle => $composableBuilder(
    column: $table.handle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vertical => $composableBuilder(
    column: $table.vertical,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarRef => $composableBuilder(
    column: $table.avatarRef,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> contentItemsRefs(
    Expression<bool> Function($$ContentItemsTableFilterComposer f) f,
  ) {
    final $$ContentItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.contentItems,
      getReferencedColumn: (t) => t.creatorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContentItemsTableFilterComposer(
            $db: $db,
            $table: $db.contentItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CreatorsTableOrderingComposer
    extends Composer<_$LoomDatabase, $CreatorsTable> {
  $$CreatorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get handle => $composableBuilder(
    column: $table.handle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vertical => $composableBuilder(
    column: $table.vertical,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarRef => $composableBuilder(
    column: $table.avatarRef,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CreatorsTableAnnotationComposer
    extends Composer<_$LoomDatabase, $CreatorsTable> {
  $$CreatorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get handle =>
      $composableBuilder(column: $table.handle, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get vertical =>
      $composableBuilder(column: $table.vertical, builder: (column) => column);

  GeneratedColumn<String> get avatarRef =>
      $composableBuilder(column: $table.avatarRef, builder: (column) => column);

  Expression<T> contentItemsRefs<T extends Object>(
    Expression<T> Function($$ContentItemsTableAnnotationComposer a) f,
  ) {
    final $$ContentItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.contentItems,
      getReferencedColumn: (t) => t.creatorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContentItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.contentItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CreatorsTableTableManager
    extends
        RootTableManager<
          _$LoomDatabase,
          $CreatorsTable,
          Creator,
          $$CreatorsTableFilterComposer,
          $$CreatorsTableOrderingComposer,
          $$CreatorsTableAnnotationComposer,
          $$CreatorsTableCreateCompanionBuilder,
          $$CreatorsTableUpdateCompanionBuilder,
          (Creator, $$CreatorsTableReferences),
          Creator,
          PrefetchHooks Function({bool contentItemsRefs})
        > {
  $$CreatorsTableTableManager(_$LoomDatabase db, $CreatorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CreatorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CreatorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CreatorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> handle = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> vertical = const Value.absent(),
                Value<String> avatarRef = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CreatorsCompanion(
                id: id,
                handle: handle,
                displayName: displayName,
                vertical: vertical,
                avatarRef: avatarRef,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String handle,
                required String displayName,
                required String vertical,
                required String avatarRef,
                Value<int> rowid = const Value.absent(),
              }) => CreatorsCompanion.insert(
                id: id,
                handle: handle,
                displayName: displayName,
                vertical: vertical,
                avatarRef: avatarRef,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CreatorsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({contentItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (contentItemsRefs) db.contentItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (contentItemsRefs)
                    await $_getPrefetchedData<
                      Creator,
                      $CreatorsTable,
                      ContentItem
                    >(
                      currentTable: table,
                      referencedTable: $$CreatorsTableReferences
                          ._contentItemsRefsTable(db),
                      managerFromTypedResult: (p0) => $$CreatorsTableReferences(
                        db,
                        table,
                        p0,
                      ).contentItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.creatorId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CreatorsTableProcessedTableManager =
    ProcessedTableManager<
      _$LoomDatabase,
      $CreatorsTable,
      Creator,
      $$CreatorsTableFilterComposer,
      $$CreatorsTableOrderingComposer,
      $$CreatorsTableAnnotationComposer,
      $$CreatorsTableCreateCompanionBuilder,
      $$CreatorsTableUpdateCompanionBuilder,
      (Creator, $$CreatorsTableReferences),
      Creator,
      PrefetchHooks Function({bool contentItemsRefs})
    >;
typedef $$ContentItemsTableCreateCompanionBuilder =
    ContentItemsCompanion Function({
      required String id,
      required String creatorId,
      required String contentType,
      required String title,
      required String summary,
      required String thumbnailRef,
      required DateTime createdAt,
      required double perfVelocity,
      Value<int> rowid,
    });
typedef $$ContentItemsTableUpdateCompanionBuilder =
    ContentItemsCompanion Function({
      Value<String> id,
      Value<String> creatorId,
      Value<String> contentType,
      Value<String> title,
      Value<String> summary,
      Value<String> thumbnailRef,
      Value<DateTime> createdAt,
      Value<double> perfVelocity,
      Value<int> rowid,
    });

final class $$ContentItemsTableReferences
    extends BaseReferences<_$LoomDatabase, $ContentItemsTable, ContentItem> {
  $$ContentItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CreatorsTable _creatorIdTable(_$LoomDatabase db) =>
      db.creators.createAlias(
        $_aliasNameGenerator(db.contentItems.creatorId, db.creators.id),
      );

  $$CreatorsTableProcessedTableManager get creatorId {
    final $_column = $_itemColumn<String>('creator_id')!;

    final manager = $$CreatorsTableTableManager(
      $_db,
      $_db.creators,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_creatorIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ContentItemsTableFilterComposer
    extends Composer<_$LoomDatabase, $ContentItemsTable> {
  $$ContentItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailRef => $composableBuilder(
    column: $table.thumbnailRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get perfVelocity => $composableBuilder(
    column: $table.perfVelocity,
    builder: (column) => ColumnFilters(column),
  );

  $$CreatorsTableFilterComposer get creatorId {
    final $$CreatorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.creatorId,
      referencedTable: $db.creators,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreatorsTableFilterComposer(
            $db: $db,
            $table: $db.creators,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContentItemsTableOrderingComposer
    extends Composer<_$LoomDatabase, $ContentItemsTable> {
  $$ContentItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailRef => $composableBuilder(
    column: $table.thumbnailRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get perfVelocity => $composableBuilder(
    column: $table.perfVelocity,
    builder: (column) => ColumnOrderings(column),
  );

  $$CreatorsTableOrderingComposer get creatorId {
    final $$CreatorsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.creatorId,
      referencedTable: $db.creators,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreatorsTableOrderingComposer(
            $db: $db,
            $table: $db.creators,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContentItemsTableAnnotationComposer
    extends Composer<_$LoomDatabase, $ContentItemsTable> {
  $$ContentItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get thumbnailRef => $composableBuilder(
    column: $table.thumbnailRef,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<double> get perfVelocity => $composableBuilder(
    column: $table.perfVelocity,
    builder: (column) => column,
  );

  $$CreatorsTableAnnotationComposer get creatorId {
    final $$CreatorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.creatorId,
      referencedTable: $db.creators,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreatorsTableAnnotationComposer(
            $db: $db,
            $table: $db.creators,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContentItemsTableTableManager
    extends
        RootTableManager<
          _$LoomDatabase,
          $ContentItemsTable,
          ContentItem,
          $$ContentItemsTableFilterComposer,
          $$ContentItemsTableOrderingComposer,
          $$ContentItemsTableAnnotationComposer,
          $$ContentItemsTableCreateCompanionBuilder,
          $$ContentItemsTableUpdateCompanionBuilder,
          (ContentItem, $$ContentItemsTableReferences),
          ContentItem,
          PrefetchHooks Function({bool creatorId})
        > {
  $$ContentItemsTableTableManager(_$LoomDatabase db, $ContentItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContentItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContentItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContentItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> creatorId = const Value.absent(),
                Value<String> contentType = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<String> thumbnailRef = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<double> perfVelocity = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContentItemsCompanion(
                id: id,
                creatorId: creatorId,
                contentType: contentType,
                title: title,
                summary: summary,
                thumbnailRef: thumbnailRef,
                createdAt: createdAt,
                perfVelocity: perfVelocity,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String creatorId,
                required String contentType,
                required String title,
                required String summary,
                required String thumbnailRef,
                required DateTime createdAt,
                required double perfVelocity,
                Value<int> rowid = const Value.absent(),
              }) => ContentItemsCompanion.insert(
                id: id,
                creatorId: creatorId,
                contentType: contentType,
                title: title,
                summary: summary,
                thumbnailRef: thumbnailRef,
                createdAt: createdAt,
                perfVelocity: perfVelocity,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ContentItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({creatorId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (creatorId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.creatorId,
                                referencedTable: $$ContentItemsTableReferences
                                    ._creatorIdTable(db),
                                referencedColumn: $$ContentItemsTableReferences
                                    ._creatorIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ContentItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$LoomDatabase,
      $ContentItemsTable,
      ContentItem,
      $$ContentItemsTableFilterComposer,
      $$ContentItemsTableOrderingComposer,
      $$ContentItemsTableAnnotationComposer,
      $$ContentItemsTableCreateCompanionBuilder,
      $$ContentItemsTableUpdateCompanionBuilder,
      (ContentItem, $$ContentItemsTableReferences),
      ContentItem,
      PrefetchHooks Function({bool creatorId})
    >;
typedef $$KvMetaTableCreateCompanionBuilder =
    KvMetaCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$KvMetaTableUpdateCompanionBuilder =
    KvMetaCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$KvMetaTableFilterComposer
    extends Composer<_$LoomDatabase, $KvMetaTable> {
  $$KvMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KvMetaTableOrderingComposer
    extends Composer<_$LoomDatabase, $KvMetaTable> {
  $$KvMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KvMetaTableAnnotationComposer
    extends Composer<_$LoomDatabase, $KvMetaTable> {
  $$KvMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$KvMetaTableTableManager
    extends
        RootTableManager<
          _$LoomDatabase,
          $KvMetaTable,
          KvMetaData,
          $$KvMetaTableFilterComposer,
          $$KvMetaTableOrderingComposer,
          $$KvMetaTableAnnotationComposer,
          $$KvMetaTableCreateCompanionBuilder,
          $$KvMetaTableUpdateCompanionBuilder,
          (
            KvMetaData,
            BaseReferences<_$LoomDatabase, $KvMetaTable, KvMetaData>,
          ),
          KvMetaData,
          PrefetchHooks Function()
        > {
  $$KvMetaTableTableManager(_$LoomDatabase db, $KvMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KvMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KvMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KvMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KvMetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) =>
                  KvMetaCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KvMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$LoomDatabase,
      $KvMetaTable,
      KvMetaData,
      $$KvMetaTableFilterComposer,
      $$KvMetaTableOrderingComposer,
      $$KvMetaTableAnnotationComposer,
      $$KvMetaTableCreateCompanionBuilder,
      $$KvMetaTableUpdateCompanionBuilder,
      (KvMetaData, BaseReferences<_$LoomDatabase, $KvMetaTable, KvMetaData>),
      KvMetaData,
      PrefetchHooks Function()
    >;

class $LoomDatabaseManager {
  final _$LoomDatabase _db;
  $LoomDatabaseManager(this._db);
  $$CreatorsTableTableManager get creators =>
      $$CreatorsTableTableManager(_db, _db.creators);
  $$ContentItemsTableTableManager get contentItems =>
      $$ContentItemsTableTableManager(_db, _db.contentItems);
  $$KvMetaTableTableManager get kvMeta =>
      $$KvMetaTableTableManager(_db, _db.kvMeta);
}
