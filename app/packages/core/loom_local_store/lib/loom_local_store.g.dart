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

class $FanPassportsTable extends FanPassports
    with TableInfo<$FanPassportsTable, FanPassport> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FanPassportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _activePersonaIdMeta = const VerificationMeta(
    'activePersonaId',
  );
  @override
  late final GeneratedColumn<String> activePersonaId = GeneratedColumn<String>(
    'active_persona_id',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    displayName,
    activePersonaId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fan_passports';
  @override
  VerificationContext validateIntegrity(
    Insertable<FanPassport> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
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
    if (data.containsKey('active_persona_id')) {
      context.handle(
        _activePersonaIdMeta,
        activePersonaId.isAcceptableOrUnknown(
          data['active_persona_id']!,
          _activePersonaIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activePersonaIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FanPassport map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FanPassport(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      activePersonaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}active_persona_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FanPassportsTable createAlias(String alias) {
    return $FanPassportsTable(attachedDatabase, alias);
  }
}

class FanPassport extends DataClass implements Insertable<FanPassport> {
  final String id;
  final String displayName;
  final String activePersonaId;
  final DateTime createdAt;
  const FanPassport({
    required this.id,
    required this.displayName,
    required this.activePersonaId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['display_name'] = Variable<String>(displayName);
    map['active_persona_id'] = Variable<String>(activePersonaId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FanPassportsCompanion toCompanion(bool nullToAbsent) {
    return FanPassportsCompanion(
      id: Value(id),
      displayName: Value(displayName),
      activePersonaId: Value(activePersonaId),
      createdAt: Value(createdAt),
    );
  }

  factory FanPassport.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FanPassport(
      id: serializer.fromJson<String>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      activePersonaId: serializer.fromJson<String>(json['activePersonaId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'displayName': serializer.toJson<String>(displayName),
      'activePersonaId': serializer.toJson<String>(activePersonaId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FanPassport copyWith({
    String? id,
    String? displayName,
    String? activePersonaId,
    DateTime? createdAt,
  }) => FanPassport(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    activePersonaId: activePersonaId ?? this.activePersonaId,
    createdAt: createdAt ?? this.createdAt,
  );
  FanPassport copyWithCompanion(FanPassportsCompanion data) {
    return FanPassport(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      activePersonaId: data.activePersonaId.present
          ? data.activePersonaId.value
          : this.activePersonaId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FanPassport(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('activePersonaId: $activePersonaId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, displayName, activePersonaId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FanPassport &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.activePersonaId == this.activePersonaId &&
          other.createdAt == this.createdAt);
}

class FanPassportsCompanion extends UpdateCompanion<FanPassport> {
  final Value<String> id;
  final Value<String> displayName;
  final Value<String> activePersonaId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const FanPassportsCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.activePersonaId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FanPassportsCompanion.insert({
    required String id,
    required String displayName,
    required String activePersonaId,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       displayName = Value(displayName),
       activePersonaId = Value(activePersonaId),
       createdAt = Value(createdAt);
  static Insertable<FanPassport> custom({
    Expression<String>? id,
    Expression<String>? displayName,
    Expression<String>? activePersonaId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (activePersonaId != null) 'active_persona_id': activePersonaId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FanPassportsCompanion copyWith({
    Value<String>? id,
    Value<String>? displayName,
    Value<String>? activePersonaId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return FanPassportsCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      activePersonaId: activePersonaId ?? this.activePersonaId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (activePersonaId.present) {
      map['active_persona_id'] = Variable<String>(activePersonaId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FanPassportsCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('activePersonaId: $activePersonaId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PersonasTable extends Personas with TableInfo<$PersonasTable, Persona> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passportIdMeta = const VerificationMeta(
    'passportId',
  );
  @override
  late final GeneratedColumn<String> passportId = GeneratedColumn<String>(
    'passport_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES fan_passports (id)',
    ),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id, passportId, label, isActive];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'personas';
  @override
  VerificationContext validateIntegrity(
    Insertable<Persona> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('passport_id')) {
      context.handle(
        _passportIdMeta,
        passportId.isAcceptableOrUnknown(data['passport_id']!, _passportIdMeta),
      );
    } else if (isInserting) {
      context.missing(_passportIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    } else if (isInserting) {
      context.missing(_isActiveMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Persona map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Persona(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      passportId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}passport_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $PersonasTable createAlias(String alias) {
    return $PersonasTable(attachedDatabase, alias);
  }
}

class Persona extends DataClass implements Insertable<Persona> {
  final String id;
  final String passportId;
  final String label;
  final bool isActive;
  const Persona({
    required this.id,
    required this.passportId,
    required this.label,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['passport_id'] = Variable<String>(passportId);
    map['label'] = Variable<String>(label);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  PersonasCompanion toCompanion(bool nullToAbsent) {
    return PersonasCompanion(
      id: Value(id),
      passportId: Value(passportId),
      label: Value(label),
      isActive: Value(isActive),
    );
  }

  factory Persona.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Persona(
      id: serializer.fromJson<String>(json['id']),
      passportId: serializer.fromJson<String>(json['passportId']),
      label: serializer.fromJson<String>(json['label']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'passportId': serializer.toJson<String>(passportId),
      'label': serializer.toJson<String>(label),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  Persona copyWith({
    String? id,
    String? passportId,
    String? label,
    bool? isActive,
  }) => Persona(
    id: id ?? this.id,
    passportId: passportId ?? this.passportId,
    label: label ?? this.label,
    isActive: isActive ?? this.isActive,
  );
  Persona copyWithCompanion(PersonasCompanion data) {
    return Persona(
      id: data.id.present ? data.id.value : this.id,
      passportId: data.passportId.present
          ? data.passportId.value
          : this.passportId,
      label: data.label.present ? data.label.value : this.label,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Persona(')
          ..write('id: $id, ')
          ..write('passportId: $passportId, ')
          ..write('label: $label, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, passportId, label, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Persona &&
          other.id == this.id &&
          other.passportId == this.passportId &&
          other.label == this.label &&
          other.isActive == this.isActive);
}

class PersonasCompanion extends UpdateCompanion<Persona> {
  final Value<String> id;
  final Value<String> passportId;
  final Value<String> label;
  final Value<bool> isActive;
  final Value<int> rowid;
  const PersonasCompanion({
    this.id = const Value.absent(),
    this.passportId = const Value.absent(),
    this.label = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PersonasCompanion.insert({
    required String id,
    required String passportId,
    required String label,
    required bool isActive,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       passportId = Value(passportId),
       label = Value(label),
       isActive = Value(isActive);
  static Insertable<Persona> custom({
    Expression<String>? id,
    Expression<String>? passportId,
    Expression<String>? label,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (passportId != null) 'passport_id': passportId,
      if (label != null) 'label': label,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PersonasCompanion copyWith({
    Value<String>? id,
    Value<String>? passportId,
    Value<String>? label,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return PersonasCompanion(
      id: id ?? this.id,
      passportId: passportId ?? this.passportId,
      label: label ?? this.label,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (passportId.present) {
      map['passport_id'] = Variable<String>(passportId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonasCompanion(')
          ..write('id: $id, ')
          ..write('passportId: $passportId, ')
          ..write('label: $label, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FollowsTable extends Follows with TableInfo<$FollowsTable, Follow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FollowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passportIdMeta = const VerificationMeta(
    'passportId',
  );
  @override
  late final GeneratedColumn<String> passportId = GeneratedColumn<String>(
    'passport_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES fan_passports (id)',
    ),
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
  static const VerificationMeta _visibilityMeta = const VerificationMeta(
    'visibility',
  );
  @override
  late final GeneratedColumn<String> visibility = GeneratedColumn<String>(
    'visibility',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _blockedMeta = const VerificationMeta(
    'blocked',
  );
  @override
  late final GeneratedColumn<bool> blocked = GeneratedColumn<bool>(
    'blocked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("blocked" IN (0, 1))',
    ),
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    passportId,
    creatorId,
    visibility,
    blocked,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'follows';
  @override
  VerificationContext validateIntegrity(
    Insertable<Follow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('passport_id')) {
      context.handle(
        _passportIdMeta,
        passportId.isAcceptableOrUnknown(data['passport_id']!, _passportIdMeta),
      );
    } else if (isInserting) {
      context.missing(_passportIdMeta);
    }
    if (data.containsKey('creator_id')) {
      context.handle(
        _creatorIdMeta,
        creatorId.isAcceptableOrUnknown(data['creator_id']!, _creatorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_creatorIdMeta);
    }
    if (data.containsKey('visibility')) {
      context.handle(
        _visibilityMeta,
        visibility.isAcceptableOrUnknown(data['visibility']!, _visibilityMeta),
      );
    } else if (isInserting) {
      context.missing(_visibilityMeta);
    }
    if (data.containsKey('blocked')) {
      context.handle(
        _blockedMeta,
        blocked.isAcceptableOrUnknown(data['blocked']!, _blockedMeta),
      );
    } else if (isInserting) {
      context.missing(_blockedMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Follow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Follow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      passportId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}passport_id'],
      )!,
      creatorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creator_id'],
      )!,
      visibility: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visibility'],
      )!,
      blocked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}blocked'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FollowsTable createAlias(String alias) {
    return $FollowsTable(attachedDatabase, alias);
  }
}

class Follow extends DataClass implements Insertable<Follow> {
  final String id;
  final String passportId;
  final String creatorId;
  final String visibility;
  final bool blocked;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Follow({
    required this.id,
    required this.passportId,
    required this.creatorId,
    required this.visibility,
    required this.blocked,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['passport_id'] = Variable<String>(passportId);
    map['creator_id'] = Variable<String>(creatorId);
    map['visibility'] = Variable<String>(visibility);
    map['blocked'] = Variable<bool>(blocked);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FollowsCompanion toCompanion(bool nullToAbsent) {
    return FollowsCompanion(
      id: Value(id),
      passportId: Value(passportId),
      creatorId: Value(creatorId),
      visibility: Value(visibility),
      blocked: Value(blocked),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Follow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Follow(
      id: serializer.fromJson<String>(json['id']),
      passportId: serializer.fromJson<String>(json['passportId']),
      creatorId: serializer.fromJson<String>(json['creatorId']),
      visibility: serializer.fromJson<String>(json['visibility']),
      blocked: serializer.fromJson<bool>(json['blocked']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'passportId': serializer.toJson<String>(passportId),
      'creatorId': serializer.toJson<String>(creatorId),
      'visibility': serializer.toJson<String>(visibility),
      'blocked': serializer.toJson<bool>(blocked),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Follow copyWith({
    String? id,
    String? passportId,
    String? creatorId,
    String? visibility,
    bool? blocked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Follow(
    id: id ?? this.id,
    passportId: passportId ?? this.passportId,
    creatorId: creatorId ?? this.creatorId,
    visibility: visibility ?? this.visibility,
    blocked: blocked ?? this.blocked,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Follow copyWithCompanion(FollowsCompanion data) {
    return Follow(
      id: data.id.present ? data.id.value : this.id,
      passportId: data.passportId.present
          ? data.passportId.value
          : this.passportId,
      creatorId: data.creatorId.present ? data.creatorId.value : this.creatorId,
      visibility: data.visibility.present
          ? data.visibility.value
          : this.visibility,
      blocked: data.blocked.present ? data.blocked.value : this.blocked,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Follow(')
          ..write('id: $id, ')
          ..write('passportId: $passportId, ')
          ..write('creatorId: $creatorId, ')
          ..write('visibility: $visibility, ')
          ..write('blocked: $blocked, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    passportId,
    creatorId,
    visibility,
    blocked,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Follow &&
          other.id == this.id &&
          other.passportId == this.passportId &&
          other.creatorId == this.creatorId &&
          other.visibility == this.visibility &&
          other.blocked == this.blocked &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FollowsCompanion extends UpdateCompanion<Follow> {
  final Value<String> id;
  final Value<String> passportId;
  final Value<String> creatorId;
  final Value<String> visibility;
  final Value<bool> blocked;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const FollowsCompanion({
    this.id = const Value.absent(),
    this.passportId = const Value.absent(),
    this.creatorId = const Value.absent(),
    this.visibility = const Value.absent(),
    this.blocked = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FollowsCompanion.insert({
    required String id,
    required String passportId,
    required String creatorId,
    required String visibility,
    required bool blocked,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       passportId = Value(passportId),
       creatorId = Value(creatorId),
       visibility = Value(visibility),
       blocked = Value(blocked),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Follow> custom({
    Expression<String>? id,
    Expression<String>? passportId,
    Expression<String>? creatorId,
    Expression<String>? visibility,
    Expression<bool>? blocked,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (passportId != null) 'passport_id': passportId,
      if (creatorId != null) 'creator_id': creatorId,
      if (visibility != null) 'visibility': visibility,
      if (blocked != null) 'blocked': blocked,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FollowsCompanion copyWith({
    Value<String>? id,
    Value<String>? passportId,
    Value<String>? creatorId,
    Value<String>? visibility,
    Value<bool>? blocked,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return FollowsCompanion(
      id: id ?? this.id,
      passportId: passportId ?? this.passportId,
      creatorId: creatorId ?? this.creatorId,
      visibility: visibility ?? this.visibility,
      blocked: blocked ?? this.blocked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (passportId.present) {
      map['passport_id'] = Variable<String>(passportId.value);
    }
    if (creatorId.present) {
      map['creator_id'] = Variable<String>(creatorId.value);
    }
    if (visibility.present) {
      map['visibility'] = Variable<String>(visibility.value);
    }
    if (blocked.present) {
      map['blocked'] = Variable<bool>(blocked.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FollowsCompanion(')
          ..write('id: $id, ')
          ..write('passportId: $passportId, ')
          ..write('creatorId: $creatorId, ')
          ..write('visibility: $visibility, ')
          ..write('blocked: $blocked, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConsentGrantsTable extends ConsentGrants
    with TableInfo<$ConsentGrantsTable, ConsentGrant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConsentGrantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passportIdMeta = const VerificationMeta(
    'passportId',
  );
  @override
  late final GeneratedColumn<String> passportId = GeneratedColumn<String>(
    'passport_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES fan_passports (id)',
    ),
  );
  static const VerificationMeta _grantTypeMeta = const VerificationMeta(
    'grantType',
  );
  @override
  late final GeneratedColumn<String> grantType = GeneratedColumn<String>(
    'grant_type',
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
  @override
  List<GeneratedColumn> get $columns => [id, passportId, grantType, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'consent_grants';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConsentGrant> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('passport_id')) {
      context.handle(
        _passportIdMeta,
        passportId.isAcceptableOrUnknown(data['passport_id']!, _passportIdMeta),
      );
    } else if (isInserting) {
      context.missing(_passportIdMeta);
    }
    if (data.containsKey('grant_type')) {
      context.handle(
        _grantTypeMeta,
        grantType.isAcceptableOrUnknown(data['grant_type']!, _grantTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_grantTypeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConsentGrant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConsentGrant(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      passportId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}passport_id'],
      )!,
      grantType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grant_type'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ConsentGrantsTable createAlias(String alias) {
    return $ConsentGrantsTable(attachedDatabase, alias);
  }
}

class ConsentGrant extends DataClass implements Insertable<ConsentGrant> {
  final String id;
  final String passportId;
  final String grantType;
  final DateTime createdAt;
  const ConsentGrant({
    required this.id,
    required this.passportId,
    required this.grantType,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['passport_id'] = Variable<String>(passportId);
    map['grant_type'] = Variable<String>(grantType);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ConsentGrantsCompanion toCompanion(bool nullToAbsent) {
    return ConsentGrantsCompanion(
      id: Value(id),
      passportId: Value(passportId),
      grantType: Value(grantType),
      createdAt: Value(createdAt),
    );
  }

  factory ConsentGrant.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConsentGrant(
      id: serializer.fromJson<String>(json['id']),
      passportId: serializer.fromJson<String>(json['passportId']),
      grantType: serializer.fromJson<String>(json['grantType']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'passportId': serializer.toJson<String>(passportId),
      'grantType': serializer.toJson<String>(grantType),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ConsentGrant copyWith({
    String? id,
    String? passportId,
    String? grantType,
    DateTime? createdAt,
  }) => ConsentGrant(
    id: id ?? this.id,
    passportId: passportId ?? this.passportId,
    grantType: grantType ?? this.grantType,
    createdAt: createdAt ?? this.createdAt,
  );
  ConsentGrant copyWithCompanion(ConsentGrantsCompanion data) {
    return ConsentGrant(
      id: data.id.present ? data.id.value : this.id,
      passportId: data.passportId.present
          ? data.passportId.value
          : this.passportId,
      grantType: data.grantType.present ? data.grantType.value : this.grantType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConsentGrant(')
          ..write('id: $id, ')
          ..write('passportId: $passportId, ')
          ..write('grantType: $grantType, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, passportId, grantType, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConsentGrant &&
          other.id == this.id &&
          other.passportId == this.passportId &&
          other.grantType == this.grantType &&
          other.createdAt == this.createdAt);
}

class ConsentGrantsCompanion extends UpdateCompanion<ConsentGrant> {
  final Value<String> id;
  final Value<String> passportId;
  final Value<String> grantType;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ConsentGrantsCompanion({
    this.id = const Value.absent(),
    this.passportId = const Value.absent(),
    this.grantType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConsentGrantsCompanion.insert({
    required String id,
    required String passportId,
    required String grantType,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       passportId = Value(passportId),
       grantType = Value(grantType),
       createdAt = Value(createdAt);
  static Insertable<ConsentGrant> custom({
    Expression<String>? id,
    Expression<String>? passportId,
    Expression<String>? grantType,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (passportId != null) 'passport_id': passportId,
      if (grantType != null) 'grant_type': grantType,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConsentGrantsCompanion copyWith({
    Value<String>? id,
    Value<String>? passportId,
    Value<String>? grantType,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ConsentGrantsCompanion(
      id: id ?? this.id,
      passportId: passportId ?? this.passportId,
      grantType: grantType ?? this.grantType,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (passportId.present) {
      map['passport_id'] = Variable<String>(passportId.value);
    }
    if (grantType.present) {
      map['grant_type'] = Variable<String>(grantType.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConsentGrantsCompanion(')
          ..write('id: $id, ')
          ..write('passportId: $passportId, ')
          ..write('grantType: $grantType, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InterestTaxonomyTable extends InterestTaxonomy
    with TableInfo<$InterestTaxonomyTable, InterestTaxonomyData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InterestTaxonomyTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, label, category];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'interest_taxonomy';
  @override
  VerificationContext validateIntegrity(
    Insertable<InterestTaxonomyData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InterestTaxonomyData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InterestTaxonomyData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
    );
  }

  @override
  $InterestTaxonomyTable createAlias(String alias) {
    return $InterestTaxonomyTable(attachedDatabase, alias);
  }
}

class InterestTaxonomyData extends DataClass
    implements Insertable<InterestTaxonomyData> {
  final String id;
  final String label;
  final String category;
  const InterestTaxonomyData({
    required this.id,
    required this.label,
    required this.category,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['label'] = Variable<String>(label);
    map['category'] = Variable<String>(category);
    return map;
  }

  InterestTaxonomyCompanion toCompanion(bool nullToAbsent) {
    return InterestTaxonomyCompanion(
      id: Value(id),
      label: Value(label),
      category: Value(category),
    );
  }

  factory InterestTaxonomyData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InterestTaxonomyData(
      id: serializer.fromJson<String>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      category: serializer.fromJson<String>(json['category']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'label': serializer.toJson<String>(label),
      'category': serializer.toJson<String>(category),
    };
  }

  InterestTaxonomyData copyWith({
    String? id,
    String? label,
    String? category,
  }) => InterestTaxonomyData(
    id: id ?? this.id,
    label: label ?? this.label,
    category: category ?? this.category,
  );
  InterestTaxonomyData copyWithCompanion(InterestTaxonomyCompanion data) {
    return InterestTaxonomyData(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      category: data.category.present ? data.category.value : this.category,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InterestTaxonomyData(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('category: $category')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, label, category);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InterestTaxonomyData &&
          other.id == this.id &&
          other.label == this.label &&
          other.category == this.category);
}

class InterestTaxonomyCompanion extends UpdateCompanion<InterestTaxonomyData> {
  final Value<String> id;
  final Value<String> label;
  final Value<String> category;
  final Value<int> rowid;
  const InterestTaxonomyCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.category = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InterestTaxonomyCompanion.insert({
    required String id,
    required String label,
    required String category,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       label = Value(label),
       category = Value(category);
  static Insertable<InterestTaxonomyData> custom({
    Expression<String>? id,
    Expression<String>? label,
    Expression<String>? category,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (category != null) 'category': category,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InterestTaxonomyCompanion copyWith({
    Value<String>? id,
    Value<String>? label,
    Value<String>? category,
    Value<int>? rowid,
  }) {
    return InterestTaxonomyCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      category: category ?? this.category,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InterestTaxonomyCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('category: $category, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FanInterestProfilesTable extends FanInterestProfiles
    with TableInfo<$FanInterestProfilesTable, FanInterestProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FanInterestProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _passportIdMeta = const VerificationMeta(
    'passportId',
  );
  @override
  late final GeneratedColumn<String> passportId = GeneratedColumn<String>(
    'passport_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES fan_passports (id)',
    ),
  );
  static const VerificationMeta _interestIdsJsonMeta = const VerificationMeta(
    'interestIdsJson',
  );
  @override
  late final GeneratedColumn<String> interestIdsJson = GeneratedColumn<String>(
    'interest_ids_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dislikedInterestIdsJsonMeta =
      const VerificationMeta('dislikedInterestIdsJson');
  @override
  late final GeneratedColumn<String> dislikedInterestIdsJson =
      GeneratedColumn<String>(
        'disliked_interest_ids_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _dislikedCreatorIdsJsonMeta =
      const VerificationMeta('dislikedCreatorIdsJson');
  @override
  late final GeneratedColumn<String> dislikedCreatorIdsJson =
      GeneratedColumn<String>(
        'disliked_creator_ids_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _mutedProviderIdsJsonMeta =
      const VerificationMeta('mutedProviderIdsJson');
  @override
  late final GeneratedColumn<String> mutedProviderIdsJson =
      GeneratedColumn<String>(
        'muted_provider_ids_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    passportId,
    interestIdsJson,
    dislikedInterestIdsJson,
    dislikedCreatorIdsJson,
    mutedProviderIdsJson,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fan_interest_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<FanInterestProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('passport_id')) {
      context.handle(
        _passportIdMeta,
        passportId.isAcceptableOrUnknown(data['passport_id']!, _passportIdMeta),
      );
    } else if (isInserting) {
      context.missing(_passportIdMeta);
    }
    if (data.containsKey('interest_ids_json')) {
      context.handle(
        _interestIdsJsonMeta,
        interestIdsJson.isAcceptableOrUnknown(
          data['interest_ids_json']!,
          _interestIdsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_interestIdsJsonMeta);
    }
    if (data.containsKey('disliked_interest_ids_json')) {
      context.handle(
        _dislikedInterestIdsJsonMeta,
        dislikedInterestIdsJson.isAcceptableOrUnknown(
          data['disliked_interest_ids_json']!,
          _dislikedInterestIdsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dislikedInterestIdsJsonMeta);
    }
    if (data.containsKey('disliked_creator_ids_json')) {
      context.handle(
        _dislikedCreatorIdsJsonMeta,
        dislikedCreatorIdsJson.isAcceptableOrUnknown(
          data['disliked_creator_ids_json']!,
          _dislikedCreatorIdsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dislikedCreatorIdsJsonMeta);
    }
    if (data.containsKey('muted_provider_ids_json')) {
      context.handle(
        _mutedProviderIdsJsonMeta,
        mutedProviderIdsJson.isAcceptableOrUnknown(
          data['muted_provider_ids_json']!,
          _mutedProviderIdsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mutedProviderIdsJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {passportId};
  @override
  FanInterestProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FanInterestProfile(
      passportId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}passport_id'],
      )!,
      interestIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}interest_ids_json'],
      )!,
      dislikedInterestIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}disliked_interest_ids_json'],
      )!,
      dislikedCreatorIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}disliked_creator_ids_json'],
      )!,
      mutedProviderIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}muted_provider_ids_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FanInterestProfilesTable createAlias(String alias) {
    return $FanInterestProfilesTable(attachedDatabase, alias);
  }
}

class FanInterestProfile extends DataClass
    implements Insertable<FanInterestProfile> {
  final String passportId;
  final String interestIdsJson;
  final String dislikedInterestIdsJson;
  final String dislikedCreatorIdsJson;
  final String mutedProviderIdsJson;
  final DateTime updatedAt;
  const FanInterestProfile({
    required this.passportId,
    required this.interestIdsJson,
    required this.dislikedInterestIdsJson,
    required this.dislikedCreatorIdsJson,
    required this.mutedProviderIdsJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['passport_id'] = Variable<String>(passportId);
    map['interest_ids_json'] = Variable<String>(interestIdsJson);
    map['disliked_interest_ids_json'] = Variable<String>(
      dislikedInterestIdsJson,
    );
    map['disliked_creator_ids_json'] = Variable<String>(dislikedCreatorIdsJson);
    map['muted_provider_ids_json'] = Variable<String>(mutedProviderIdsJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FanInterestProfilesCompanion toCompanion(bool nullToAbsent) {
    return FanInterestProfilesCompanion(
      passportId: Value(passportId),
      interestIdsJson: Value(interestIdsJson),
      dislikedInterestIdsJson: Value(dislikedInterestIdsJson),
      dislikedCreatorIdsJson: Value(dislikedCreatorIdsJson),
      mutedProviderIdsJson: Value(mutedProviderIdsJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory FanInterestProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FanInterestProfile(
      passportId: serializer.fromJson<String>(json['passportId']),
      interestIdsJson: serializer.fromJson<String>(json['interestIdsJson']),
      dislikedInterestIdsJson: serializer.fromJson<String>(
        json['dislikedInterestIdsJson'],
      ),
      dislikedCreatorIdsJson: serializer.fromJson<String>(
        json['dislikedCreatorIdsJson'],
      ),
      mutedProviderIdsJson: serializer.fromJson<String>(
        json['mutedProviderIdsJson'],
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'passportId': serializer.toJson<String>(passportId),
      'interestIdsJson': serializer.toJson<String>(interestIdsJson),
      'dislikedInterestIdsJson': serializer.toJson<String>(
        dislikedInterestIdsJson,
      ),
      'dislikedCreatorIdsJson': serializer.toJson<String>(
        dislikedCreatorIdsJson,
      ),
      'mutedProviderIdsJson': serializer.toJson<String>(mutedProviderIdsJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FanInterestProfile copyWith({
    String? passportId,
    String? interestIdsJson,
    String? dislikedInterestIdsJson,
    String? dislikedCreatorIdsJson,
    String? mutedProviderIdsJson,
    DateTime? updatedAt,
  }) => FanInterestProfile(
    passportId: passportId ?? this.passportId,
    interestIdsJson: interestIdsJson ?? this.interestIdsJson,
    dislikedInterestIdsJson:
        dislikedInterestIdsJson ?? this.dislikedInterestIdsJson,
    dislikedCreatorIdsJson:
        dislikedCreatorIdsJson ?? this.dislikedCreatorIdsJson,
    mutedProviderIdsJson: mutedProviderIdsJson ?? this.mutedProviderIdsJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FanInterestProfile copyWithCompanion(FanInterestProfilesCompanion data) {
    return FanInterestProfile(
      passportId: data.passportId.present
          ? data.passportId.value
          : this.passportId,
      interestIdsJson: data.interestIdsJson.present
          ? data.interestIdsJson.value
          : this.interestIdsJson,
      dislikedInterestIdsJson: data.dislikedInterestIdsJson.present
          ? data.dislikedInterestIdsJson.value
          : this.dislikedInterestIdsJson,
      dislikedCreatorIdsJson: data.dislikedCreatorIdsJson.present
          ? data.dislikedCreatorIdsJson.value
          : this.dislikedCreatorIdsJson,
      mutedProviderIdsJson: data.mutedProviderIdsJson.present
          ? data.mutedProviderIdsJson.value
          : this.mutedProviderIdsJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FanInterestProfile(')
          ..write('passportId: $passportId, ')
          ..write('interestIdsJson: $interestIdsJson, ')
          ..write('dislikedInterestIdsJson: $dislikedInterestIdsJson, ')
          ..write('dislikedCreatorIdsJson: $dislikedCreatorIdsJson, ')
          ..write('mutedProviderIdsJson: $mutedProviderIdsJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    passportId,
    interestIdsJson,
    dislikedInterestIdsJson,
    dislikedCreatorIdsJson,
    mutedProviderIdsJson,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FanInterestProfile &&
          other.passportId == this.passportId &&
          other.interestIdsJson == this.interestIdsJson &&
          other.dislikedInterestIdsJson == this.dislikedInterestIdsJson &&
          other.dislikedCreatorIdsJson == this.dislikedCreatorIdsJson &&
          other.mutedProviderIdsJson == this.mutedProviderIdsJson &&
          other.updatedAt == this.updatedAt);
}

class FanInterestProfilesCompanion extends UpdateCompanion<FanInterestProfile> {
  final Value<String> passportId;
  final Value<String> interestIdsJson;
  final Value<String> dislikedInterestIdsJson;
  final Value<String> dislikedCreatorIdsJson;
  final Value<String> mutedProviderIdsJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const FanInterestProfilesCompanion({
    this.passportId = const Value.absent(),
    this.interestIdsJson = const Value.absent(),
    this.dislikedInterestIdsJson = const Value.absent(),
    this.dislikedCreatorIdsJson = const Value.absent(),
    this.mutedProviderIdsJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FanInterestProfilesCompanion.insert({
    required String passportId,
    required String interestIdsJson,
    required String dislikedInterestIdsJson,
    required String dislikedCreatorIdsJson,
    required String mutedProviderIdsJson,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : passportId = Value(passportId),
       interestIdsJson = Value(interestIdsJson),
       dislikedInterestIdsJson = Value(dislikedInterestIdsJson),
       dislikedCreatorIdsJson = Value(dislikedCreatorIdsJson),
       mutedProviderIdsJson = Value(mutedProviderIdsJson),
       updatedAt = Value(updatedAt);
  static Insertable<FanInterestProfile> custom({
    Expression<String>? passportId,
    Expression<String>? interestIdsJson,
    Expression<String>? dislikedInterestIdsJson,
    Expression<String>? dislikedCreatorIdsJson,
    Expression<String>? mutedProviderIdsJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (passportId != null) 'passport_id': passportId,
      if (interestIdsJson != null) 'interest_ids_json': interestIdsJson,
      if (dislikedInterestIdsJson != null)
        'disliked_interest_ids_json': dislikedInterestIdsJson,
      if (dislikedCreatorIdsJson != null)
        'disliked_creator_ids_json': dislikedCreatorIdsJson,
      if (mutedProviderIdsJson != null)
        'muted_provider_ids_json': mutedProviderIdsJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FanInterestProfilesCompanion copyWith({
    Value<String>? passportId,
    Value<String>? interestIdsJson,
    Value<String>? dislikedInterestIdsJson,
    Value<String>? dislikedCreatorIdsJson,
    Value<String>? mutedProviderIdsJson,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return FanInterestProfilesCompanion(
      passportId: passportId ?? this.passportId,
      interestIdsJson: interestIdsJson ?? this.interestIdsJson,
      dislikedInterestIdsJson:
          dislikedInterestIdsJson ?? this.dislikedInterestIdsJson,
      dislikedCreatorIdsJson:
          dislikedCreatorIdsJson ?? this.dislikedCreatorIdsJson,
      mutedProviderIdsJson: mutedProviderIdsJson ?? this.mutedProviderIdsJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (passportId.present) {
      map['passport_id'] = Variable<String>(passportId.value);
    }
    if (interestIdsJson.present) {
      map['interest_ids_json'] = Variable<String>(interestIdsJson.value);
    }
    if (dislikedInterestIdsJson.present) {
      map['disliked_interest_ids_json'] = Variable<String>(
        dislikedInterestIdsJson.value,
      );
    }
    if (dislikedCreatorIdsJson.present) {
      map['disliked_creator_ids_json'] = Variable<String>(
        dislikedCreatorIdsJson.value,
      );
    }
    if (mutedProviderIdsJson.present) {
      map['muted_provider_ids_json'] = Variable<String>(
        mutedProviderIdsJson.value,
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FanInterestProfilesCompanion(')
          ..write('passportId: $passportId, ')
          ..write('interestIdsJson: $interestIdsJson, ')
          ..write('dislikedInterestIdsJson: $dislikedInterestIdsJson, ')
          ..write('dislikedCreatorIdsJson: $dislikedCreatorIdsJson, ')
          ..write('mutedProviderIdsJson: $mutedProviderIdsJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AdPreferencesTable extends AdPreferences
    with TableInfo<$AdPreferencesTable, AdPreference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AdPreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _passportIdMeta = const VerificationMeta(
    'passportId',
  );
  @override
  late final GeneratedColumn<String> passportId = GeneratedColumn<String>(
    'passport_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES fan_passports (id)',
    ),
  );
  static const VerificationMeta _personalizedAdsMeta = const VerificationMeta(
    'personalizedAds',
  );
  @override
  late final GeneratedColumn<bool> personalizedAds = GeneratedColumn<bool>(
    'personalized_ads',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("personalized_ads" IN (0, 1))',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    passportId,
    personalizedAds,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ad_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<AdPreference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('passport_id')) {
      context.handle(
        _passportIdMeta,
        passportId.isAcceptableOrUnknown(data['passport_id']!, _passportIdMeta),
      );
    } else if (isInserting) {
      context.missing(_passportIdMeta);
    }
    if (data.containsKey('personalized_ads')) {
      context.handle(
        _personalizedAdsMeta,
        personalizedAds.isAcceptableOrUnknown(
          data['personalized_ads']!,
          _personalizedAdsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_personalizedAdsMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {passportId};
  @override
  AdPreference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AdPreference(
      passportId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}passport_id'],
      )!,
      personalizedAds: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}personalized_ads'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AdPreferencesTable createAlias(String alias) {
    return $AdPreferencesTable(attachedDatabase, alias);
  }
}

class AdPreference extends DataClass implements Insertable<AdPreference> {
  final String passportId;
  final bool personalizedAds;
  final DateTime updatedAt;
  const AdPreference({
    required this.passportId,
    required this.personalizedAds,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['passport_id'] = Variable<String>(passportId);
    map['personalized_ads'] = Variable<bool>(personalizedAds);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AdPreferencesCompanion toCompanion(bool nullToAbsent) {
    return AdPreferencesCompanion(
      passportId: Value(passportId),
      personalizedAds: Value(personalizedAds),
      updatedAt: Value(updatedAt),
    );
  }

  factory AdPreference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AdPreference(
      passportId: serializer.fromJson<String>(json['passportId']),
      personalizedAds: serializer.fromJson<bool>(json['personalizedAds']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'passportId': serializer.toJson<String>(passportId),
      'personalizedAds': serializer.toJson<bool>(personalizedAds),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AdPreference copyWith({
    String? passportId,
    bool? personalizedAds,
    DateTime? updatedAt,
  }) => AdPreference(
    passportId: passportId ?? this.passportId,
    personalizedAds: personalizedAds ?? this.personalizedAds,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AdPreference copyWithCompanion(AdPreferencesCompanion data) {
    return AdPreference(
      passportId: data.passportId.present
          ? data.passportId.value
          : this.passportId,
      personalizedAds: data.personalizedAds.present
          ? data.personalizedAds.value
          : this.personalizedAds,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AdPreference(')
          ..write('passportId: $passportId, ')
          ..write('personalizedAds: $personalizedAds, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(passportId, personalizedAds, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdPreference &&
          other.passportId == this.passportId &&
          other.personalizedAds == this.personalizedAds &&
          other.updatedAt == this.updatedAt);
}

class AdPreferencesCompanion extends UpdateCompanion<AdPreference> {
  final Value<String> passportId;
  final Value<bool> personalizedAds;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AdPreferencesCompanion({
    this.passportId = const Value.absent(),
    this.personalizedAds = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AdPreferencesCompanion.insert({
    required String passportId,
    required bool personalizedAds,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : passportId = Value(passportId),
       personalizedAds = Value(personalizedAds),
       updatedAt = Value(updatedAt);
  static Insertable<AdPreference> custom({
    Expression<String>? passportId,
    Expression<bool>? personalizedAds,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (passportId != null) 'passport_id': passportId,
      if (personalizedAds != null) 'personalized_ads': personalizedAds,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AdPreferencesCompanion copyWith({
    Value<String>? passportId,
    Value<bool>? personalizedAds,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AdPreferencesCompanion(
      passportId: passportId ?? this.passportId,
      personalizedAds: personalizedAds ?? this.personalizedAds,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (passportId.present) {
      map['passport_id'] = Variable<String>(passportId.value);
    }
    if (personalizedAds.present) {
      map['personalized_ads'] = Variable<bool>(personalizedAds.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AdPreferencesCompanion(')
          ..write('passportId: $passportId, ')
          ..write('personalizedAds: $personalizedAds, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CreatorChannelsTable extends CreatorChannels
    with TableInfo<$CreatorChannelsTable, CreatorChannel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CreatorChannelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerPassportIdMeta = const VerificationMeta(
    'ownerPassportId',
  );
  @override
  late final GeneratedColumn<String> ownerPassportId = GeneratedColumn<String>(
    'owner_passport_id',
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
  static const VerificationMeta _handleMeta = const VerificationMeta('handle');
  @override
  late final GeneratedColumn<String> handle = GeneratedColumn<String>(
    'handle',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerPassportId,
    displayName,
    handle,
    vertical,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'creator_channels';
  @override
  VerificationContext validateIntegrity(
    Insertable<CreatorChannel> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_passport_id')) {
      context.handle(
        _ownerPassportIdMeta,
        ownerPassportId.isAcceptableOrUnknown(
          data['owner_passport_id']!,
          _ownerPassportIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ownerPassportIdMeta);
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
    if (data.containsKey('handle')) {
      context.handle(
        _handleMeta,
        handle.isAcceptableOrUnknown(data['handle']!, _handleMeta),
      );
    } else if (isInserting) {
      context.missing(_handleMeta);
    }
    if (data.containsKey('vertical')) {
      context.handle(
        _verticalMeta,
        vertical.isAcceptableOrUnknown(data['vertical']!, _verticalMeta),
      );
    } else if (isInserting) {
      context.missing(_verticalMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CreatorChannel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CreatorChannel(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ownerPassportId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_passport_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      handle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}handle'],
      )!,
      vertical: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vertical'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CreatorChannelsTable createAlias(String alias) {
    return $CreatorChannelsTable(attachedDatabase, alias);
  }
}

class CreatorChannel extends DataClass implements Insertable<CreatorChannel> {
  final String id;
  final String ownerPassportId;
  final String displayName;
  final String handle;
  final String vertical;
  final DateTime createdAt;
  const CreatorChannel({
    required this.id,
    required this.ownerPassportId,
    required this.displayName,
    required this.handle,
    required this.vertical,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['owner_passport_id'] = Variable<String>(ownerPassportId);
    map['display_name'] = Variable<String>(displayName);
    map['handle'] = Variable<String>(handle);
    map['vertical'] = Variable<String>(vertical);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CreatorChannelsCompanion toCompanion(bool nullToAbsent) {
    return CreatorChannelsCompanion(
      id: Value(id),
      ownerPassportId: Value(ownerPassportId),
      displayName: Value(displayName),
      handle: Value(handle),
      vertical: Value(vertical),
      createdAt: Value(createdAt),
    );
  }

  factory CreatorChannel.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CreatorChannel(
      id: serializer.fromJson<String>(json['id']),
      ownerPassportId: serializer.fromJson<String>(json['ownerPassportId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      handle: serializer.fromJson<String>(json['handle']),
      vertical: serializer.fromJson<String>(json['vertical']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerPassportId': serializer.toJson<String>(ownerPassportId),
      'displayName': serializer.toJson<String>(displayName),
      'handle': serializer.toJson<String>(handle),
      'vertical': serializer.toJson<String>(vertical),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CreatorChannel copyWith({
    String? id,
    String? ownerPassportId,
    String? displayName,
    String? handle,
    String? vertical,
    DateTime? createdAt,
  }) => CreatorChannel(
    id: id ?? this.id,
    ownerPassportId: ownerPassportId ?? this.ownerPassportId,
    displayName: displayName ?? this.displayName,
    handle: handle ?? this.handle,
    vertical: vertical ?? this.vertical,
    createdAt: createdAt ?? this.createdAt,
  );
  CreatorChannel copyWithCompanion(CreatorChannelsCompanion data) {
    return CreatorChannel(
      id: data.id.present ? data.id.value : this.id,
      ownerPassportId: data.ownerPassportId.present
          ? data.ownerPassportId.value
          : this.ownerPassportId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      handle: data.handle.present ? data.handle.value : this.handle,
      vertical: data.vertical.present ? data.vertical.value : this.vertical,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CreatorChannel(')
          ..write('id: $id, ')
          ..write('ownerPassportId: $ownerPassportId, ')
          ..write('displayName: $displayName, ')
          ..write('handle: $handle, ')
          ..write('vertical: $vertical, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ownerPassportId,
    displayName,
    handle,
    vertical,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CreatorChannel &&
          other.id == this.id &&
          other.ownerPassportId == this.ownerPassportId &&
          other.displayName == this.displayName &&
          other.handle == this.handle &&
          other.vertical == this.vertical &&
          other.createdAt == this.createdAt);
}

class CreatorChannelsCompanion extends UpdateCompanion<CreatorChannel> {
  final Value<String> id;
  final Value<String> ownerPassportId;
  final Value<String> displayName;
  final Value<String> handle;
  final Value<String> vertical;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CreatorChannelsCompanion({
    this.id = const Value.absent(),
    this.ownerPassportId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.handle = const Value.absent(),
    this.vertical = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CreatorChannelsCompanion.insert({
    required String id,
    required String ownerPassportId,
    required String displayName,
    required String handle,
    required String vertical,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ownerPassportId = Value(ownerPassportId),
       displayName = Value(displayName),
       handle = Value(handle),
       vertical = Value(vertical),
       createdAt = Value(createdAt);
  static Insertable<CreatorChannel> custom({
    Expression<String>? id,
    Expression<String>? ownerPassportId,
    Expression<String>? displayName,
    Expression<String>? handle,
    Expression<String>? vertical,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerPassportId != null) 'owner_passport_id': ownerPassportId,
      if (displayName != null) 'display_name': displayName,
      if (handle != null) 'handle': handle,
      if (vertical != null) 'vertical': vertical,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CreatorChannelsCompanion copyWith({
    Value<String>? id,
    Value<String>? ownerPassportId,
    Value<String>? displayName,
    Value<String>? handle,
    Value<String>? vertical,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CreatorChannelsCompanion(
      id: id ?? this.id,
      ownerPassportId: ownerPassportId ?? this.ownerPassportId,
      displayName: displayName ?? this.displayName,
      handle: handle ?? this.handle,
      vertical: vertical ?? this.vertical,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ownerPassportId.present) {
      map['owner_passport_id'] = Variable<String>(ownerPassportId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (handle.present) {
      map['handle'] = Variable<String>(handle.value);
    }
    if (vertical.present) {
      map['vertical'] = Variable<String>(vertical.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CreatorChannelsCompanion(')
          ..write('id: $id, ')
          ..write('ownerPassportId: $ownerPassportId, ')
          ..write('displayName: $displayName, ')
          ..write('handle: $handle, ')
          ..write('vertical: $vertical, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChannelManifestsTable extends ChannelManifests
    with TableInfo<$ChannelManifestsTable, ChannelManifest> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChannelManifestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
    'channel_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES creator_channels (id)',
    ),
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
  static const VerificationMeta _handleMeta = const VerificationMeta('handle');
  @override
  late final GeneratedColumn<String> handle = GeneratedColumn<String>(
    'handle',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
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
  @override
  List<GeneratedColumn> get $columns => [
    channelId,
    displayName,
    handle,
    description,
    category,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'channel_manifests';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChannelManifest> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_channelIdMeta);
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
    if (data.containsKey('handle')) {
      context.handle(
        _handleMeta,
        handle.isAcceptableOrUnknown(data['handle']!, _handleMeta),
      );
    } else if (isInserting) {
      context.missing(_handleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {channelId};
  @override
  ChannelManifest map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChannelManifest(
      channelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      handle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}handle'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ChannelManifestsTable createAlias(String alias) {
    return $ChannelManifestsTable(attachedDatabase, alias);
  }
}

class ChannelManifest extends DataClass implements Insertable<ChannelManifest> {
  final String channelId;
  final String displayName;
  final String handle;
  final String description;
  final String category;
  final DateTime createdAt;
  const ChannelManifest({
    required this.channelId,
    required this.displayName,
    required this.handle,
    required this.description,
    required this.category,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['channel_id'] = Variable<String>(channelId);
    map['display_name'] = Variable<String>(displayName);
    map['handle'] = Variable<String>(handle);
    map['description'] = Variable<String>(description);
    map['category'] = Variable<String>(category);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ChannelManifestsCompanion toCompanion(bool nullToAbsent) {
    return ChannelManifestsCompanion(
      channelId: Value(channelId),
      displayName: Value(displayName),
      handle: Value(handle),
      description: Value(description),
      category: Value(category),
      createdAt: Value(createdAt),
    );
  }

  factory ChannelManifest.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChannelManifest(
      channelId: serializer.fromJson<String>(json['channelId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      handle: serializer.fromJson<String>(json['handle']),
      description: serializer.fromJson<String>(json['description']),
      category: serializer.fromJson<String>(json['category']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'channelId': serializer.toJson<String>(channelId),
      'displayName': serializer.toJson<String>(displayName),
      'handle': serializer.toJson<String>(handle),
      'description': serializer.toJson<String>(description),
      'category': serializer.toJson<String>(category),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ChannelManifest copyWith({
    String? channelId,
    String? displayName,
    String? handle,
    String? description,
    String? category,
    DateTime? createdAt,
  }) => ChannelManifest(
    channelId: channelId ?? this.channelId,
    displayName: displayName ?? this.displayName,
    handle: handle ?? this.handle,
    description: description ?? this.description,
    category: category ?? this.category,
    createdAt: createdAt ?? this.createdAt,
  );
  ChannelManifest copyWithCompanion(ChannelManifestsCompanion data) {
    return ChannelManifest(
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      handle: data.handle.present ? data.handle.value : this.handle,
      description: data.description.present
          ? data.description.value
          : this.description,
      category: data.category.present ? data.category.value : this.category,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChannelManifest(')
          ..write('channelId: $channelId, ')
          ..write('displayName: $displayName, ')
          ..write('handle: $handle, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    channelId,
    displayName,
    handle,
    description,
    category,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChannelManifest &&
          other.channelId == this.channelId &&
          other.displayName == this.displayName &&
          other.handle == this.handle &&
          other.description == this.description &&
          other.category == this.category &&
          other.createdAt == this.createdAt);
}

class ChannelManifestsCompanion extends UpdateCompanion<ChannelManifest> {
  final Value<String> channelId;
  final Value<String> displayName;
  final Value<String> handle;
  final Value<String> description;
  final Value<String> category;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ChannelManifestsCompanion({
    this.channelId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.handle = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChannelManifestsCompanion.insert({
    required String channelId,
    required String displayName,
    required String handle,
    required String description,
    required String category,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : channelId = Value(channelId),
       displayName = Value(displayName),
       handle = Value(handle),
       description = Value(description),
       category = Value(category),
       createdAt = Value(createdAt);
  static Insertable<ChannelManifest> custom({
    Expression<String>? channelId,
    Expression<String>? displayName,
    Expression<String>? handle,
    Expression<String>? description,
    Expression<String>? category,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (channelId != null) 'channel_id': channelId,
      if (displayName != null) 'display_name': displayName,
      if (handle != null) 'handle': handle,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChannelManifestsCompanion copyWith({
    Value<String>? channelId,
    Value<String>? displayName,
    Value<String>? handle,
    Value<String>? description,
    Value<String>? category,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ChannelManifestsCompanion(
      channelId: channelId ?? this.channelId,
      displayName: displayName ?? this.displayName,
      handle: handle ?? this.handle,
      description: description ?? this.description,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (handle.present) {
      map['handle'] = Variable<String>(handle.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChannelManifestsCompanion(')
          ..write('channelId: $channelId, ')
          ..write('displayName: $displayName, ')
          ..write('handle: $handle, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HostingContractsTable extends HostingContracts
    with TableInfo<$HostingContractsTable, HostingContract> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HostingContractsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
    'channel_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES creator_channels (id)',
    ),
  );
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _termsVersionMeta = const VerificationMeta(
    'termsVersion',
  );
  @override
  late final GeneratedColumn<String> termsVersion = GeneratedColumn<String>(
    'terms_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _acceptedAtMeta = const VerificationMeta(
    'acceptedAt',
  );
  @override
  late final GeneratedColumn<DateTime> acceptedAt = GeneratedColumn<DateTime>(
    'accepted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    channelId,
    provider,
    status,
    termsVersion,
    acceptedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hosting_contracts';
  @override
  VerificationContext validateIntegrity(
    Insertable<HostingContract> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    } else if (isInserting) {
      context.missing(_providerMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('terms_version')) {
      context.handle(
        _termsVersionMeta,
        termsVersion.isAcceptableOrUnknown(
          data['terms_version']!,
          _termsVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_termsVersionMeta);
    }
    if (data.containsKey('accepted_at')) {
      context.handle(
        _acceptedAtMeta,
        acceptedAt.isAcceptableOrUnknown(data['accepted_at']!, _acceptedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_acceptedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HostingContract map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HostingContract(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      channelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel_id'],
      )!,
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      termsVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}terms_version'],
      )!,
      acceptedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}accepted_at'],
      )!,
    );
  }

  @override
  $HostingContractsTable createAlias(String alias) {
    return $HostingContractsTable(attachedDatabase, alias);
  }
}

class HostingContract extends DataClass implements Insertable<HostingContract> {
  final String id;
  final String channelId;
  final String provider;
  final String status;
  final String termsVersion;
  final DateTime acceptedAt;
  const HostingContract({
    required this.id,
    required this.channelId,
    required this.provider,
    required this.status,
    required this.termsVersion,
    required this.acceptedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['channel_id'] = Variable<String>(channelId);
    map['provider'] = Variable<String>(provider);
    map['status'] = Variable<String>(status);
    map['terms_version'] = Variable<String>(termsVersion);
    map['accepted_at'] = Variable<DateTime>(acceptedAt);
    return map;
  }

  HostingContractsCompanion toCompanion(bool nullToAbsent) {
    return HostingContractsCompanion(
      id: Value(id),
      channelId: Value(channelId),
      provider: Value(provider),
      status: Value(status),
      termsVersion: Value(termsVersion),
      acceptedAt: Value(acceptedAt),
    );
  }

  factory HostingContract.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HostingContract(
      id: serializer.fromJson<String>(json['id']),
      channelId: serializer.fromJson<String>(json['channelId']),
      provider: serializer.fromJson<String>(json['provider']),
      status: serializer.fromJson<String>(json['status']),
      termsVersion: serializer.fromJson<String>(json['termsVersion']),
      acceptedAt: serializer.fromJson<DateTime>(json['acceptedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'channelId': serializer.toJson<String>(channelId),
      'provider': serializer.toJson<String>(provider),
      'status': serializer.toJson<String>(status),
      'termsVersion': serializer.toJson<String>(termsVersion),
      'acceptedAt': serializer.toJson<DateTime>(acceptedAt),
    };
  }

  HostingContract copyWith({
    String? id,
    String? channelId,
    String? provider,
    String? status,
    String? termsVersion,
    DateTime? acceptedAt,
  }) => HostingContract(
    id: id ?? this.id,
    channelId: channelId ?? this.channelId,
    provider: provider ?? this.provider,
    status: status ?? this.status,
    termsVersion: termsVersion ?? this.termsVersion,
    acceptedAt: acceptedAt ?? this.acceptedAt,
  );
  HostingContract copyWithCompanion(HostingContractsCompanion data) {
    return HostingContract(
      id: data.id.present ? data.id.value : this.id,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      provider: data.provider.present ? data.provider.value : this.provider,
      status: data.status.present ? data.status.value : this.status,
      termsVersion: data.termsVersion.present
          ? data.termsVersion.value
          : this.termsVersion,
      acceptedAt: data.acceptedAt.present
          ? data.acceptedAt.value
          : this.acceptedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HostingContract(')
          ..write('id: $id, ')
          ..write('channelId: $channelId, ')
          ..write('provider: $provider, ')
          ..write('status: $status, ')
          ..write('termsVersion: $termsVersion, ')
          ..write('acceptedAt: $acceptedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, channelId, provider, status, termsVersion, acceptedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HostingContract &&
          other.id == this.id &&
          other.channelId == this.channelId &&
          other.provider == this.provider &&
          other.status == this.status &&
          other.termsVersion == this.termsVersion &&
          other.acceptedAt == this.acceptedAt);
}

class HostingContractsCompanion extends UpdateCompanion<HostingContract> {
  final Value<String> id;
  final Value<String> channelId;
  final Value<String> provider;
  final Value<String> status;
  final Value<String> termsVersion;
  final Value<DateTime> acceptedAt;
  final Value<int> rowid;
  const HostingContractsCompanion({
    this.id = const Value.absent(),
    this.channelId = const Value.absent(),
    this.provider = const Value.absent(),
    this.status = const Value.absent(),
    this.termsVersion = const Value.absent(),
    this.acceptedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HostingContractsCompanion.insert({
    required String id,
    required String channelId,
    required String provider,
    required String status,
    required String termsVersion,
    required DateTime acceptedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       channelId = Value(channelId),
       provider = Value(provider),
       status = Value(status),
       termsVersion = Value(termsVersion),
       acceptedAt = Value(acceptedAt);
  static Insertable<HostingContract> custom({
    Expression<String>? id,
    Expression<String>? channelId,
    Expression<String>? provider,
    Expression<String>? status,
    Expression<String>? termsVersion,
    Expression<DateTime>? acceptedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (channelId != null) 'channel_id': channelId,
      if (provider != null) 'provider': provider,
      if (status != null) 'status': status,
      if (termsVersion != null) 'terms_version': termsVersion,
      if (acceptedAt != null) 'accepted_at': acceptedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HostingContractsCompanion copyWith({
    Value<String>? id,
    Value<String>? channelId,
    Value<String>? provider,
    Value<String>? status,
    Value<String>? termsVersion,
    Value<DateTime>? acceptedAt,
    Value<int>? rowid,
  }) {
    return HostingContractsCompanion(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      provider: provider ?? this.provider,
      status: status ?? this.status,
      termsVersion: termsVersion ?? this.termsVersion,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (termsVersion.present) {
      map['terms_version'] = Variable<String>(termsVersion.value);
    }
    if (acceptedAt.present) {
      map['accepted_at'] = Variable<DateTime>(acceptedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HostingContractsCompanion(')
          ..write('id: $id, ')
          ..write('channelId: $channelId, ')
          ..write('provider: $provider, ')
          ..write('status: $status, ')
          ..write('termsVersion: $termsVersion, ')
          ..write('acceptedAt: $acceptedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IdempotencyRecordsTable extends IdempotencyRecords
    with TableInfo<$IdempotencyRecordsTable, IdempotencyRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IdempotencyRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetTypeMeta = const VerificationMeta(
    'targetType',
  );
  @override
  late final GeneratedColumn<String> targetType = GeneratedColumn<String>(
    'target_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
    'target_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, targetType, targetId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'idempotency_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<IdempotencyRecord> instance, {
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
    if (data.containsKey('target_type')) {
      context.handle(
        _targetTypeMeta,
        targetType.isAcceptableOrUnknown(data['target_type']!, _targetTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_targetTypeMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  IdempotencyRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IdempotencyRecord(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      targetType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_type'],
      )!,
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_id'],
      )!,
    );
  }

  @override
  $IdempotencyRecordsTable createAlias(String alias) {
    return $IdempotencyRecordsTable(attachedDatabase, alias);
  }
}

class IdempotencyRecord extends DataClass
    implements Insertable<IdempotencyRecord> {
  final String key;
  final String targetType;
  final String targetId;
  const IdempotencyRecord({
    required this.key,
    required this.targetType,
    required this.targetId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['target_type'] = Variable<String>(targetType);
    map['target_id'] = Variable<String>(targetId);
    return map;
  }

  IdempotencyRecordsCompanion toCompanion(bool nullToAbsent) {
    return IdempotencyRecordsCompanion(
      key: Value(key),
      targetType: Value(targetType),
      targetId: Value(targetId),
    );
  }

  factory IdempotencyRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IdempotencyRecord(
      key: serializer.fromJson<String>(json['key']),
      targetType: serializer.fromJson<String>(json['targetType']),
      targetId: serializer.fromJson<String>(json['targetId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'targetType': serializer.toJson<String>(targetType),
      'targetId': serializer.toJson<String>(targetId),
    };
  }

  IdempotencyRecord copyWith({
    String? key,
    String? targetType,
    String? targetId,
  }) => IdempotencyRecord(
    key: key ?? this.key,
    targetType: targetType ?? this.targetType,
    targetId: targetId ?? this.targetId,
  );
  IdempotencyRecord copyWithCompanion(IdempotencyRecordsCompanion data) {
    return IdempotencyRecord(
      key: data.key.present ? data.key.value : this.key,
      targetType: data.targetType.present
          ? data.targetType.value
          : this.targetType,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IdempotencyRecord(')
          ..write('key: $key, ')
          ..write('targetType: $targetType, ')
          ..write('targetId: $targetId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, targetType, targetId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IdempotencyRecord &&
          other.key == this.key &&
          other.targetType == this.targetType &&
          other.targetId == this.targetId);
}

class IdempotencyRecordsCompanion extends UpdateCompanion<IdempotencyRecord> {
  final Value<String> key;
  final Value<String> targetType;
  final Value<String> targetId;
  final Value<int> rowid;
  const IdempotencyRecordsCompanion({
    this.key = const Value.absent(),
    this.targetType = const Value.absent(),
    this.targetId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IdempotencyRecordsCompanion.insert({
    required String key,
    required String targetType,
    required String targetId,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       targetType = Value(targetType),
       targetId = Value(targetId);
  static Insertable<IdempotencyRecord> custom({
    Expression<String>? key,
    Expression<String>? targetType,
    Expression<String>? targetId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (targetType != null) 'target_type': targetType,
      if (targetId != null) 'target_id': targetId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IdempotencyRecordsCompanion copyWith({
    Value<String>? key,
    Value<String>? targetType,
    Value<String>? targetId,
    Value<int>? rowid,
  }) {
    return IdempotencyRecordsCompanion(
      key: key ?? this.key,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (targetType.present) {
      map['target_type'] = Variable<String>(targetType.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IdempotencyRecordsCompanion(')
          ..write('key: $key, ')
          ..write('targetType: $targetType, ')
          ..write('targetId: $targetId, ')
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
  late final $FanPassportsTable fanPassports = $FanPassportsTable(this);
  late final $PersonasTable personas = $PersonasTable(this);
  late final $FollowsTable follows = $FollowsTable(this);
  late final $ConsentGrantsTable consentGrants = $ConsentGrantsTable(this);
  late final $InterestTaxonomyTable interestTaxonomy = $InterestTaxonomyTable(
    this,
  );
  late final $FanInterestProfilesTable fanInterestProfiles =
      $FanInterestProfilesTable(this);
  late final $AdPreferencesTable adPreferences = $AdPreferencesTable(this);
  late final $CreatorChannelsTable creatorChannels = $CreatorChannelsTable(
    this,
  );
  late final $ChannelManifestsTable channelManifests = $ChannelManifestsTable(
    this,
  );
  late final $HostingContractsTable hostingContracts = $HostingContractsTable(
    this,
  );
  late final $IdempotencyRecordsTable idempotencyRecords =
      $IdempotencyRecordsTable(this);
  late final $KvMetaTable kvMeta = $KvMetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    creators,
    contentItems,
    fanPassports,
    personas,
    follows,
    consentGrants,
    interestTaxonomy,
    fanInterestProfiles,
    adPreferences,
    creatorChannels,
    channelManifests,
    hostingContracts,
    idempotencyRecords,
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

  static MultiTypedResultKey<$FollowsTable, List<Follow>> _followsRefsTable(
    _$LoomDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.follows,
    aliasName: $_aliasNameGenerator(db.creators.id, db.follows.creatorId),
  );

  $$FollowsTableProcessedTableManager get followsRefs {
    final manager = $$FollowsTableTableManager(
      $_db,
      $_db.follows,
    ).filter((f) => f.creatorId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_followsRefsTable($_db));
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

  Expression<bool> followsRefs(
    Expression<bool> Function($$FollowsTableFilterComposer f) f,
  ) {
    final $$FollowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.follows,
      getReferencedColumn: (t) => t.creatorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FollowsTableFilterComposer(
            $db: $db,
            $table: $db.follows,
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

  Expression<T> followsRefs<T extends Object>(
    Expression<T> Function($$FollowsTableAnnotationComposer a) f,
  ) {
    final $$FollowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.follows,
      getReferencedColumn: (t) => t.creatorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FollowsTableAnnotationComposer(
            $db: $db,
            $table: $db.follows,
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
          PrefetchHooks Function({bool contentItemsRefs, bool followsRefs})
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
          prefetchHooksCallback:
              ({contentItemsRefs = false, followsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (contentItemsRefs) db.contentItems,
                    if (followsRefs) db.follows,
                  ],
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
                          managerFromTypedResult: (p0) =>
                              $$CreatorsTableReferences(
                                db,
                                table,
                                p0,
                              ).contentItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.creatorId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (followsRefs)
                        await $_getPrefetchedData<
                          Creator,
                          $CreatorsTable,
                          Follow
                        >(
                          currentTable: table,
                          referencedTable: $$CreatorsTableReferences
                              ._followsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CreatorsTableReferences(
                                db,
                                table,
                                p0,
                              ).followsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.creatorId == item.id,
                              ),
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
      PrefetchHooks Function({bool contentItemsRefs, bool followsRefs})
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
typedef $$FanPassportsTableCreateCompanionBuilder =
    FanPassportsCompanion Function({
      required String id,
      required String displayName,
      required String activePersonaId,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$FanPassportsTableUpdateCompanionBuilder =
    FanPassportsCompanion Function({
      Value<String> id,
      Value<String> displayName,
      Value<String> activePersonaId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$FanPassportsTableReferences
    extends BaseReferences<_$LoomDatabase, $FanPassportsTable, FanPassport> {
  $$FanPassportsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PersonasTable, List<Persona>> _personasRefsTable(
    _$LoomDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.personas,
    aliasName: $_aliasNameGenerator(db.fanPassports.id, db.personas.passportId),
  );

  $$PersonasTableProcessedTableManager get personasRefs {
    final manager = $$PersonasTableTableManager(
      $_db,
      $_db.personas,
    ).filter((f) => f.passportId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_personasRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FollowsTable, List<Follow>> _followsRefsTable(
    _$LoomDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.follows,
    aliasName: $_aliasNameGenerator(db.fanPassports.id, db.follows.passportId),
  );

  $$FollowsTableProcessedTableManager get followsRefs {
    final manager = $$FollowsTableTableManager(
      $_db,
      $_db.follows,
    ).filter((f) => f.passportId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_followsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ConsentGrantsTable, List<ConsentGrant>>
  _consentGrantsRefsTable(_$LoomDatabase db) => MultiTypedResultKey.fromTable(
    db.consentGrants,
    aliasName: $_aliasNameGenerator(
      db.fanPassports.id,
      db.consentGrants.passportId,
    ),
  );

  $$ConsentGrantsTableProcessedTableManager get consentGrantsRefs {
    final manager = $$ConsentGrantsTableTableManager(
      $_db,
      $_db.consentGrants,
    ).filter((f) => f.passportId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_consentGrantsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $FanInterestProfilesTable,
    List<FanInterestProfile>
  >
  _fanInterestProfilesRefsTable(_$LoomDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.fanInterestProfiles,
        aliasName: $_aliasNameGenerator(
          db.fanPassports.id,
          db.fanInterestProfiles.passportId,
        ),
      );

  $$FanInterestProfilesTableProcessedTableManager get fanInterestProfilesRefs {
    final manager = $$FanInterestProfilesTableTableManager(
      $_db,
      $_db.fanInterestProfiles,
    ).filter((f) => f.passportId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _fanInterestProfilesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AdPreferencesTable, List<AdPreference>>
  _adPreferencesRefsTable(_$LoomDatabase db) => MultiTypedResultKey.fromTable(
    db.adPreferences,
    aliasName: $_aliasNameGenerator(
      db.fanPassports.id,
      db.adPreferences.passportId,
    ),
  );

  $$AdPreferencesTableProcessedTableManager get adPreferencesRefs {
    final manager = $$AdPreferencesTableTableManager(
      $_db,
      $_db.adPreferences,
    ).filter((f) => f.passportId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_adPreferencesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FanPassportsTableFilterComposer
    extends Composer<_$LoomDatabase, $FanPassportsTable> {
  $$FanPassportsTableFilterComposer({
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

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activePersonaId => $composableBuilder(
    column: $table.activePersonaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> personasRefs(
    Expression<bool> Function($$PersonasTableFilterComposer f) f,
  ) {
    final $$PersonasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.personas,
      getReferencedColumn: (t) => t.passportId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonasTableFilterComposer(
            $db: $db,
            $table: $db.personas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> followsRefs(
    Expression<bool> Function($$FollowsTableFilterComposer f) f,
  ) {
    final $$FollowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.follows,
      getReferencedColumn: (t) => t.passportId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FollowsTableFilterComposer(
            $db: $db,
            $table: $db.follows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> consentGrantsRefs(
    Expression<bool> Function($$ConsentGrantsTableFilterComposer f) f,
  ) {
    final $$ConsentGrantsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.consentGrants,
      getReferencedColumn: (t) => t.passportId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConsentGrantsTableFilterComposer(
            $db: $db,
            $table: $db.consentGrants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> fanInterestProfilesRefs(
    Expression<bool> Function($$FanInterestProfilesTableFilterComposer f) f,
  ) {
    final $$FanInterestProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fanInterestProfiles,
      getReferencedColumn: (t) => t.passportId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FanInterestProfilesTableFilterComposer(
            $db: $db,
            $table: $db.fanInterestProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> adPreferencesRefs(
    Expression<bool> Function($$AdPreferencesTableFilterComposer f) f,
  ) {
    final $$AdPreferencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.adPreferences,
      getReferencedColumn: (t) => t.passportId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdPreferencesTableFilterComposer(
            $db: $db,
            $table: $db.adPreferences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FanPassportsTableOrderingComposer
    extends Composer<_$LoomDatabase, $FanPassportsTable> {
  $$FanPassportsTableOrderingComposer({
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

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activePersonaId => $composableBuilder(
    column: $table.activePersonaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FanPassportsTableAnnotationComposer
    extends Composer<_$LoomDatabase, $FanPassportsTable> {
  $$FanPassportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get activePersonaId => $composableBuilder(
    column: $table.activePersonaId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> personasRefs<T extends Object>(
    Expression<T> Function($$PersonasTableAnnotationComposer a) f,
  ) {
    final $$PersonasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.personas,
      getReferencedColumn: (t) => t.passportId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonasTableAnnotationComposer(
            $db: $db,
            $table: $db.personas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> followsRefs<T extends Object>(
    Expression<T> Function($$FollowsTableAnnotationComposer a) f,
  ) {
    final $$FollowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.follows,
      getReferencedColumn: (t) => t.passportId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FollowsTableAnnotationComposer(
            $db: $db,
            $table: $db.follows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> consentGrantsRefs<T extends Object>(
    Expression<T> Function($$ConsentGrantsTableAnnotationComposer a) f,
  ) {
    final $$ConsentGrantsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.consentGrants,
      getReferencedColumn: (t) => t.passportId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConsentGrantsTableAnnotationComposer(
            $db: $db,
            $table: $db.consentGrants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> fanInterestProfilesRefs<T extends Object>(
    Expression<T> Function($$FanInterestProfilesTableAnnotationComposer a) f,
  ) {
    final $$FanInterestProfilesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.fanInterestProfiles,
          getReferencedColumn: (t) => t.passportId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FanInterestProfilesTableAnnotationComposer(
                $db: $db,
                $table: $db.fanInterestProfiles,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> adPreferencesRefs<T extends Object>(
    Expression<T> Function($$AdPreferencesTableAnnotationComposer a) f,
  ) {
    final $$AdPreferencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.adPreferences,
      getReferencedColumn: (t) => t.passportId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdPreferencesTableAnnotationComposer(
            $db: $db,
            $table: $db.adPreferences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FanPassportsTableTableManager
    extends
        RootTableManager<
          _$LoomDatabase,
          $FanPassportsTable,
          FanPassport,
          $$FanPassportsTableFilterComposer,
          $$FanPassportsTableOrderingComposer,
          $$FanPassportsTableAnnotationComposer,
          $$FanPassportsTableCreateCompanionBuilder,
          $$FanPassportsTableUpdateCompanionBuilder,
          (FanPassport, $$FanPassportsTableReferences),
          FanPassport,
          PrefetchHooks Function({
            bool personasRefs,
            bool followsRefs,
            bool consentGrantsRefs,
            bool fanInterestProfilesRefs,
            bool adPreferencesRefs,
          })
        > {
  $$FanPassportsTableTableManager(_$LoomDatabase db, $FanPassportsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FanPassportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FanPassportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FanPassportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> activePersonaId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FanPassportsCompanion(
                id: id,
                displayName: displayName,
                activePersonaId: activePersonaId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String displayName,
                required String activePersonaId,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => FanPassportsCompanion.insert(
                id: id,
                displayName: displayName,
                activePersonaId: activePersonaId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FanPassportsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                personasRefs = false,
                followsRefs = false,
                consentGrantsRefs = false,
                fanInterestProfilesRefs = false,
                adPreferencesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (personasRefs) db.personas,
                    if (followsRefs) db.follows,
                    if (consentGrantsRefs) db.consentGrants,
                    if (fanInterestProfilesRefs) db.fanInterestProfiles,
                    if (adPreferencesRefs) db.adPreferences,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (personasRefs)
                        await $_getPrefetchedData<
                          FanPassport,
                          $FanPassportsTable,
                          Persona
                        >(
                          currentTable: table,
                          referencedTable: $$FanPassportsTableReferences
                              ._personasRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FanPassportsTableReferences(
                                db,
                                table,
                                p0,
                              ).personasRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.passportId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (followsRefs)
                        await $_getPrefetchedData<
                          FanPassport,
                          $FanPassportsTable,
                          Follow
                        >(
                          currentTable: table,
                          referencedTable: $$FanPassportsTableReferences
                              ._followsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FanPassportsTableReferences(
                                db,
                                table,
                                p0,
                              ).followsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.passportId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (consentGrantsRefs)
                        await $_getPrefetchedData<
                          FanPassport,
                          $FanPassportsTable,
                          ConsentGrant
                        >(
                          currentTable: table,
                          referencedTable: $$FanPassportsTableReferences
                              ._consentGrantsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FanPassportsTableReferences(
                                db,
                                table,
                                p0,
                              ).consentGrantsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.passportId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (fanInterestProfilesRefs)
                        await $_getPrefetchedData<
                          FanPassport,
                          $FanPassportsTable,
                          FanInterestProfile
                        >(
                          currentTable: table,
                          referencedTable: $$FanPassportsTableReferences
                              ._fanInterestProfilesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FanPassportsTableReferences(
                                db,
                                table,
                                p0,
                              ).fanInterestProfilesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.passportId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (adPreferencesRefs)
                        await $_getPrefetchedData<
                          FanPassport,
                          $FanPassportsTable,
                          AdPreference
                        >(
                          currentTable: table,
                          referencedTable: $$FanPassportsTableReferences
                              ._adPreferencesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FanPassportsTableReferences(
                                db,
                                table,
                                p0,
                              ).adPreferencesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.passportId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$FanPassportsTableProcessedTableManager =
    ProcessedTableManager<
      _$LoomDatabase,
      $FanPassportsTable,
      FanPassport,
      $$FanPassportsTableFilterComposer,
      $$FanPassportsTableOrderingComposer,
      $$FanPassportsTableAnnotationComposer,
      $$FanPassportsTableCreateCompanionBuilder,
      $$FanPassportsTableUpdateCompanionBuilder,
      (FanPassport, $$FanPassportsTableReferences),
      FanPassport,
      PrefetchHooks Function({
        bool personasRefs,
        bool followsRefs,
        bool consentGrantsRefs,
        bool fanInterestProfilesRefs,
        bool adPreferencesRefs,
      })
    >;
typedef $$PersonasTableCreateCompanionBuilder =
    PersonasCompanion Function({
      required String id,
      required String passportId,
      required String label,
      required bool isActive,
      Value<int> rowid,
    });
typedef $$PersonasTableUpdateCompanionBuilder =
    PersonasCompanion Function({
      Value<String> id,
      Value<String> passportId,
      Value<String> label,
      Value<bool> isActive,
      Value<int> rowid,
    });

final class $$PersonasTableReferences
    extends BaseReferences<_$LoomDatabase, $PersonasTable, Persona> {
  $$PersonasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FanPassportsTable _passportIdTable(_$LoomDatabase db) =>
      db.fanPassports.createAlias(
        $_aliasNameGenerator(db.personas.passportId, db.fanPassports.id),
      );

  $$FanPassportsTableProcessedTableManager get passportId {
    final $_column = $_itemColumn<String>('passport_id')!;

    final manager = $$FanPassportsTableTableManager(
      $_db,
      $_db.fanPassports,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_passportIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PersonasTableFilterComposer
    extends Composer<_$LoomDatabase, $PersonasTable> {
  $$PersonasTableFilterComposer({
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

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  $$FanPassportsTableFilterComposer get passportId {
    final $$FanPassportsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.passportId,
      referencedTable: $db.fanPassports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FanPassportsTableFilterComposer(
            $db: $db,
            $table: $db.fanPassports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PersonasTableOrderingComposer
    extends Composer<_$LoomDatabase, $PersonasTable> {
  $$PersonasTableOrderingComposer({
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

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  $$FanPassportsTableOrderingComposer get passportId {
    final $$FanPassportsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.passportId,
      referencedTable: $db.fanPassports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FanPassportsTableOrderingComposer(
            $db: $db,
            $table: $db.fanPassports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PersonasTableAnnotationComposer
    extends Composer<_$LoomDatabase, $PersonasTable> {
  $$PersonasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  $$FanPassportsTableAnnotationComposer get passportId {
    final $$FanPassportsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.passportId,
      referencedTable: $db.fanPassports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FanPassportsTableAnnotationComposer(
            $db: $db,
            $table: $db.fanPassports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PersonasTableTableManager
    extends
        RootTableManager<
          _$LoomDatabase,
          $PersonasTable,
          Persona,
          $$PersonasTableFilterComposer,
          $$PersonasTableOrderingComposer,
          $$PersonasTableAnnotationComposer,
          $$PersonasTableCreateCompanionBuilder,
          $$PersonasTableUpdateCompanionBuilder,
          (Persona, $$PersonasTableReferences),
          Persona,
          PrefetchHooks Function({bool passportId})
        > {
  $$PersonasTableTableManager(_$LoomDatabase db, $PersonasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PersonasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PersonasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> passportId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PersonasCompanion(
                id: id,
                passportId: passportId,
                label: label,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String passportId,
                required String label,
                required bool isActive,
                Value<int> rowid = const Value.absent(),
              }) => PersonasCompanion.insert(
                id: id,
                passportId: passportId,
                label: label,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PersonasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({passportId = false}) {
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
                    if (passportId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.passportId,
                                referencedTable: $$PersonasTableReferences
                                    ._passportIdTable(db),
                                referencedColumn: $$PersonasTableReferences
                                    ._passportIdTable(db)
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

typedef $$PersonasTableProcessedTableManager =
    ProcessedTableManager<
      _$LoomDatabase,
      $PersonasTable,
      Persona,
      $$PersonasTableFilterComposer,
      $$PersonasTableOrderingComposer,
      $$PersonasTableAnnotationComposer,
      $$PersonasTableCreateCompanionBuilder,
      $$PersonasTableUpdateCompanionBuilder,
      (Persona, $$PersonasTableReferences),
      Persona,
      PrefetchHooks Function({bool passportId})
    >;
typedef $$FollowsTableCreateCompanionBuilder =
    FollowsCompanion Function({
      required String id,
      required String passportId,
      required String creatorId,
      required String visibility,
      required bool blocked,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$FollowsTableUpdateCompanionBuilder =
    FollowsCompanion Function({
      Value<String> id,
      Value<String> passportId,
      Value<String> creatorId,
      Value<String> visibility,
      Value<bool> blocked,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$FollowsTableReferences
    extends BaseReferences<_$LoomDatabase, $FollowsTable, Follow> {
  $$FollowsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FanPassportsTable _passportIdTable(_$LoomDatabase db) =>
      db.fanPassports.createAlias(
        $_aliasNameGenerator(db.follows.passportId, db.fanPassports.id),
      );

  $$FanPassportsTableProcessedTableManager get passportId {
    final $_column = $_itemColumn<String>('passport_id')!;

    final manager = $$FanPassportsTableTableManager(
      $_db,
      $_db.fanPassports,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_passportIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CreatorsTable _creatorIdTable(_$LoomDatabase db) => db.creators
      .createAlias($_aliasNameGenerator(db.follows.creatorId, db.creators.id));

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

class $$FollowsTableFilterComposer
    extends Composer<_$LoomDatabase, $FollowsTable> {
  $$FollowsTableFilterComposer({
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

  ColumnFilters<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get blocked => $composableBuilder(
    column: $table.blocked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$FanPassportsTableFilterComposer get passportId {
    final $$FanPassportsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.passportId,
      referencedTable: $db.fanPassports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FanPassportsTableFilterComposer(
            $db: $db,
            $table: $db.fanPassports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

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

class $$FollowsTableOrderingComposer
    extends Composer<_$LoomDatabase, $FollowsTable> {
  $$FollowsTableOrderingComposer({
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

  ColumnOrderings<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get blocked => $composableBuilder(
    column: $table.blocked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$FanPassportsTableOrderingComposer get passportId {
    final $$FanPassportsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.passportId,
      referencedTable: $db.fanPassports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FanPassportsTableOrderingComposer(
            $db: $db,
            $table: $db.fanPassports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

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

class $$FollowsTableAnnotationComposer
    extends Composer<_$LoomDatabase, $FollowsTable> {
  $$FollowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get blocked =>
      $composableBuilder(column: $table.blocked, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$FanPassportsTableAnnotationComposer get passportId {
    final $$FanPassportsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.passportId,
      referencedTable: $db.fanPassports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FanPassportsTableAnnotationComposer(
            $db: $db,
            $table: $db.fanPassports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

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

class $$FollowsTableTableManager
    extends
        RootTableManager<
          _$LoomDatabase,
          $FollowsTable,
          Follow,
          $$FollowsTableFilterComposer,
          $$FollowsTableOrderingComposer,
          $$FollowsTableAnnotationComposer,
          $$FollowsTableCreateCompanionBuilder,
          $$FollowsTableUpdateCompanionBuilder,
          (Follow, $$FollowsTableReferences),
          Follow,
          PrefetchHooks Function({bool passportId, bool creatorId})
        > {
  $$FollowsTableTableManager(_$LoomDatabase db, $FollowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FollowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FollowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FollowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> passportId = const Value.absent(),
                Value<String> creatorId = const Value.absent(),
                Value<String> visibility = const Value.absent(),
                Value<bool> blocked = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FollowsCompanion(
                id: id,
                passportId: passportId,
                creatorId: creatorId,
                visibility: visibility,
                blocked: blocked,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String passportId,
                required String creatorId,
                required String visibility,
                required bool blocked,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => FollowsCompanion.insert(
                id: id,
                passportId: passportId,
                creatorId: creatorId,
                visibility: visibility,
                blocked: blocked,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FollowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({passportId = false, creatorId = false}) {
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
                    if (passportId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.passportId,
                                referencedTable: $$FollowsTableReferences
                                    ._passportIdTable(db),
                                referencedColumn: $$FollowsTableReferences
                                    ._passportIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (creatorId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.creatorId,
                                referencedTable: $$FollowsTableReferences
                                    ._creatorIdTable(db),
                                referencedColumn: $$FollowsTableReferences
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

typedef $$FollowsTableProcessedTableManager =
    ProcessedTableManager<
      _$LoomDatabase,
      $FollowsTable,
      Follow,
      $$FollowsTableFilterComposer,
      $$FollowsTableOrderingComposer,
      $$FollowsTableAnnotationComposer,
      $$FollowsTableCreateCompanionBuilder,
      $$FollowsTableUpdateCompanionBuilder,
      (Follow, $$FollowsTableReferences),
      Follow,
      PrefetchHooks Function({bool passportId, bool creatorId})
    >;
typedef $$ConsentGrantsTableCreateCompanionBuilder =
    ConsentGrantsCompanion Function({
      required String id,
      required String passportId,
      required String grantType,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ConsentGrantsTableUpdateCompanionBuilder =
    ConsentGrantsCompanion Function({
      Value<String> id,
      Value<String> passportId,
      Value<String> grantType,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$ConsentGrantsTableReferences
    extends BaseReferences<_$LoomDatabase, $ConsentGrantsTable, ConsentGrant> {
  $$ConsentGrantsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FanPassportsTable _passportIdTable(_$LoomDatabase db) =>
      db.fanPassports.createAlias(
        $_aliasNameGenerator(db.consentGrants.passportId, db.fanPassports.id),
      );

  $$FanPassportsTableProcessedTableManager get passportId {
    final $_column = $_itemColumn<String>('passport_id')!;

    final manager = $$FanPassportsTableTableManager(
      $_db,
      $_db.fanPassports,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_passportIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ConsentGrantsTableFilterComposer
    extends Composer<_$LoomDatabase, $ConsentGrantsTable> {
  $$ConsentGrantsTableFilterComposer({
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

  ColumnFilters<String> get grantType => $composableBuilder(
    column: $table.grantType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$FanPassportsTableFilterComposer get passportId {
    final $$FanPassportsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.passportId,
      referencedTable: $db.fanPassports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FanPassportsTableFilterComposer(
            $db: $db,
            $table: $db.fanPassports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConsentGrantsTableOrderingComposer
    extends Composer<_$LoomDatabase, $ConsentGrantsTable> {
  $$ConsentGrantsTableOrderingComposer({
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

  ColumnOrderings<String> get grantType => $composableBuilder(
    column: $table.grantType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$FanPassportsTableOrderingComposer get passportId {
    final $$FanPassportsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.passportId,
      referencedTable: $db.fanPassports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FanPassportsTableOrderingComposer(
            $db: $db,
            $table: $db.fanPassports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConsentGrantsTableAnnotationComposer
    extends Composer<_$LoomDatabase, $ConsentGrantsTable> {
  $$ConsentGrantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get grantType =>
      $composableBuilder(column: $table.grantType, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$FanPassportsTableAnnotationComposer get passportId {
    final $$FanPassportsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.passportId,
      referencedTable: $db.fanPassports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FanPassportsTableAnnotationComposer(
            $db: $db,
            $table: $db.fanPassports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConsentGrantsTableTableManager
    extends
        RootTableManager<
          _$LoomDatabase,
          $ConsentGrantsTable,
          ConsentGrant,
          $$ConsentGrantsTableFilterComposer,
          $$ConsentGrantsTableOrderingComposer,
          $$ConsentGrantsTableAnnotationComposer,
          $$ConsentGrantsTableCreateCompanionBuilder,
          $$ConsentGrantsTableUpdateCompanionBuilder,
          (ConsentGrant, $$ConsentGrantsTableReferences),
          ConsentGrant,
          PrefetchHooks Function({bool passportId})
        > {
  $$ConsentGrantsTableTableManager(_$LoomDatabase db, $ConsentGrantsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConsentGrantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConsentGrantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConsentGrantsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> passportId = const Value.absent(),
                Value<String> grantType = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConsentGrantsCompanion(
                id: id,
                passportId: passportId,
                grantType: grantType,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String passportId,
                required String grantType,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ConsentGrantsCompanion.insert(
                id: id,
                passportId: passportId,
                grantType: grantType,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ConsentGrantsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({passportId = false}) {
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
                    if (passportId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.passportId,
                                referencedTable: $$ConsentGrantsTableReferences
                                    ._passportIdTable(db),
                                referencedColumn: $$ConsentGrantsTableReferences
                                    ._passportIdTable(db)
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

typedef $$ConsentGrantsTableProcessedTableManager =
    ProcessedTableManager<
      _$LoomDatabase,
      $ConsentGrantsTable,
      ConsentGrant,
      $$ConsentGrantsTableFilterComposer,
      $$ConsentGrantsTableOrderingComposer,
      $$ConsentGrantsTableAnnotationComposer,
      $$ConsentGrantsTableCreateCompanionBuilder,
      $$ConsentGrantsTableUpdateCompanionBuilder,
      (ConsentGrant, $$ConsentGrantsTableReferences),
      ConsentGrant,
      PrefetchHooks Function({bool passportId})
    >;
typedef $$InterestTaxonomyTableCreateCompanionBuilder =
    InterestTaxonomyCompanion Function({
      required String id,
      required String label,
      required String category,
      Value<int> rowid,
    });
typedef $$InterestTaxonomyTableUpdateCompanionBuilder =
    InterestTaxonomyCompanion Function({
      Value<String> id,
      Value<String> label,
      Value<String> category,
      Value<int> rowid,
    });

class $$InterestTaxonomyTableFilterComposer
    extends Composer<_$LoomDatabase, $InterestTaxonomyTable> {
  $$InterestTaxonomyTableFilterComposer({
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

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InterestTaxonomyTableOrderingComposer
    extends Composer<_$LoomDatabase, $InterestTaxonomyTable> {
  $$InterestTaxonomyTableOrderingComposer({
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

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InterestTaxonomyTableAnnotationComposer
    extends Composer<_$LoomDatabase, $InterestTaxonomyTable> {
  $$InterestTaxonomyTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);
}

class $$InterestTaxonomyTableTableManager
    extends
        RootTableManager<
          _$LoomDatabase,
          $InterestTaxonomyTable,
          InterestTaxonomyData,
          $$InterestTaxonomyTableFilterComposer,
          $$InterestTaxonomyTableOrderingComposer,
          $$InterestTaxonomyTableAnnotationComposer,
          $$InterestTaxonomyTableCreateCompanionBuilder,
          $$InterestTaxonomyTableUpdateCompanionBuilder,
          (
            InterestTaxonomyData,
            BaseReferences<
              _$LoomDatabase,
              $InterestTaxonomyTable,
              InterestTaxonomyData
            >,
          ),
          InterestTaxonomyData,
          PrefetchHooks Function()
        > {
  $$InterestTaxonomyTableTableManager(
    _$LoomDatabase db,
    $InterestTaxonomyTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InterestTaxonomyTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InterestTaxonomyTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InterestTaxonomyTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InterestTaxonomyCompanion(
                id: id,
                label: label,
                category: category,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String label,
                required String category,
                Value<int> rowid = const Value.absent(),
              }) => InterestTaxonomyCompanion.insert(
                id: id,
                label: label,
                category: category,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InterestTaxonomyTableProcessedTableManager =
    ProcessedTableManager<
      _$LoomDatabase,
      $InterestTaxonomyTable,
      InterestTaxonomyData,
      $$InterestTaxonomyTableFilterComposer,
      $$InterestTaxonomyTableOrderingComposer,
      $$InterestTaxonomyTableAnnotationComposer,
      $$InterestTaxonomyTableCreateCompanionBuilder,
      $$InterestTaxonomyTableUpdateCompanionBuilder,
      (
        InterestTaxonomyData,
        BaseReferences<
          _$LoomDatabase,
          $InterestTaxonomyTable,
          InterestTaxonomyData
        >,
      ),
      InterestTaxonomyData,
      PrefetchHooks Function()
    >;
typedef $$FanInterestProfilesTableCreateCompanionBuilder =
    FanInterestProfilesCompanion Function({
      required String passportId,
      required String interestIdsJson,
      required String dislikedInterestIdsJson,
      required String dislikedCreatorIdsJson,
      required String mutedProviderIdsJson,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$FanInterestProfilesTableUpdateCompanionBuilder =
    FanInterestProfilesCompanion Function({
      Value<String> passportId,
      Value<String> interestIdsJson,
      Value<String> dislikedInterestIdsJson,
      Value<String> dislikedCreatorIdsJson,
      Value<String> mutedProviderIdsJson,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$FanInterestProfilesTableReferences
    extends
        BaseReferences<
          _$LoomDatabase,
          $FanInterestProfilesTable,
          FanInterestProfile
        > {
  $$FanInterestProfilesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FanPassportsTable _passportIdTable(_$LoomDatabase db) =>
      db.fanPassports.createAlias(
        $_aliasNameGenerator(
          db.fanInterestProfiles.passportId,
          db.fanPassports.id,
        ),
      );

  $$FanPassportsTableProcessedTableManager get passportId {
    final $_column = $_itemColumn<String>('passport_id')!;

    final manager = $$FanPassportsTableTableManager(
      $_db,
      $_db.fanPassports,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_passportIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FanInterestProfilesTableFilterComposer
    extends Composer<_$LoomDatabase, $FanInterestProfilesTable> {
  $$FanInterestProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get interestIdsJson => $composableBuilder(
    column: $table.interestIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dislikedInterestIdsJson => $composableBuilder(
    column: $table.dislikedInterestIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dislikedCreatorIdsJson => $composableBuilder(
    column: $table.dislikedCreatorIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mutedProviderIdsJson => $composableBuilder(
    column: $table.mutedProviderIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$FanPassportsTableFilterComposer get passportId {
    final $$FanPassportsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.passportId,
      referencedTable: $db.fanPassports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FanPassportsTableFilterComposer(
            $db: $db,
            $table: $db.fanPassports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FanInterestProfilesTableOrderingComposer
    extends Composer<_$LoomDatabase, $FanInterestProfilesTable> {
  $$FanInterestProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get interestIdsJson => $composableBuilder(
    column: $table.interestIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dislikedInterestIdsJson => $composableBuilder(
    column: $table.dislikedInterestIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dislikedCreatorIdsJson => $composableBuilder(
    column: $table.dislikedCreatorIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mutedProviderIdsJson => $composableBuilder(
    column: $table.mutedProviderIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$FanPassportsTableOrderingComposer get passportId {
    final $$FanPassportsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.passportId,
      referencedTable: $db.fanPassports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FanPassportsTableOrderingComposer(
            $db: $db,
            $table: $db.fanPassports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FanInterestProfilesTableAnnotationComposer
    extends Composer<_$LoomDatabase, $FanInterestProfilesTable> {
  $$FanInterestProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get interestIdsJson => $composableBuilder(
    column: $table.interestIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dislikedInterestIdsJson => $composableBuilder(
    column: $table.dislikedInterestIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dislikedCreatorIdsJson => $composableBuilder(
    column: $table.dislikedCreatorIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mutedProviderIdsJson => $composableBuilder(
    column: $table.mutedProviderIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$FanPassportsTableAnnotationComposer get passportId {
    final $$FanPassportsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.passportId,
      referencedTable: $db.fanPassports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FanPassportsTableAnnotationComposer(
            $db: $db,
            $table: $db.fanPassports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FanInterestProfilesTableTableManager
    extends
        RootTableManager<
          _$LoomDatabase,
          $FanInterestProfilesTable,
          FanInterestProfile,
          $$FanInterestProfilesTableFilterComposer,
          $$FanInterestProfilesTableOrderingComposer,
          $$FanInterestProfilesTableAnnotationComposer,
          $$FanInterestProfilesTableCreateCompanionBuilder,
          $$FanInterestProfilesTableUpdateCompanionBuilder,
          (FanInterestProfile, $$FanInterestProfilesTableReferences),
          FanInterestProfile,
          PrefetchHooks Function({bool passportId})
        > {
  $$FanInterestProfilesTableTableManager(
    _$LoomDatabase db,
    $FanInterestProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FanInterestProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FanInterestProfilesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$FanInterestProfilesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> passportId = const Value.absent(),
                Value<String> interestIdsJson = const Value.absent(),
                Value<String> dislikedInterestIdsJson = const Value.absent(),
                Value<String> dislikedCreatorIdsJson = const Value.absent(),
                Value<String> mutedProviderIdsJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FanInterestProfilesCompanion(
                passportId: passportId,
                interestIdsJson: interestIdsJson,
                dislikedInterestIdsJson: dislikedInterestIdsJson,
                dislikedCreatorIdsJson: dislikedCreatorIdsJson,
                mutedProviderIdsJson: mutedProviderIdsJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String passportId,
                required String interestIdsJson,
                required String dislikedInterestIdsJson,
                required String dislikedCreatorIdsJson,
                required String mutedProviderIdsJson,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => FanInterestProfilesCompanion.insert(
                passportId: passportId,
                interestIdsJson: interestIdsJson,
                dislikedInterestIdsJson: dislikedInterestIdsJson,
                dislikedCreatorIdsJson: dislikedCreatorIdsJson,
                mutedProviderIdsJson: mutedProviderIdsJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FanInterestProfilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({passportId = false}) {
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
                    if (passportId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.passportId,
                                referencedTable:
                                    $$FanInterestProfilesTableReferences
                                        ._passportIdTable(db),
                                referencedColumn:
                                    $$FanInterestProfilesTableReferences
                                        ._passportIdTable(db)
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

typedef $$FanInterestProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$LoomDatabase,
      $FanInterestProfilesTable,
      FanInterestProfile,
      $$FanInterestProfilesTableFilterComposer,
      $$FanInterestProfilesTableOrderingComposer,
      $$FanInterestProfilesTableAnnotationComposer,
      $$FanInterestProfilesTableCreateCompanionBuilder,
      $$FanInterestProfilesTableUpdateCompanionBuilder,
      (FanInterestProfile, $$FanInterestProfilesTableReferences),
      FanInterestProfile,
      PrefetchHooks Function({bool passportId})
    >;
typedef $$AdPreferencesTableCreateCompanionBuilder =
    AdPreferencesCompanion Function({
      required String passportId,
      required bool personalizedAds,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$AdPreferencesTableUpdateCompanionBuilder =
    AdPreferencesCompanion Function({
      Value<String> passportId,
      Value<bool> personalizedAds,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$AdPreferencesTableReferences
    extends BaseReferences<_$LoomDatabase, $AdPreferencesTable, AdPreference> {
  $$AdPreferencesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FanPassportsTable _passportIdTable(_$LoomDatabase db) =>
      db.fanPassports.createAlias(
        $_aliasNameGenerator(db.adPreferences.passportId, db.fanPassports.id),
      );

  $$FanPassportsTableProcessedTableManager get passportId {
    final $_column = $_itemColumn<String>('passport_id')!;

    final manager = $$FanPassportsTableTableManager(
      $_db,
      $_db.fanPassports,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_passportIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AdPreferencesTableFilterComposer
    extends Composer<_$LoomDatabase, $AdPreferencesTable> {
  $$AdPreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<bool> get personalizedAds => $composableBuilder(
    column: $table.personalizedAds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$FanPassportsTableFilterComposer get passportId {
    final $$FanPassportsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.passportId,
      referencedTable: $db.fanPassports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FanPassportsTableFilterComposer(
            $db: $db,
            $table: $db.fanPassports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AdPreferencesTableOrderingComposer
    extends Composer<_$LoomDatabase, $AdPreferencesTable> {
  $$AdPreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<bool> get personalizedAds => $composableBuilder(
    column: $table.personalizedAds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$FanPassportsTableOrderingComposer get passportId {
    final $$FanPassportsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.passportId,
      referencedTable: $db.fanPassports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FanPassportsTableOrderingComposer(
            $db: $db,
            $table: $db.fanPassports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AdPreferencesTableAnnotationComposer
    extends Composer<_$LoomDatabase, $AdPreferencesTable> {
  $$AdPreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<bool> get personalizedAds => $composableBuilder(
    column: $table.personalizedAds,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$FanPassportsTableAnnotationComposer get passportId {
    final $$FanPassportsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.passportId,
      referencedTable: $db.fanPassports,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FanPassportsTableAnnotationComposer(
            $db: $db,
            $table: $db.fanPassports,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AdPreferencesTableTableManager
    extends
        RootTableManager<
          _$LoomDatabase,
          $AdPreferencesTable,
          AdPreference,
          $$AdPreferencesTableFilterComposer,
          $$AdPreferencesTableOrderingComposer,
          $$AdPreferencesTableAnnotationComposer,
          $$AdPreferencesTableCreateCompanionBuilder,
          $$AdPreferencesTableUpdateCompanionBuilder,
          (AdPreference, $$AdPreferencesTableReferences),
          AdPreference,
          PrefetchHooks Function({bool passportId})
        > {
  $$AdPreferencesTableTableManager(_$LoomDatabase db, $AdPreferencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AdPreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AdPreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AdPreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> passportId = const Value.absent(),
                Value<bool> personalizedAds = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AdPreferencesCompanion(
                passportId: passportId,
                personalizedAds: personalizedAds,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String passportId,
                required bool personalizedAds,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AdPreferencesCompanion.insert(
                passportId: passportId,
                personalizedAds: personalizedAds,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AdPreferencesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({passportId = false}) {
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
                    if (passportId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.passportId,
                                referencedTable: $$AdPreferencesTableReferences
                                    ._passportIdTable(db),
                                referencedColumn: $$AdPreferencesTableReferences
                                    ._passportIdTable(db)
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

typedef $$AdPreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$LoomDatabase,
      $AdPreferencesTable,
      AdPreference,
      $$AdPreferencesTableFilterComposer,
      $$AdPreferencesTableOrderingComposer,
      $$AdPreferencesTableAnnotationComposer,
      $$AdPreferencesTableCreateCompanionBuilder,
      $$AdPreferencesTableUpdateCompanionBuilder,
      (AdPreference, $$AdPreferencesTableReferences),
      AdPreference,
      PrefetchHooks Function({bool passportId})
    >;
typedef $$CreatorChannelsTableCreateCompanionBuilder =
    CreatorChannelsCompanion Function({
      required String id,
      required String ownerPassportId,
      required String displayName,
      required String handle,
      required String vertical,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$CreatorChannelsTableUpdateCompanionBuilder =
    CreatorChannelsCompanion Function({
      Value<String> id,
      Value<String> ownerPassportId,
      Value<String> displayName,
      Value<String> handle,
      Value<String> vertical,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$CreatorChannelsTableReferences
    extends
        BaseReferences<_$LoomDatabase, $CreatorChannelsTable, CreatorChannel> {
  $$CreatorChannelsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ChannelManifestsTable, List<ChannelManifest>>
  _channelManifestsRefsTable(_$LoomDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.channelManifests,
        aliasName: $_aliasNameGenerator(
          db.creatorChannels.id,
          db.channelManifests.channelId,
        ),
      );

  $$ChannelManifestsTableProcessedTableManager get channelManifestsRefs {
    final manager = $$ChannelManifestsTableTableManager(
      $_db,
      $_db.channelManifests,
    ).filter((f) => f.channelId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _channelManifestsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$HostingContractsTable, List<HostingContract>>
  _hostingContractsRefsTable(_$LoomDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.hostingContracts,
        aliasName: $_aliasNameGenerator(
          db.creatorChannels.id,
          db.hostingContracts.channelId,
        ),
      );

  $$HostingContractsTableProcessedTableManager get hostingContractsRefs {
    final manager = $$HostingContractsTableTableManager(
      $_db,
      $_db.hostingContracts,
    ).filter((f) => f.channelId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _hostingContractsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CreatorChannelsTableFilterComposer
    extends Composer<_$LoomDatabase, $CreatorChannelsTable> {
  $$CreatorChannelsTableFilterComposer({
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

  ColumnFilters<String> get ownerPassportId => $composableBuilder(
    column: $table.ownerPassportId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get handle => $composableBuilder(
    column: $table.handle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vertical => $composableBuilder(
    column: $table.vertical,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> channelManifestsRefs(
    Expression<bool> Function($$ChannelManifestsTableFilterComposer f) f,
  ) {
    final $$ChannelManifestsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.channelManifests,
      getReferencedColumn: (t) => t.channelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelManifestsTableFilterComposer(
            $db: $db,
            $table: $db.channelManifests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> hostingContractsRefs(
    Expression<bool> Function($$HostingContractsTableFilterComposer f) f,
  ) {
    final $$HostingContractsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.hostingContracts,
      getReferencedColumn: (t) => t.channelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HostingContractsTableFilterComposer(
            $db: $db,
            $table: $db.hostingContracts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CreatorChannelsTableOrderingComposer
    extends Composer<_$LoomDatabase, $CreatorChannelsTable> {
  $$CreatorChannelsTableOrderingComposer({
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

  ColumnOrderings<String> get ownerPassportId => $composableBuilder(
    column: $table.ownerPassportId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get handle => $composableBuilder(
    column: $table.handle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vertical => $composableBuilder(
    column: $table.vertical,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CreatorChannelsTableAnnotationComposer
    extends Composer<_$LoomDatabase, $CreatorChannelsTable> {
  $$CreatorChannelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ownerPassportId => $composableBuilder(
    column: $table.ownerPassportId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get handle =>
      $composableBuilder(column: $table.handle, builder: (column) => column);

  GeneratedColumn<String> get vertical =>
      $composableBuilder(column: $table.vertical, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> channelManifestsRefs<T extends Object>(
    Expression<T> Function($$ChannelManifestsTableAnnotationComposer a) f,
  ) {
    final $$ChannelManifestsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.channelManifests,
      getReferencedColumn: (t) => t.channelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelManifestsTableAnnotationComposer(
            $db: $db,
            $table: $db.channelManifests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> hostingContractsRefs<T extends Object>(
    Expression<T> Function($$HostingContractsTableAnnotationComposer a) f,
  ) {
    final $$HostingContractsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.hostingContracts,
      getReferencedColumn: (t) => t.channelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HostingContractsTableAnnotationComposer(
            $db: $db,
            $table: $db.hostingContracts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CreatorChannelsTableTableManager
    extends
        RootTableManager<
          _$LoomDatabase,
          $CreatorChannelsTable,
          CreatorChannel,
          $$CreatorChannelsTableFilterComposer,
          $$CreatorChannelsTableOrderingComposer,
          $$CreatorChannelsTableAnnotationComposer,
          $$CreatorChannelsTableCreateCompanionBuilder,
          $$CreatorChannelsTableUpdateCompanionBuilder,
          (CreatorChannel, $$CreatorChannelsTableReferences),
          CreatorChannel,
          PrefetchHooks Function({
            bool channelManifestsRefs,
            bool hostingContractsRefs,
          })
        > {
  $$CreatorChannelsTableTableManager(
    _$LoomDatabase db,
    $CreatorChannelsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CreatorChannelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CreatorChannelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CreatorChannelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ownerPassportId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> handle = const Value.absent(),
                Value<String> vertical = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CreatorChannelsCompanion(
                id: id,
                ownerPassportId: ownerPassportId,
                displayName: displayName,
                handle: handle,
                vertical: vertical,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ownerPassportId,
                required String displayName,
                required String handle,
                required String vertical,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CreatorChannelsCompanion.insert(
                id: id,
                ownerPassportId: ownerPassportId,
                displayName: displayName,
                handle: handle,
                vertical: vertical,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CreatorChannelsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({channelManifestsRefs = false, hostingContractsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (channelManifestsRefs) db.channelManifests,
                    if (hostingContractsRefs) db.hostingContracts,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (channelManifestsRefs)
                        await $_getPrefetchedData<
                          CreatorChannel,
                          $CreatorChannelsTable,
                          ChannelManifest
                        >(
                          currentTable: table,
                          referencedTable: $$CreatorChannelsTableReferences
                              ._channelManifestsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CreatorChannelsTableReferences(
                                db,
                                table,
                                p0,
                              ).channelManifestsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.channelId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (hostingContractsRefs)
                        await $_getPrefetchedData<
                          CreatorChannel,
                          $CreatorChannelsTable,
                          HostingContract
                        >(
                          currentTable: table,
                          referencedTable: $$CreatorChannelsTableReferences
                              ._hostingContractsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CreatorChannelsTableReferences(
                                db,
                                table,
                                p0,
                              ).hostingContractsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.channelId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CreatorChannelsTableProcessedTableManager =
    ProcessedTableManager<
      _$LoomDatabase,
      $CreatorChannelsTable,
      CreatorChannel,
      $$CreatorChannelsTableFilterComposer,
      $$CreatorChannelsTableOrderingComposer,
      $$CreatorChannelsTableAnnotationComposer,
      $$CreatorChannelsTableCreateCompanionBuilder,
      $$CreatorChannelsTableUpdateCompanionBuilder,
      (CreatorChannel, $$CreatorChannelsTableReferences),
      CreatorChannel,
      PrefetchHooks Function({
        bool channelManifestsRefs,
        bool hostingContractsRefs,
      })
    >;
typedef $$ChannelManifestsTableCreateCompanionBuilder =
    ChannelManifestsCompanion Function({
      required String channelId,
      required String displayName,
      required String handle,
      required String description,
      required String category,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ChannelManifestsTableUpdateCompanionBuilder =
    ChannelManifestsCompanion Function({
      Value<String> channelId,
      Value<String> displayName,
      Value<String> handle,
      Value<String> description,
      Value<String> category,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$ChannelManifestsTableReferences
    extends
        BaseReferences<
          _$LoomDatabase,
          $ChannelManifestsTable,
          ChannelManifest
        > {
  $$ChannelManifestsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CreatorChannelsTable _channelIdTable(_$LoomDatabase db) =>
      db.creatorChannels.createAlias(
        $_aliasNameGenerator(
          db.channelManifests.channelId,
          db.creatorChannels.id,
        ),
      );

  $$CreatorChannelsTableProcessedTableManager get channelId {
    final $_column = $_itemColumn<String>('channel_id')!;

    final manager = $$CreatorChannelsTableTableManager(
      $_db,
      $_db.creatorChannels,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_channelIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ChannelManifestsTableFilterComposer
    extends Composer<_$LoomDatabase, $ChannelManifestsTable> {
  $$ChannelManifestsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get handle => $composableBuilder(
    column: $table.handle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CreatorChannelsTableFilterComposer get channelId {
    final $$CreatorChannelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.channelId,
      referencedTable: $db.creatorChannels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreatorChannelsTableFilterComposer(
            $db: $db,
            $table: $db.creatorChannels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChannelManifestsTableOrderingComposer
    extends Composer<_$LoomDatabase, $ChannelManifestsTable> {
  $$ChannelManifestsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get handle => $composableBuilder(
    column: $table.handle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CreatorChannelsTableOrderingComposer get channelId {
    final $$CreatorChannelsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.channelId,
      referencedTable: $db.creatorChannels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreatorChannelsTableOrderingComposer(
            $db: $db,
            $table: $db.creatorChannels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChannelManifestsTableAnnotationComposer
    extends Composer<_$LoomDatabase, $ChannelManifestsTable> {
  $$ChannelManifestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get handle =>
      $composableBuilder(column: $table.handle, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CreatorChannelsTableAnnotationComposer get channelId {
    final $$CreatorChannelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.channelId,
      referencedTable: $db.creatorChannels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreatorChannelsTableAnnotationComposer(
            $db: $db,
            $table: $db.creatorChannels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChannelManifestsTableTableManager
    extends
        RootTableManager<
          _$LoomDatabase,
          $ChannelManifestsTable,
          ChannelManifest,
          $$ChannelManifestsTableFilterComposer,
          $$ChannelManifestsTableOrderingComposer,
          $$ChannelManifestsTableAnnotationComposer,
          $$ChannelManifestsTableCreateCompanionBuilder,
          $$ChannelManifestsTableUpdateCompanionBuilder,
          (ChannelManifest, $$ChannelManifestsTableReferences),
          ChannelManifest,
          PrefetchHooks Function({bool channelId})
        > {
  $$ChannelManifestsTableTableManager(
    _$LoomDatabase db,
    $ChannelManifestsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChannelManifestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChannelManifestsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChannelManifestsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> channelId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> handle = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChannelManifestsCompanion(
                channelId: channelId,
                displayName: displayName,
                handle: handle,
                description: description,
                category: category,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String channelId,
                required String displayName,
                required String handle,
                required String description,
                required String category,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ChannelManifestsCompanion.insert(
                channelId: channelId,
                displayName: displayName,
                handle: handle,
                description: description,
                category: category,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ChannelManifestsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({channelId = false}) {
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
                    if (channelId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.channelId,
                                referencedTable:
                                    $$ChannelManifestsTableReferences
                                        ._channelIdTable(db),
                                referencedColumn:
                                    $$ChannelManifestsTableReferences
                                        ._channelIdTable(db)
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

typedef $$ChannelManifestsTableProcessedTableManager =
    ProcessedTableManager<
      _$LoomDatabase,
      $ChannelManifestsTable,
      ChannelManifest,
      $$ChannelManifestsTableFilterComposer,
      $$ChannelManifestsTableOrderingComposer,
      $$ChannelManifestsTableAnnotationComposer,
      $$ChannelManifestsTableCreateCompanionBuilder,
      $$ChannelManifestsTableUpdateCompanionBuilder,
      (ChannelManifest, $$ChannelManifestsTableReferences),
      ChannelManifest,
      PrefetchHooks Function({bool channelId})
    >;
typedef $$HostingContractsTableCreateCompanionBuilder =
    HostingContractsCompanion Function({
      required String id,
      required String channelId,
      required String provider,
      required String status,
      required String termsVersion,
      required DateTime acceptedAt,
      Value<int> rowid,
    });
typedef $$HostingContractsTableUpdateCompanionBuilder =
    HostingContractsCompanion Function({
      Value<String> id,
      Value<String> channelId,
      Value<String> provider,
      Value<String> status,
      Value<String> termsVersion,
      Value<DateTime> acceptedAt,
      Value<int> rowid,
    });

final class $$HostingContractsTableReferences
    extends
        BaseReferences<
          _$LoomDatabase,
          $HostingContractsTable,
          HostingContract
        > {
  $$HostingContractsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CreatorChannelsTable _channelIdTable(_$LoomDatabase db) =>
      db.creatorChannels.createAlias(
        $_aliasNameGenerator(
          db.hostingContracts.channelId,
          db.creatorChannels.id,
        ),
      );

  $$CreatorChannelsTableProcessedTableManager get channelId {
    final $_column = $_itemColumn<String>('channel_id')!;

    final manager = $$CreatorChannelsTableTableManager(
      $_db,
      $_db.creatorChannels,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_channelIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HostingContractsTableFilterComposer
    extends Composer<_$LoomDatabase, $HostingContractsTable> {
  $$HostingContractsTableFilterComposer({
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

  ColumnFilters<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get termsVersion => $composableBuilder(
    column: $table.termsVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get acceptedAt => $composableBuilder(
    column: $table.acceptedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CreatorChannelsTableFilterComposer get channelId {
    final $$CreatorChannelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.channelId,
      referencedTable: $db.creatorChannels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreatorChannelsTableFilterComposer(
            $db: $db,
            $table: $db.creatorChannels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HostingContractsTableOrderingComposer
    extends Composer<_$LoomDatabase, $HostingContractsTable> {
  $$HostingContractsTableOrderingComposer({
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

  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get termsVersion => $composableBuilder(
    column: $table.termsVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get acceptedAt => $composableBuilder(
    column: $table.acceptedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CreatorChannelsTableOrderingComposer get channelId {
    final $$CreatorChannelsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.channelId,
      referencedTable: $db.creatorChannels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreatorChannelsTableOrderingComposer(
            $db: $db,
            $table: $db.creatorChannels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HostingContractsTableAnnotationComposer
    extends Composer<_$LoomDatabase, $HostingContractsTable> {
  $$HostingContractsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get termsVersion => $composableBuilder(
    column: $table.termsVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get acceptedAt => $composableBuilder(
    column: $table.acceptedAt,
    builder: (column) => column,
  );

  $$CreatorChannelsTableAnnotationComposer get channelId {
    final $$CreatorChannelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.channelId,
      referencedTable: $db.creatorChannels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreatorChannelsTableAnnotationComposer(
            $db: $db,
            $table: $db.creatorChannels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HostingContractsTableTableManager
    extends
        RootTableManager<
          _$LoomDatabase,
          $HostingContractsTable,
          HostingContract,
          $$HostingContractsTableFilterComposer,
          $$HostingContractsTableOrderingComposer,
          $$HostingContractsTableAnnotationComposer,
          $$HostingContractsTableCreateCompanionBuilder,
          $$HostingContractsTableUpdateCompanionBuilder,
          (HostingContract, $$HostingContractsTableReferences),
          HostingContract,
          PrefetchHooks Function({bool channelId})
        > {
  $$HostingContractsTableTableManager(
    _$LoomDatabase db,
    $HostingContractsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HostingContractsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HostingContractsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HostingContractsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> channelId = const Value.absent(),
                Value<String> provider = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> termsVersion = const Value.absent(),
                Value<DateTime> acceptedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HostingContractsCompanion(
                id: id,
                channelId: channelId,
                provider: provider,
                status: status,
                termsVersion: termsVersion,
                acceptedAt: acceptedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String channelId,
                required String provider,
                required String status,
                required String termsVersion,
                required DateTime acceptedAt,
                Value<int> rowid = const Value.absent(),
              }) => HostingContractsCompanion.insert(
                id: id,
                channelId: channelId,
                provider: provider,
                status: status,
                termsVersion: termsVersion,
                acceptedAt: acceptedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$HostingContractsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({channelId = false}) {
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
                    if (channelId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.channelId,
                                referencedTable:
                                    $$HostingContractsTableReferences
                                        ._channelIdTable(db),
                                referencedColumn:
                                    $$HostingContractsTableReferences
                                        ._channelIdTable(db)
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

typedef $$HostingContractsTableProcessedTableManager =
    ProcessedTableManager<
      _$LoomDatabase,
      $HostingContractsTable,
      HostingContract,
      $$HostingContractsTableFilterComposer,
      $$HostingContractsTableOrderingComposer,
      $$HostingContractsTableAnnotationComposer,
      $$HostingContractsTableCreateCompanionBuilder,
      $$HostingContractsTableUpdateCompanionBuilder,
      (HostingContract, $$HostingContractsTableReferences),
      HostingContract,
      PrefetchHooks Function({bool channelId})
    >;
typedef $$IdempotencyRecordsTableCreateCompanionBuilder =
    IdempotencyRecordsCompanion Function({
      required String key,
      required String targetType,
      required String targetId,
      Value<int> rowid,
    });
typedef $$IdempotencyRecordsTableUpdateCompanionBuilder =
    IdempotencyRecordsCompanion Function({
      Value<String> key,
      Value<String> targetType,
      Value<String> targetId,
      Value<int> rowid,
    });

class $$IdempotencyRecordsTableFilterComposer
    extends Composer<_$LoomDatabase, $IdempotencyRecordsTable> {
  $$IdempotencyRecordsTableFilterComposer({
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

  ColumnFilters<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IdempotencyRecordsTableOrderingComposer
    extends Composer<_$LoomDatabase, $IdempotencyRecordsTable> {
  $$IdempotencyRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IdempotencyRecordsTableAnnotationComposer
    extends Composer<_$LoomDatabase, $IdempotencyRecordsTable> {
  $$IdempotencyRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);
}

class $$IdempotencyRecordsTableTableManager
    extends
        RootTableManager<
          _$LoomDatabase,
          $IdempotencyRecordsTable,
          IdempotencyRecord,
          $$IdempotencyRecordsTableFilterComposer,
          $$IdempotencyRecordsTableOrderingComposer,
          $$IdempotencyRecordsTableAnnotationComposer,
          $$IdempotencyRecordsTableCreateCompanionBuilder,
          $$IdempotencyRecordsTableUpdateCompanionBuilder,
          (
            IdempotencyRecord,
            BaseReferences<
              _$LoomDatabase,
              $IdempotencyRecordsTable,
              IdempotencyRecord
            >,
          ),
          IdempotencyRecord,
          PrefetchHooks Function()
        > {
  $$IdempotencyRecordsTableTableManager(
    _$LoomDatabase db,
    $IdempotencyRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IdempotencyRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IdempotencyRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IdempotencyRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> targetType = const Value.absent(),
                Value<String> targetId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IdempotencyRecordsCompanion(
                key: key,
                targetType: targetType,
                targetId: targetId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String targetType,
                required String targetId,
                Value<int> rowid = const Value.absent(),
              }) => IdempotencyRecordsCompanion.insert(
                key: key,
                targetType: targetType,
                targetId: targetId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IdempotencyRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$LoomDatabase,
      $IdempotencyRecordsTable,
      IdempotencyRecord,
      $$IdempotencyRecordsTableFilterComposer,
      $$IdempotencyRecordsTableOrderingComposer,
      $$IdempotencyRecordsTableAnnotationComposer,
      $$IdempotencyRecordsTableCreateCompanionBuilder,
      $$IdempotencyRecordsTableUpdateCompanionBuilder,
      (
        IdempotencyRecord,
        BaseReferences<
          _$LoomDatabase,
          $IdempotencyRecordsTable,
          IdempotencyRecord
        >,
      ),
      IdempotencyRecord,
      PrefetchHooks Function()
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
  $$FanPassportsTableTableManager get fanPassports =>
      $$FanPassportsTableTableManager(_db, _db.fanPassports);
  $$PersonasTableTableManager get personas =>
      $$PersonasTableTableManager(_db, _db.personas);
  $$FollowsTableTableManager get follows =>
      $$FollowsTableTableManager(_db, _db.follows);
  $$ConsentGrantsTableTableManager get consentGrants =>
      $$ConsentGrantsTableTableManager(_db, _db.consentGrants);
  $$InterestTaxonomyTableTableManager get interestTaxonomy =>
      $$InterestTaxonomyTableTableManager(_db, _db.interestTaxonomy);
  $$FanInterestProfilesTableTableManager get fanInterestProfiles =>
      $$FanInterestProfilesTableTableManager(_db, _db.fanInterestProfiles);
  $$AdPreferencesTableTableManager get adPreferences =>
      $$AdPreferencesTableTableManager(_db, _db.adPreferences);
  $$CreatorChannelsTableTableManager get creatorChannels =>
      $$CreatorChannelsTableTableManager(_db, _db.creatorChannels);
  $$ChannelManifestsTableTableManager get channelManifests =>
      $$ChannelManifestsTableTableManager(_db, _db.channelManifests);
  $$HostingContractsTableTableManager get hostingContracts =>
      $$HostingContractsTableTableManager(_db, _db.hostingContracts);
  $$IdempotencyRecordsTableTableManager get idempotencyRecords =>
      $$IdempotencyRecordsTableTableManager(_db, _db.idempotencyRecords);
  $$KvMetaTableTableManager get kvMeta =>
      $$KvMetaTableTableManager(_db, _db.kvMeta);
}
