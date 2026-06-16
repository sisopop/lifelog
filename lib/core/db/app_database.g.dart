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
  static const VerificationMeta _journalIdMeta = const VerificationMeta(
    'journalId',
  );
  @override
  late final GeneratedColumn<String> journalId = GeneratedColumn<String>(
    'journal_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('jr_default'),
  );
  static const VerificationMeta _replyToEntryIdMeta = const VerificationMeta(
    'replyToEntryId',
  );
  @override
  late final GeneratedColumn<String> replyToEntryId = GeneratedColumn<String>(
    'reply_to_entry_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _langMeta = const VerificationMeta('lang');
  @override
  late final GeneratedColumn<String> lang = GeneratedColumn<String>(
    'lang',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ko'),
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
    journalId,
    replyToEntryId,
    lang,
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
    if (data.containsKey('journal_id')) {
      context.handle(
        _journalIdMeta,
        journalId.isAcceptableOrUnknown(data['journal_id']!, _journalIdMeta),
      );
    }
    if (data.containsKey('reply_to_entry_id')) {
      context.handle(
        _replyToEntryIdMeta,
        replyToEntryId.isAcceptableOrUnknown(
          data['reply_to_entry_id']!,
          _replyToEntryIdMeta,
        ),
      );
    }
    if (data.containsKey('lang')) {
      context.handle(
        _langMeta,
        lang.isAcceptableOrUnknown(data['lang']!, _langMeta),
      );
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
      journalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}journal_id'],
      )!,
      replyToEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reply_to_entry_id'],
      ),
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
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
  final String journalId;
  final String? replyToEntryId;
  final String lang;
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
    required this.journalId,
    this.replyToEntryId,
    required this.lang,
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
    map['journal_id'] = Variable<String>(journalId);
    if (!nullToAbsent || replyToEntryId != null) {
      map['reply_to_entry_id'] = Variable<String>(replyToEntryId);
    }
    map['lang'] = Variable<String>(lang);
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
      journalId: Value(journalId),
      replyToEntryId: replyToEntryId == null && nullToAbsent
          ? const Value.absent()
          : Value(replyToEntryId),
      lang: Value(lang),
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
      journalId: serializer.fromJson<String>(json['journalId']),
      replyToEntryId: serializer.fromJson<String?>(json['replyToEntryId']),
      lang: serializer.fromJson<String>(json['lang']),
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
      'journalId': serializer.toJson<String>(journalId),
      'replyToEntryId': serializer.toJson<String?>(replyToEntryId),
      'lang': serializer.toJson<String>(lang),
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
    String? journalId,
    Value<String?> replyToEntryId = const Value.absent(),
    String? lang,
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
    journalId: journalId ?? this.journalId,
    replyToEntryId: replyToEntryId.present
        ? replyToEntryId.value
        : this.replyToEntryId,
    lang: lang ?? this.lang,
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
      journalId: data.journalId.present ? data.journalId.value : this.journalId,
      replyToEntryId: data.replyToEntryId.present
          ? data.replyToEntryId.value
          : this.replyToEntryId,
      lang: data.lang.present ? data.lang.value : this.lang,
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
          ..write('journalId: $journalId, ')
          ..write('replyToEntryId: $replyToEntryId, ')
          ..write('lang: $lang, ')
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
    journalId,
    replyToEntryId,
    lang,
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
          other.journalId == this.journalId &&
          other.replyToEntryId == this.replyToEntryId &&
          other.lang == this.lang &&
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
  final Value<String> journalId;
  final Value<String?> replyToEntryId;
  final Value<String> lang;
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
    this.journalId = const Value.absent(),
    this.replyToEntryId = const Value.absent(),
    this.lang = const Value.absent(),
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
    this.journalId = const Value.absent(),
    this.replyToEntryId = const Value.absent(),
    this.lang = const Value.absent(),
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
    Expression<String>? journalId,
    Expression<String>? replyToEntryId,
    Expression<String>? lang,
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
      if (journalId != null) 'journal_id': journalId,
      if (replyToEntryId != null) 'reply_to_entry_id': replyToEntryId,
      if (lang != null) 'lang': lang,
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
    Value<String>? journalId,
    Value<String?>? replyToEntryId,
    Value<String>? lang,
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
      journalId: journalId ?? this.journalId,
      replyToEntryId: replyToEntryId ?? this.replyToEntryId,
      lang: lang ?? this.lang,
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
    if (journalId.present) {
      map['journal_id'] = Variable<String>(journalId.value);
    }
    if (replyToEntryId.present) {
      map['reply_to_entry_id'] = Variable<String>(replyToEntryId.value);
    }
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
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
          ..write('journalId: $journalId, ')
          ..write('replyToEntryId: $replyToEntryId, ')
          ..write('lang: $lang, ')
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

