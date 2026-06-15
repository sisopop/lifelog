// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DiaryEntriesTable extends DiaryEntries
    with TableInfo<$DiaryEntriesTable, DiaryEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiaryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
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
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aiSummaryMeta = const VerificationMeta(
    'aiSummary',
  );
  @override
  late final GeneratedColumn<String> aiSummary = GeneratedColumn<String>(
    'ai_summary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AiStatus, String> aiStatus =
      GeneratedColumn<String>(
        'ai_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AiStatus>($DiaryEntriesTable.$converteraiStatus);
  @override
  late final GeneratedColumnWithTypeConverter<Mood?, String> mood =
      GeneratedColumn<String>(
        'mood',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Mood?>($DiaryEntriesTable.$convertermoodn);
  @override
  late final GeneratedColumnWithTypeConverter<EntryVisibility, String>
  visibility = GeneratedColumn<String>(
    'visibility',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<EntryVisibility>($DiaryEntriesTable.$convertervisibility);
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> tags =
      GeneratedColumn<String>(
        'tags',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>($DiaryEntriesTable.$convertertags);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> mediaUrls =
      GeneratedColumn<String>(
        'media_urls',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>($DiaryEntriesTable.$convertermediaUrls);
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
  late final GeneratedColumnWithTypeConverter<SyncStatus, String> syncStatus =
      GeneratedColumn<String>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SyncStatus>($DiaryEntriesTable.$convertersyncStatus);
  @override
  List<GeneratedColumn> get $columns => [
    entryId,
    userId,
    title,
    content,
    aiSummary,
    aiStatus,
    mood,
    visibility,
    location,
    tags,
    mediaUrls,
    createdAt,
    updatedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'diary_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DiaryEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('ai_summary')) {
      context.handle(
        _aiSummaryMeta,
        aiSummary.isAcceptableOrUnknown(data['ai_summary']!, _aiSummaryMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
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
  Set<GeneratedColumn> get $primaryKey => {entryId};
  @override
  DiaryEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiaryEntryRow(
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      aiSummary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ai_summary'],
      ),
      aiStatus: $DiaryEntriesTable.$converteraiStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}ai_status'],
        )!,
      ),
      mood: $DiaryEntriesTable.$convertermoodn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}mood'],
        ),
      ),
      visibility: $DiaryEntriesTable.$convertervisibility.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}visibility'],
        )!,
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      tags: $DiaryEntriesTable.$convertertags.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}tags'],
        )!,
      ),
      mediaUrls: $DiaryEntriesTable.$convertermediaUrls.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}media_urls'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncStatus: $DiaryEntriesTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
    );
  }

  @override
  $DiaryEntriesTable createAlias(String alias) {
    return $DiaryEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AiStatus, String, String> $converteraiStatus =
      const EnumNameConverter<AiStatus>(AiStatus.values);
  static JsonTypeConverter2<Mood, String, String> $convertermood =
      const EnumNameConverter<Mood>(Mood.values);
  static JsonTypeConverter2<Mood?, String?, String?> $convertermoodn =
      JsonTypeConverter2.asNullable($convertermood);
  static JsonTypeConverter2<EntryVisibility, String, String>
  $convertervisibility = const EnumNameConverter<EntryVisibility>(
    EntryVisibility.values,
  );
  static TypeConverter<List<String>, String> $convertertags =
      const StringListConverter();
  static TypeConverter<List<String>, String> $convertermediaUrls =
      const StringListConverter();
  static JsonTypeConverter2<SyncStatus, String, String> $convertersyncStatus =
      const EnumNameConverter<SyncStatus>(SyncStatus.values);
}

class DiaryEntryRow extends DataClass implements Insertable<DiaryEntryRow> {
  final String entryId;
  final String userId;
  final String? title;
  final String content;
  final String? aiSummary;
  final AiStatus aiStatus;
  final Mood? mood;
  final EntryVisibility visibility;
  final String? location;
  final List<String> tags;
  final List<String> mediaUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  const DiaryEntryRow({
    required this.entryId,
    required this.userId,
    this.title,
    required this.content,
    this.aiSummary,
    required this.aiStatus,
    this.mood,
    required this.visibility,
    this.location,
    required this.tags,
    required this.mediaUrls,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entry_id'] = Variable<String>(entryId);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || aiSummary != null) {
      map['ai_summary'] = Variable<String>(aiSummary);
    }
    {
      map['ai_status'] = Variable<String>(
        $DiaryEntriesTable.$converteraiStatus.toSql(aiStatus),
      );
    }
    if (!nullToAbsent || mood != null) {
      map['mood'] = Variable<String>(
        $DiaryEntriesTable.$convertermoodn.toSql(mood),
      );
    }
    {
      map['visibility'] = Variable<String>(
        $DiaryEntriesTable.$convertervisibility.toSql(visibility),
      );
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    {
      map['tags'] = Variable<String>(
        $DiaryEntriesTable.$convertertags.toSql(tags),
      );
    }
    {
      map['media_urls'] = Variable<String>(
        $DiaryEntriesTable.$convertermediaUrls.toSql(mediaUrls),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['sync_status'] = Variable<String>(
        $DiaryEntriesTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    return map;
  }

  DiaryEntriesCompanion toCompanion(bool nullToAbsent) {
    return DiaryEntriesCompanion(
      entryId: Value(entryId),
      userId: Value(userId),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      content: Value(content),
      aiSummary: aiSummary == null && nullToAbsent
          ? const Value.absent()
          : Value(aiSummary),
      aiStatus: Value(aiStatus),
      mood: mood == null && nullToAbsent ? const Value.absent() : Value(mood),
      visibility: Value(visibility),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      tags: Value(tags),
      mediaUrls: Value(mediaUrls),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory DiaryEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiaryEntryRow(
      entryId: serializer.fromJson<String>(json['entryId']),
      userId: serializer.fromJson<String>(json['userId']),
      title: serializer.fromJson<String?>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      aiSummary: serializer.fromJson<String?>(json['aiSummary']),
      aiStatus: $DiaryEntriesTable.$converteraiStatus.fromJson(
        serializer.fromJson<String>(json['aiStatus']),
      ),
      mood: $DiaryEntriesTable.$convertermoodn.fromJson(
        serializer.fromJson<String?>(json['mood']),
      ),
      visibility: $DiaryEntriesTable.$convertervisibility.fromJson(
        serializer.fromJson<String>(json['visibility']),
      ),
      location: serializer.fromJson<String?>(json['location']),
      tags: serializer.fromJson<List<String>>(json['tags']),
      mediaUrls: serializer.fromJson<List<String>>(json['mediaUrls']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncStatus: $DiaryEntriesTable.$convertersyncStatus.fromJson(
        serializer.fromJson<String>(json['syncStatus']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entryId': serializer.toJson<String>(entryId),
      'userId': serializer.toJson<String>(userId),
      'title': serializer.toJson<String?>(title),
      'content': serializer.toJson<String>(content),
      'aiSummary': serializer.toJson<String?>(aiSummary),
      'aiStatus': serializer.toJson<String>(
        $DiaryEntriesTable.$converteraiStatus.toJson(aiStatus),
      ),
      'mood': serializer.toJson<String?>(
        $DiaryEntriesTable.$convertermoodn.toJson(mood),
      ),
      'visibility': serializer.toJson<String>(
        $DiaryEntriesTable.$convertervisibility.toJson(visibility),
      ),
      'location': serializer.toJson<String?>(location),
      'tags': serializer.toJson<List<String>>(tags),
      'mediaUrls': serializer.toJson<List<String>>(mediaUrls),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncStatus': serializer.toJson<String>(
        $DiaryEntriesTable.$convertersyncStatus.toJson(syncStatus),
      ),
    };
  }

  DiaryEntryRow copyWith({
    String? entryId,
    String? userId,
    Value<String?> title = const Value.absent(),
    String? content,
    Value<String?> aiSummary = const Value.absent(),
    AiStatus? aiStatus,
    Value<Mood?> mood = const Value.absent(),
    EntryVisibility? visibility,
    Value<String?> location = const Value.absent(),
    List<String>? tags,
    List<String>? mediaUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
  }) => DiaryEntryRow(
    entryId: entryId ?? this.entryId,
    userId: userId ?? this.userId,
    title: title.present ? title.value : this.title,
    content: content ?? this.content,
    aiSummary: aiSummary.present ? aiSummary.value : this.aiSummary,
    aiStatus: aiStatus ?? this.aiStatus,
    mood: mood.present ? mood.value : this.mood,
    visibility: visibility ?? this.visibility,
    location: location.present ? location.value : this.location,
    tags: tags ?? this.tags,
    mediaUrls: mediaUrls ?? this.mediaUrls,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  DiaryEntryRow copyWithCompanion(DiaryEntriesCompanion data) {
    return DiaryEntryRow(
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      userId: data.userId.present ? data.userId.value : this.userId,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      aiSummary: data.aiSummary.present ? data.aiSummary.value : this.aiSummary,
      aiStatus: data.aiStatus.present ? data.aiStatus.value : this.aiStatus,
      mood: data.mood.present ? data.mood.value : this.mood,
      visibility: data.visibility.present
          ? data.visibility.value
          : this.visibility,
      location: data.location.present ? data.location.value : this.location,
      tags: data.tags.present ? data.tags.value : this.tags,
      mediaUrls: data.mediaUrls.present ? data.mediaUrls.value : this.mediaUrls,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiaryEntryRow(')
          ..write('entryId: $entryId, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('aiSummary: $aiSummary, ')
          ..write('aiStatus: $aiStatus, ')
          ..write('mood: $mood, ')
          ..write('visibility: $visibility, ')
          ..write('location: $location, ')
          ..write('tags: $tags, ')
          ..write('mediaUrls: $mediaUrls, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    entryId,
    userId,
    title,
    content,
    aiSummary,
    aiStatus,
    mood,
    visibility,
    location,
    tags,
    mediaUrls,
    createdAt,
    updatedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiaryEntryRow &&
          other.entryId == this.entryId &&
          other.userId == this.userId &&
          other.title == this.title &&
          other.content == this.content &&
          other.aiSummary == this.aiSummary &&
          other.aiStatus == this.aiStatus &&
          other.mood == this.mood &&
          other.visibility == this.visibility &&
          other.location == this.location &&
          other.tags == this.tags &&
          other.mediaUrls == this.mediaUrls &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus);
}

class DiaryEntriesCompanion extends UpdateCompanion<DiaryEntryRow> {
  final Value<String> entryId;
  final Value<String> userId;
  final Value<String?> title;
  final Value<String> content;
  final Value<String?> aiSummary;
  final Value<AiStatus> aiStatus;
  final Value<Mood?> mood;
  final Value<EntryVisibility> visibility;
  final Value<String?> location;
  final Value<List<String>> tags;
  final Value<List<String>> mediaUrls;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<SyncStatus> syncStatus;
  final Value<int> rowid;
  const DiaryEntriesCompanion({
    this.entryId = const Value.absent(),
    this.userId = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.aiSummary = const Value.absent(),
    this.aiStatus = const Value.absent(),
    this.mood = const Value.absent(),
    this.visibility = const Value.absent(),
    this.location = const Value.absent(),
    this.tags = const Value.absent(),
    this.mediaUrls = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DiaryEntriesCompanion.insert({
    required String entryId,
    required String userId,
    this.title = const Value.absent(),
    required String content,
    this.aiSummary = const Value.absent(),
    required AiStatus aiStatus,
    this.mood = const Value.absent(),
    required EntryVisibility visibility,
    this.location = const Value.absent(),
    required List<String> tags,
    required List<String> mediaUrls,
    required DateTime createdAt,
    required DateTime updatedAt,
    required SyncStatus syncStatus,
    this.rowid = const Value.absent(),
  }) : entryId = Value(entryId),
       userId = Value(userId),
       content = Value(content),
       aiStatus = Value(aiStatus),
       visibility = Value(visibility),
       tags = Value(tags),
       mediaUrls = Value(mediaUrls),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       syncStatus = Value(syncStatus);
  static Insertable<DiaryEntryRow> custom({
    Expression<String>? entryId,
    Expression<String>? userId,
    Expression<String>? title,
    Expression<String>? content,
    Expression<String>? aiSummary,
    Expression<String>? aiStatus,
    Expression<String>? mood,
    Expression<String>? visibility,
    Expression<String>? location,
    Expression<String>? tags,
    Expression<String>? mediaUrls,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entryId != null) 'entry_id': entryId,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (aiSummary != null) 'ai_summary': aiSummary,
      if (aiStatus != null) 'ai_status': aiStatus,
      if (mood != null) 'mood': mood,
      if (visibility != null) 'visibility': visibility,
      if (location != null) 'location': location,
      if (tags != null) 'tags': tags,
      if (mediaUrls != null) 'media_urls': mediaUrls,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DiaryEntriesCompanion copyWith({
    Value<String>? entryId,
    Value<String>? userId,
    Value<String?>? title,
    Value<String>? content,
    Value<String?>? aiSummary,
    Value<AiStatus>? aiStatus,
    Value<Mood?>? mood,
    Value<EntryVisibility>? visibility,
    Value<String?>? location,
    Value<List<String>>? tags,
    Value<List<String>>? mediaUrls,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<SyncStatus>? syncStatus,
    Value<int>? rowid,
  }) {
    return DiaryEntriesCompanion(
      entryId: entryId ?? this.entryId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      aiSummary: aiSummary ?? this.aiSummary,
      aiStatus: aiStatus ?? this.aiStatus,
      mood: mood ?? this.mood,
      visibility: visibility ?? this.visibility,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (aiSummary.present) {
      map['ai_summary'] = Variable<String>(aiSummary.value);
    }
    if (aiStatus.present) {
      map['ai_status'] = Variable<String>(
        $DiaryEntriesTable.$converteraiStatus.toSql(aiStatus.value),
      );
    }
    if (mood.present) {
      map['mood'] = Variable<String>(
        $DiaryEntriesTable.$convertermoodn.toSql(mood.value),
      );
    }
    if (visibility.present) {
      map['visibility'] = Variable<String>(
        $DiaryEntriesTable.$convertervisibility.toSql(visibility.value),
      );
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(
        $DiaryEntriesTable.$convertertags.toSql(tags.value),
      );
    }
    if (mediaUrls.present) {
      map['media_urls'] = Variable<String>(
        $DiaryEntriesTable.$convertermediaUrls.toSql(mediaUrls.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
        $DiaryEntriesTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiaryEntriesCompanion(')
          ..write('entryId: $entryId, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('aiSummary: $aiSummary, ')
          ..write('aiStatus: $aiStatus, ')
          ..write('mood: $mood, ')
          ..write('visibility: $visibility, ')
          ..write('location: $location, ')
          ..write('tags: $tags, ')
          ..write('mediaUrls: $mediaUrls, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DiaryEntriesTable diaryEntries = $DiaryEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [diaryEntries];
}

typedef $$DiaryEntriesTableCreateCompanionBuilder =
    DiaryEntriesCompanion Function({
      required String entryId,
      required String userId,
      Value<String?> title,
      required String content,
      Value<String?> aiSummary,
      required AiStatus aiStatus,
      Value<Mood?> mood,
      required EntryVisibility visibility,
      Value<String?> location,
      required List<String> tags,
      required List<String> mediaUrls,
      required DateTime createdAt,
      required DateTime updatedAt,
      required SyncStatus syncStatus,
      Value<int> rowid,
    });
typedef $$DiaryEntriesTableUpdateCompanionBuilder =
    DiaryEntriesCompanion Function({
      Value<String> entryId,
      Value<String> userId,
      Value<String?> title,
      Value<String> content,
      Value<String?> aiSummary,
      Value<AiStatus> aiStatus,
      Value<Mood?> mood,
      Value<EntryVisibility> visibility,
      Value<String?> location,
      Value<List<String>> tags,
      Value<List<String>> mediaUrls,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<SyncStatus> syncStatus,
      Value<int> rowid,
    });

class $$DiaryEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DiaryEntriesTable> {
  $$DiaryEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aiSummary => $composableBuilder(
    column: $table.aiSummary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AiStatus, AiStatus, String> get aiStatus =>
      $composableBuilder(
        column: $table.aiStatus,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Mood?, Mood, String> get mood =>
      $composableBuilder(
        column: $table.mood,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<EntryVisibility, EntryVisibility, String>
  get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String> get tags =>
      $composableBuilder(
        column: $table.tags,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get mediaUrls => $composableBuilder(
    column: $table.mediaUrls,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, String>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$DiaryEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DiaryEntriesTable> {
  $$DiaryEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aiSummary => $composableBuilder(
    column: $table.aiSummary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aiStatus => $composableBuilder(
    column: $table.aiStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaUrls => $composableBuilder(
    column: $table.mediaUrls,
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

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DiaryEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiaryEntriesTable> {
  $$DiaryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get aiSummary =>
      $composableBuilder(column: $table.aiSummary, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AiStatus, String> get aiStatus =>
      $composableBuilder(column: $table.aiStatus, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Mood?, String> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumnWithTypeConverter<EntryVisibility, String> get visibility =>
      $composableBuilder(
        column: $table.visibility,
        builder: (column) => column,
      );

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get mediaUrls =>
      $composableBuilder(column: $table.mediaUrls, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatus, String> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );
}

class $$DiaryEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DiaryEntriesTable,
          DiaryEntryRow,
          $$DiaryEntriesTableFilterComposer,
          $$DiaryEntriesTableOrderingComposer,
          $$DiaryEntriesTableAnnotationComposer,
          $$DiaryEntriesTableCreateCompanionBuilder,
          $$DiaryEntriesTableUpdateCompanionBuilder,
          (
            DiaryEntryRow,
            BaseReferences<_$AppDatabase, $DiaryEntriesTable, DiaryEntryRow>,
          ),
          DiaryEntryRow,
          PrefetchHooks Function()
        > {
  $$DiaryEntriesTableTableManager(_$AppDatabase db, $DiaryEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiaryEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiaryEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiaryEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entryId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> aiSummary = const Value.absent(),
                Value<AiStatus> aiStatus = const Value.absent(),
                Value<Mood?> mood = const Value.absent(),
                Value<EntryVisibility> visibility = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<List<String>> tags = const Value.absent(),
                Value<List<String>> mediaUrls = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiaryEntriesCompanion(
                entryId: entryId,
                userId: userId,
                title: title,
                content: content,
                aiSummary: aiSummary,
                aiStatus: aiStatus,
                mood: mood,
                visibility: visibility,
                location: location,
                tags: tags,
                mediaUrls: mediaUrls,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entryId,
                required String userId,
                Value<String?> title = const Value.absent(),
                required String content,
                Value<String?> aiSummary = const Value.absent(),
                required AiStatus aiStatus,
                Value<Mood?> mood = const Value.absent(),
                required EntryVisibility visibility,
                Value<String?> location = const Value.absent(),
                required List<String> tags,
                required List<String> mediaUrls,
                required DateTime createdAt,
                required DateTime updatedAt,
                required SyncStatus syncStatus,
                Value<int> rowid = const Value.absent(),
              }) => DiaryEntriesCompanion.insert(
                entryId: entryId,
                userId: userId,
                title: title,
                content: content,
                aiSummary: aiSummary,
                aiStatus: aiStatus,
                mood: mood,
                visibility: visibility,
                location: location,
                tags: tags,
                mediaUrls: mediaUrls,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DiaryEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DiaryEntriesTable,
      DiaryEntryRow,
      $$DiaryEntriesTableFilterComposer,
      $$DiaryEntriesTableOrderingComposer,
      $$DiaryEntriesTableAnnotationComposer,
      $$DiaryEntriesTableCreateCompanionBuilder,
      $$DiaryEntriesTableUpdateCompanionBuilder,
      (
        DiaryEntryRow,
        BaseReferences<_$AppDatabase, $DiaryEntriesTable, DiaryEntryRow>,
      ),
      DiaryEntryRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DiaryEntriesTableTableManager get diaryEntries =>
      $$DiaryEntriesTableTableManager(_db, _db.diaryEntries);
}