class $JournalsTable extends Journals
    with TableInfo<$JournalsTable, JournalRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _journalIdMeta = const VerificationMeta(
    'journalId',
  );
  @override
  late final GeneratedColumn<String> journalId = GeneratedColumn<String>(
    'journal_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<JournalType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<JournalType>($JournalsTable.$convertertype);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverColorMeta = const VerificationMeta(
    'coverColor',
  );
  @override
  late final GeneratedColumn<int> coverColor = GeneratedColumn<int>(
    'cover_color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0xFF7C6FF0),
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<JournalStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<JournalStatus>($JournalsTable.$converterstatus);
  static const VerificationMeta _spaceIdMeta = const VerificationMeta(
    'spaceId',
  );
  @override
  late final GeneratedColumn<String> spaceId = GeneratedColumn<String>(
    'space_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    journalId,
    ownerId,
    type,
    title,
    coverColor,
    icon,
    status,
    spaceId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journals';
  @override
  VerificationContext validateIntegrity(
    Insertable<JournalRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('journal_id')) {
      context.handle(
        _journalIdMeta,
        journalId.isAcceptableOrUnknown(data['journal_id']!, _journalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_journalIdMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('cover_color')) {
      context.handle(
        _coverColorMeta,
        coverColor.isAcceptableOrUnknown(data['cover_color']!, _coverColorMeta),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('space_id')) {
      context.handle(
        _spaceIdMeta,
        spaceId.isAcceptableOrUnknown(data['space_id']!, _spaceIdMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {journalId};
  @override
  JournalRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalRow(
      journalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}journal_id'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      type: $JournalsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      coverColor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cover_color'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      status: $JournalsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      spaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}space_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $JournalsTable createAlias(String alias) {
    return $JournalsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<JournalType, String, String> $convertertype =
      const EnumNameConverter<JournalType>(JournalType.values);
  static JsonTypeConverter2<JournalStatus, String, String> $converterstatus =
      const EnumNameConverter<JournalStatus>(JournalStatus.values);
}

class JournalRow extends DataClass implements Insertable<JournalRow> {
  final String journalId;
  final String ownerId;
  final JournalType type;
  final String title;
  final int coverColor;
  final String? icon;
  final JournalStatus status;
  final String? spaceId;
  final DateTime createdAt;
  const JournalRow({
    required this.journalId,
    required this.ownerId,
    required this.type,
    required this.title,
    required this.coverColor,
    this.icon,
    required this.status,
    this.spaceId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['journal_id'] = Variable<String>(journalId);
    map['owner_id'] = Variable<String>(ownerId);
    {
      map['type'] = Variable<String>($JournalsTable.$convertertype.toSql(type));
    }
    map['title'] = Variable<String>(title);
    map['cover_color'] = Variable<int>(coverColor);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    {
      map['status'] = Variable<String>(
        $JournalsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || spaceId != null) {
      map['space_id'] = Variable<String>(spaceId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  JournalsCompanion toCompanion(bool nullToAbsent) {
    return JournalsCompanion(
      journalId: Value(journalId),
      ownerId: Value(ownerId),
      type: Value(type),
      title: Value(title),
      coverColor: Value(coverColor),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      status: Value(status),
      spaceId: spaceId == null && nullToAbsent
          ? const Value.absent()
          : Value(spaceId),
      createdAt: Value(createdAt),
    );
  }

  factory JournalRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JournalRow(
      journalId: serializer.fromJson<String>(json['journalId']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      type: $JournalsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      title: serializer.fromJson<String>(json['title']),
      coverColor: serializer.fromJson<int>(json['coverColor']),
      icon: serializer.fromJson<String?>(json['icon']),
      status: $JournalsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      spaceId: serializer.fromJson<String?>(json['spaceId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'journalId': serializer.toJson<String>(journalId),
      'ownerId': serializer.toJson<String>(ownerId),
      'type': serializer.toJson<String>(
        $JournalsTable.$convertertype.toJson(type),
      ),
      'title': serializer.toJson<String>(title),
      'coverColor': serializer.toJson<int>(coverColor),
      'icon': serializer.toJson<String?>(icon),
      'status': serializer.toJson<String>(
        $JournalsTable.$converterstatus.toJson(status),
      ),
      'spaceId': serializer.toJson<String?>(spaceId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  JournalRow copyWith({
    String? journalId,
    String? ownerId,
    JournalType? type,
    String? title,
    int? coverColor,
    Value<String?> icon = const Value.absent(),
    JournalStatus? status,
    Value<String?> spaceId = const Value.absent(),
    DateTime? createdAt,
  }) => JournalRow(
    journalId: journalId ?? this.journalId,
    ownerId: ownerId ?? this.ownerId,
    type: type ?? this.type,
    title: title ?? this.title,
    coverColor: coverColor ?? this.coverColor,
    icon: icon.present ? icon.value : this.icon,
    status: status ?? this.status,
    spaceId: spaceId.present ? spaceId.value : this.spaceId,
    createdAt: createdAt ?? this.createdAt,
  );
  JournalRow copyWithCompanion(JournalsCompanion data) {
    return JournalRow(
      journalId: data.journalId.present ? data.journalId.value : this.journalId,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      coverColor: data.coverColor.present
          ? data.coverColor.value
          : this.coverColor,
      icon: data.icon.present ? data.icon.value : this.icon,
      status: data.status.present ? data.status.value : this.status,
      spaceId: data.spaceId.present ? data.spaceId.value : this.spaceId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JournalRow(')
          ..write('journalId: $journalId, ')
          ..write('ownerId: $ownerId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('coverColor: $coverColor, ')
          ..write('icon: $icon, ')
          ..write('status: $status, ')
          ..write('spaceId: $spaceId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    journalId,
    ownerId,
    type,
    title,
    coverColor,
    icon,
    status,
    spaceId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JournalRow &&
          other.journalId == this.journalId &&
          other.ownerId == this.ownerId &&
          other.type == this.type &&
          other.title == this.title &&
          other.coverColor == this.coverColor &&
          other.icon == this.icon &&
          other.status == this.status &&
          other.spaceId == this.spaceId &&
          other.createdAt == this.createdAt);
}

class JournalsCompanion extends UpdateCompanion<JournalRow> {
  final Value<String> journalId;
  final Value<String> ownerId;
  final Value<JournalType> type;
  final Value<String> title;
  final Value<int> coverColor;
  final Value<String?> icon;
  final Value<JournalStatus> status;
  final Value<String?> spaceId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const JournalsCompanion({
    this.journalId = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.coverColor = const Value.absent(),
    this.icon = const Value.absent(),
    this.status = const Value.absent(),
    this.spaceId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JournalsCompanion.insert({
    required String journalId,
    required String ownerId,
    required JournalType type,
    required String title,
    this.coverColor = const Value.absent(),
    this.icon = const Value.absent(),
    required JournalStatus status,
    this.spaceId = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : journalId = Value(journalId),
       ownerId = Value(ownerId),
       type = Value(type),
       title = Value(title),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<JournalRow> custom({
    Expression<String>? journalId,
    Expression<String>? ownerId,
    Expression<String>? type,
    Expression<String>? title,
    Expression<int>? coverColor,
    Expression<String>? icon,
    Expression<String>? status,
    Expression<String>? spaceId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (journalId != null) 'journal_id': journalId,
      if (ownerId != null) 'owner_id': ownerId,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (coverColor != null) 'cover_color': coverColor,
      if (icon != null) 'icon': icon,
      if (status != null) 'status': status,
      if (spaceId != null) 'space_id': spaceId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JournalsCompanion copyWith({
    Value<String>? journalId,
    Value<String>? ownerId,
    Value<JournalType>? type,
    Value<String>? title,
    Value<int>? coverColor,
    Value<String?>? icon,
    Value<JournalStatus>? status,
    Value<String?>? spaceId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return JournalsCompanion(
      journalId: journalId ?? this.journalId,
      ownerId: ownerId ?? this.ownerId,
      type: type ?? this.type,
      title: title ?? this.title,
      coverColor: coverColor ?? this.coverColor,
      icon: icon ?? this.icon,
      status: status ?? this.status,
      spaceId: spaceId ?? this.spaceId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (journalId.present) {
      map['journal_id'] = Variable<String>(journalId.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $JournalsTable.$convertertype.toSql(type.value),
      );
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (coverColor.present) {
      map['cover_color'] = Variable<int>(coverColor.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $JournalsTable.$converterstatus.toSql(status.value),
      );
    }
    if (spaceId.present) {
      map['space_id'] = Variable<String>(spaceId.value);
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
    return (StringBuffer('JournalsCompanion(')
          ..write('journalId: $journalId, ')
          ..write('ownerId: $ownerId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('coverColor: $coverColor, ')
          ..write('icon: $icon, ')
          ..write('status: $status, ')
          ..write('spaceId: $spaceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JournalMembersTable extends JournalMembers
    with TableInfo<$JournalMembersTable, JournalMemberRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _journalIdMeta = const VerificationMeta(
    'journalId',
  );
  @override
  late final GeneratedColumn<String> journalId = GeneratedColumn<String>(
    'journal_id',
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
  @override
  late final GeneratedColumnWithTypeConverter<MemberRole, String> role =
      GeneratedColumn<String>(
        'role',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MemberRole>($JournalMembersTable.$converterrole);
  static const VerificationMeta _isMeMeta = const VerificationMeta('isMe');
  @override
  late final GeneratedColumn<bool> isMe = GeneratedColumn<bool>(
    'is_me',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_me" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _joinedAtMeta = const VerificationMeta(
    'joinedAt',
  );
  @override
  late final GeneratedColumn<DateTime> joinedAt = GeneratedColumn<DateTime>(
    'joined_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    memberId,
    journalId,
    userId,
    displayName,
    role,
    isMe,
    joinedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journal_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<JournalMemberRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('journal_id')) {
      context.handle(
        _journalIdMeta,
        journalId.isAcceptableOrUnknown(data['journal_id']!, _journalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_journalIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
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
    if (data.containsKey('is_me')) {
      context.handle(
        _isMeMeta,
        isMe.isAcceptableOrUnknown(data['is_me']!, _isMeMeta),
      );
    }
    if (data.containsKey('joined_at')) {
      context.handle(
        _joinedAtMeta,
        joinedAt.isAcceptableOrUnknown(data['joined_at']!, _joinedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_joinedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {memberId};
  @override
  JournalMemberRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalMemberRow(
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      journalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}journal_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      role: $JournalMembersTable.$converterrole.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}role'],
        )!,
      ),
      isMe: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_me'],
      )!,
      joinedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}joined_at'],
      )!,
    );
  }

  @override
  $JournalMembersTable createAlias(String alias) {
    return $JournalMembersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MemberRole, String, String> $converterrole =
      const EnumNameConverter<MemberRole>(MemberRole.values);
}

class JournalMemberRow extends DataClass
    implements Insertable<JournalMemberRow> {
  final String memberId;
  final String journalId;
  final String userId;
  final String displayName;
  final MemberRole role;
  final bool isMe;
  final DateTime joinedAt;
  const JournalMemberRow({
    required this.memberId,
    required this.journalId,
    required this.userId,
    required this.displayName,
    required this.role,
    required this.isMe,
    required this.joinedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['member_id'] = Variable<String>(memberId);
    map['journal_id'] = Variable<String>(journalId);
    map['user_id'] = Variable<String>(userId);
    map['display_name'] = Variable<String>(displayName);
    {
      map['role'] = Variable<String>(
        $JournalMembersTable.$converterrole.toSql(role),
      );
    }
    map['is_me'] = Variable<bool>(isMe);
    map['joined_at'] = Variable<DateTime>(joinedAt);
    return map;
  }

  JournalMembersCompanion toCompanion(bool nullToAbsent) {
    return JournalMembersCompanion(
      memberId: Value(memberId),
      journalId: Value(journalId),
      userId: Value(userId),
      displayName: Value(displayName),
      role: Value(role),
      isMe: Value(isMe),
      joinedAt: Value(joinedAt),
    );
  }

  factory JournalMemberRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JournalMemberRow(
      memberId: serializer.fromJson<String>(json['memberId']),
      journalId: serializer.fromJson<String>(json['journalId']),
      userId: serializer.fromJson<String>(json['userId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      role: $JournalMembersTable.$converterrole.fromJson(
        serializer.fromJson<String>(json['role']),
      ),
      isMe: serializer.fromJson<bool>(json['isMe']),
      joinedAt: serializer.fromJson<DateTime>(json['joinedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'memberId': serializer.toJson<String>(memberId),
      'journalId': serializer.toJson<String>(journalId),
      'userId': serializer.toJson<String>(userId),
      'displayName': serializer.toJson<String>(displayName),
      'role': serializer.toJson<String>(
        $JournalMembersTable.$converterrole.toJson(role),
      ),
      'isMe': serializer.toJson<bool>(isMe),
      'joinedAt': serializer.toJson<DateTime>(joinedAt),
    };
  }

  JournalMemberRow copyWith({
    String? memberId,
    String? journalId,
    String? userId,
    String? displayName,
    MemberRole? role,
    bool? isMe,
    DateTime? joinedAt,
  }) => JournalMemberRow(
    memberId: memberId ?? this.memberId,
    journalId: journalId ?? this.journalId,
    userId: userId ?? this.userId,
    displayName: displayName ?? this.displayName,
    role: role ?? this.role,
    isMe: isMe ?? this.isMe,
    joinedAt: joinedAt ?? this.joinedAt,
  );
  JournalMemberRow copyWithCompanion(JournalMembersCompanion data) {
    return JournalMemberRow(
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      journalId: data.journalId.present ? data.journalId.value : this.journalId,
      userId: data.userId.present ? data.userId.value : this.userId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      role: data.role.present ? data.role.value : this.role,
      isMe: data.isMe.present ? data.isMe.value : this.isMe,
      joinedAt: data.joinedAt.present ? data.joinedAt.value : this.joinedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JournalMemberRow(')
          ..write('memberId: $memberId, ')
          ..write('journalId: $journalId, ')
          ..write('userId: $userId, ')
          ..write('displayName: $displayName, ')
          ..write('role: $role, ')
          ..write('isMe: $isMe, ')
          ..write('joinedAt: $joinedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    memberId,
    journalId,
    userId,
    displayName,
    role,
    isMe,
    joinedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JournalMemberRow &&
          other.memberId == this.memberId &&
          other.journalId == this.journalId &&
          other.userId == this.userId &&
          other.displayName == this.displayName &&
          other.role == this.role &&
          other.isMe == this.isMe &&
          other.joinedAt == this.joinedAt);
}

class JournalMembersCompanion extends UpdateCompanion<JournalMemberRow> {
  final Value<String> memberId;
  final Value<String> journalId;
  final Value<String> userId;
  final Value<String> displayName;
  final Value<MemberRole> role;
  final Value<bool> isMe;
  final Value<DateTime> joinedAt;
  final Value<int> rowid;
  const JournalMembersCompanion({
    this.memberId = const Value.absent(),
    this.journalId = const Value.absent(),
    this.userId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.role = const Value.absent(),
    this.isMe = const Value.absent(),
    this.joinedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JournalMembersCompanion.insert({
    required String memberId,
    required String journalId,
    required String userId,
    required String displayName,
    required MemberRole role,
    this.isMe = const Value.absent(),
    required DateTime joinedAt,
    this.rowid = const Value.absent(),
  }) : memberId = Value(memberId),
       journalId = Value(journalId),
       userId = Value(userId),
       displayName = Value(displayName),
       role = Value(role),
       joinedAt = Value(joinedAt);
  static Insertable<JournalMemberRow> custom({
    Expression<String>? memberId,
    Expression<String>? journalId,
    Expression<String>? userId,
    Expression<String>? displayName,
    Expression<String>? role,
    Expression<bool>? isMe,
    Expression<DateTime>? joinedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (memberId != null) 'member_id': memberId,
      if (journalId != null) 'journal_id': journalId,
      if (userId != null) 'user_id': userId,
      if (displayName != null) 'display_name': displayName,
      if (role != null) 'role': role,
      if (isMe != null) 'is_me': isMe,
      if (joinedAt != null) 'joined_at': joinedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JournalMembersCompanion copyWith({
    Value<String>? memberId,
    Value<String>? journalId,
    Value<String>? userId,
    Value<String>? displayName,
    Value<MemberRole>? role,
    Value<bool>? isMe,
    Value<DateTime>? joinedAt,
    Value<int>? rowid,
  }) {
    return JournalMembersCompanion(
      memberId: memberId ?? this.memberId,
      journalId: journalId ?? this.journalId,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      isMe: isMe ?? this.isMe,
      joinedAt: joinedAt ?? this.joinedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (journalId.present) {
      map['journal_id'] = Variable<String>(journalId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(
        $JournalMembersTable.$converterrole.toSql(role.value),
      );
    }
    if (isMe.present) {
      map['is_me'] = Variable<bool>(isMe.value);
    }
    if (joinedAt.present) {
      map['joined_at'] = Variable<DateTime>(joinedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalMembersCompanion(')
          ..write('memberId: $memberId, ')
          ..write('journalId: $journalId, ')
          ..write('userId: $userId, ')
          ..write('displayName: $displayName, ')
          ..write('role: $role, ')
          ..write('isMe: $isMe, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DiaryEntriesTable diaryEntries = $DiaryEntriesTable(this);
  late final $JournalsTable journals = $JournalsTable(this);
  late final $JournalMembersTable journalMembers = $JournalMembersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    diaryEntries,
    journals,
    journalMembers,
  ];
}

typedef $$DiaryEntriesTableCreateCompanionBuilder =
    DiaryEntriesCompanion Function({
      required String entryId,
      required String userId,
      Value<String> journalId,
      Value<String?> replyToEntryId,
      Value<String> lang,
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
      Value<String> journalId,
      Value<String?> replyToEntryId,
      Value<String> lang,
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

  ColumnFilters<String> get journalId => $composableBuilder(
    column: $table.journalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replyToEntryId => $composableBuilder(
    column: $table.replyToEntryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lang => $composableBuilder(
    column: $table.lang,
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

  ColumnOrderings<String> get journalId => $composableBuilder(
    column: $table.journalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replyToEntryId => $composableBuilder(
    column: $table.replyToEntryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lang => $composableBuilder(
    column: $table.lang,
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

  GeneratedColumn<String> get journalId =>
      $composableBuilder(column: $table.journalId, builder: (column) => column);

  GeneratedColumn<String> get replyToEntryId => $composableBuilder(
    column: $table.replyToEntryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lang =>
      $composableBuilder(column: $table.lang, builder: (column) => column);

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
                Value<String> journalId = const Value.absent(),
                Value<String?> replyToEntryId = const Value.absent(),
                Value<String> lang = const Value.absent(),
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
                journalId: journalId,
                replyToEntryId: replyToEntryId,
                lang: lang,
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
                Value<String> journalId = const Value.absent(),
                Value<String?> replyToEntryId = const Value.absent(),
                Value<String> lang = const Value.absent(),
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
                journalId: journalId,
                replyToEntryId: replyToEntryId,
                lang: lang,
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
typedef $$JournalsTableCreateCompanionBuilder =
    JournalsCompanion Function({
      required String journalId,
      required String ownerId,
      required JournalType type,
      required String title,
      Value<int> coverColor,
      Value<String?> icon,
      required JournalStatus status,
      Value<String?> spaceId,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$JournalsTableUpdateCompanionBuilder =
    JournalsCompanion Function({
      Value<String> journalId,
      Value<String> ownerId,
      Value<JournalType> type,
      Value<String> title,
      Value<int> coverColor,
      Value<String?> icon,
      Value<JournalStatus> status,
      Value<String?> spaceId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$JournalsTableFilterComposer
    extends Composer<_$AppDatabase, $JournalsTable> {
  $$JournalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get journalId => $composableBuilder(
    column: $table.journalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<JournalType, JournalType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get coverColor => $composableBuilder(
    column: $table.coverColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<JournalStatus, JournalStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get spaceId => $composableBuilder(
    column: $table.spaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JournalsTableOrderingComposer
    extends Composer<_$AppDatabase, $JournalsTable> {
  $$JournalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get journalId => $composableBuilder(
    column: $table.journalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get coverColor => $composableBuilder(
    column: $table.coverColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get spaceId => $composableBuilder(
    column: $table.spaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JournalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $JournalsTable> {
  $$JournalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get journalId =>
      $composableBuilder(column: $table.journalId, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<JournalType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get coverColor => $composableBuilder(
    column: $table.coverColor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumnWithTypeConverter<JournalStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get spaceId =>
      $composableBuilder(column: $table.spaceId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$JournalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JournalsTable,
          JournalRow,
          $$JournalsTableFilterComposer,
          $$JournalsTableOrderingComposer,
          $$JournalsTableAnnotationComposer,
          $$JournalsTableCreateCompanionBuilder,
          $$JournalsTableUpdateCompanionBuilder,
          (
            JournalRow,
            BaseReferences<_$AppDatabase, $JournalsTable, JournalRow>,
          ),
          JournalRow,
          PrefetchHooks Function()
        > {
  $$JournalsTableTableManager(_$AppDatabase db, $JournalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JournalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JournalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JournalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> journalId = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<JournalType> type = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> coverColor = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<JournalStatus> status = const Value.absent(),
                Value<String?> spaceId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JournalsCompanion(
                journalId: journalId,
                ownerId: ownerId,
                type: type,
                title: title,
                coverColor: coverColor,
                icon: icon,
                status: status,
                spaceId: spaceId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String journalId,
                required String ownerId,
                required JournalType type,
                required String title,
                Value<int> coverColor = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                required JournalStatus status,
                Value<String?> spaceId = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => JournalsCompanion.insert(
                journalId: journalId,
                ownerId: ownerId,
                type: type,
                title: title,
                coverColor: coverColor,
                icon: icon,
                status: status,
                spaceId: spaceId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JournalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JournalsTable,
      JournalRow,
      $$JournalsTableFilterComposer,
      $$JournalsTableOrderingComposer,
      $$JournalsTableAnnotationComposer,
      $$JournalsTableCreateCompanionBuilder,
      $$JournalsTableUpdateCompanionBuilder,
      (JournalRow, BaseReferences<_$AppDatabase, $JournalsTable, JournalRow>),
      JournalRow,
      PrefetchHooks Function()
    >;
typedef $$JournalMembersTableCreateCompanionBuilder =
    JournalMembersCompanion Function({
      required String memberId,
      required String journalId,
      required String userId,
      required String displayName,
      required MemberRole role,
      Value<bool> isMe,
      required DateTime joinedAt,
      Value<int> rowid,
    });
typedef $$JournalMembersTableUpdateCompanionBuilder =
    JournalMembersCompanion Function({
      Value<String> memberId,
      Value<String> journalId,
      Value<String> userId,
      Value<String> displayName,
      Value<MemberRole> role,
      Value<bool> isMe,
      Value<DateTime> joinedAt,
      Value<int> rowid,
    });

class $$JournalMembersTableFilterComposer
    extends Composer<_$AppDatabase, $JournalMembersTable> {
  $$JournalMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get journalId => $composableBuilder(
    column: $table.journalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MemberRole, MemberRole, String> get role =>
      $composableBuilder(
        column: $table.role,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get isMe => $composableBuilder(
    column: $table.isMe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JournalMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $JournalMembersTable> {
  $$JournalMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get journalId => $composableBuilder(
    column: $table.journalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMe => $composableBuilder(
    column: $table.isMe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JournalMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $JournalMembersTable> {
  $$JournalMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);

  GeneratedColumn<String> get journalId =>
      $composableBuilder(column: $table.journalId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<MemberRole, String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<bool> get isMe =>
      $composableBuilder(column: $table.isMe, builder: (column) => column);

  GeneratedColumn<DateTime> get joinedAt =>
      $composableBuilder(column: $table.joinedAt, builder: (column) => column);
}

class $$JournalMembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JournalMembersTable,
          JournalMemberRow,
          $$JournalMembersTableFilterComposer,
          $$JournalMembersTableOrderingComposer,
          $$JournalMembersTableAnnotationComposer,
          $$JournalMembersTableCreateCompanionBuilder,
          $$JournalMembersTableUpdateCompanionBuilder,
          (
            JournalMemberRow,
            BaseReferences<
              _$AppDatabase,
              $JournalMembersTable,
              JournalMemberRow
            >,
          ),
          JournalMemberRow,
          PrefetchHooks Function()
        > {
  $$JournalMembersTableTableManager(
    _$AppDatabase db,
    $JournalMembersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JournalMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JournalMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JournalMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> memberId = const Value.absent(),
                Value<String> journalId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<MemberRole> role = const Value.absent(),
                Value<bool> isMe = const Value.absent(),
                Value<DateTime> joinedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JournalMembersCompanion(
                memberId: memberId,
                journalId: journalId,
                userId: userId,
                displayName: displayName,
                role: role,
                isMe: isMe,
                joinedAt: joinedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String memberId,
                required String journalId,
                required String userId,
                required String displayName,
                required MemberRole role,
                Value<bool> isMe = const Value.absent(),
                required DateTime joinedAt,
                Value<int> rowid = const Value.absent(),
              }) => JournalMembersCompanion.insert(
                memberId: memberId,
                journalId: journalId,
                userId: userId,
                displayName: displayName,
                role: role,
                isMe: isMe,
                joinedAt: joinedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JournalMembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JournalMembersTable,
      JournalMemberRow,
      $$JournalMembersTableFilterComposer,
      $$JournalMembersTableOrderingComposer,
      $$JournalMembersTableAnnotationComposer,
      $$JournalMembersTableCreateCompanionBuilder,
      $$JournalMembersTableUpdateCompanionBuilder,
      (
        JournalMemberRow,
        BaseReferences<_$AppDatabase, $JournalMembersTable, JournalMemberRow>,
      ),
      JournalMemberRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DiaryEntriesTableTableManager get diaryEntries =>
      $$DiaryEntriesTableTableManager(_db, _db.diaryEntries);
  $$JournalsTableTableManager get journals =>
      $$JournalsTableTableManager(_db, _db.journals);
  $$JournalMembersTableTableManager get journalMembers =>
      $$JournalMembersTableTableManager(_db, _db.journalMembers);
}
