import 'dart:convert';

import '../../shared/models/diary_entry.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/journal.dart';

/// Backup document format version. Bump when the shape changes so that
/// [parseBackupJson] can migrate older files instead of rejecting them.
const int kBackupFormatVersion = 1;

/// Parsed contents of a lifelog backup document.
class BackupData {
  const BackupData({
    required this.version,
    required this.journals,
    required this.entries,
    this.exportedAt,
  });

  final int version;
  final List<Journal> journals;
  final List<DiaryEntry> entries;
  final DateTime? exportedAt;
}

/// Thrown when a backup document can't be read — wrong app, broken JSON, or a
/// record missing a required field. The [message] is user-facing (Korean).
class BackupParseException implements Exception {
  const BackupParseException(this.message);
  final String message;
  @override
  String toString() => 'BackupParseException: $message';
}

/// Serializes every [journal] + [entry] into a versioned, full-fidelity JSON
/// backup string (pretty-printed). Unlike the Markdown export this is a
/// loss-less round-trip: [parseBackupJson] rebuilds the exact same models.
/// Soft-deleted (trashed) records are included so the trash survives a restore.
String exportBackupJson(
  List<Journal> journals,
  List<DiaryEntry> entries,
  DateTime now,
) {
  final map = <String, dynamic>{
    'app': 'lifelog',
    'version': kBackupFormatVersion,
    'exportedAt': now.toIso8601String(),
    'journals': [for (final j in journals) _journalToJson(j)],
    'entries': [for (final e in entries) _entryToJson(e)],
  };
  return const JsonEncoder.withIndent('  ').convert(map);
}

/// Parses a backup string produced by [exportBackupJson] back into models.
/// Throws [BackupParseException] with a Korean message when the document is not
/// valid JSON, is not a lifelog backup, or a record is missing a required field.
BackupData parseBackupJson(String raw) {
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } catch (_) {
    throw const BackupParseException('백업 형식이 아니에요 (JSON을 읽을 수 없어요)');
  }
  if (decoded is! Map<String, dynamic>) {
    throw const BackupParseException('백업 형식이 아니에요');
  }
  if (decoded['app'] != 'lifelog') {
    throw const BackupParseException('lifelog 백업 파일이 아니에요');
  }
  final version = (decoded['version'] as num?)?.toInt() ?? 0;

  final journalsRaw = decoded['journals'];
  final entriesRaw = decoded['entries'];
  if (journalsRaw is! List || entriesRaw is! List) {
    throw const BackupParseException('백업 내용이 손상됐어요');
  }

  final journals = <Journal>[];
  for (final j in journalsRaw) {
    if (j is! Map<String, dynamic>) {
      throw const BackupParseException('일기장 정보가 손상됐어요');
    }
    journals.add(_journalFromJson(j));
  }
  final entries = <DiaryEntry>[];
  for (final e in entriesRaw) {
    if (e is! Map<String, dynamic>) {
      throw const BackupParseException('기록 정보가 손상됐어요');
    }
    entries.add(_entryFromJson(e));
  }

  return BackupData(
    version: version,
    journals: journals,
    entries: entries,
    exportedAt: _dateOrNull(decoded['exportedAt']),
  );
}

/// Counts for a restore preview: how many records are brand new vs. already
/// present (matched by id, and therefore overwritten by the backup copy).
class RestoreSummary {
  const RestoreSummary({
    required this.newJournals,
    required this.updatedJournals,
    required this.newEntries,
    required this.updatedEntries,
  });

  final int newJournals;
  final int updatedJournals;
  final int newEntries;
  final int updatedEntries;

  int get totalJournals => newJournals + updatedJournals;
  int get totalEntries => newEntries + updatedEntries;
}

/// Pure: classifies a [backup]'s records against what already exists (by id) so
/// the UI can preview and report the restore. Mutates nothing. A record whose
/// id already exists will be overwritten (counted as "updated"); the rest are
/// "new".
RestoreSummary summarizeRestore({
  required Set<String> existingJournalIds,
  required Set<String> existingEntryIds,
  required BackupData backup,
}) {
  var newJournals = 0;
  var updatedJournals = 0;
  for (final j in backup.journals) {
    if (existingJournalIds.contains(j.journalId)) {
      updatedJournals++;
    } else {
      newJournals++;
    }
  }
  var newEntries = 0;
  var updatedEntries = 0;
  for (final e in backup.entries) {
    if (existingEntryIds.contains(e.entryId)) {
      updatedEntries++;
    } else {
      newEntries++;
    }
  }
  return RestoreSummary(
    newJournals: newJournals,
    updatedJournals: updatedJournals,
    newEntries: newEntries,
    updatedEntries: updatedEntries,
  );
}

// ── serialization helpers ──────────────────────────────────────────────────

Map<String, dynamic> _entryToJson(DiaryEntry e) => {
      'entryId': e.entryId,
      'userId': e.userId,
      'journalId': e.journalId,
      if (e.replyToEntryId != null) 'replyToEntryId': e.replyToEntryId,
      'lang': e.lang,
      if (e.title != null) 'title': e.title,
      'content': e.content,
      if (e.aiSummary != null) 'aiSummary': e.aiSummary,
      'aiStatus': e.aiStatus.name,
      if (e.mood != null) 'mood': e.mood!.name,
      'visibility': e.visibility.name,
      if (e.location != null) 'location': e.location,
      'createdAt': e.createdAt.toIso8601String(),
      'updatedAt': e.updatedAt.toIso8601String(),
      'mediaUrls': e.mediaUrls,
      'tags': e.tags,
      if (e.pageCanvas != null) 'pageCanvas': e.pageCanvas,
      'isFavorite': e.isFavorite,
      if (e.deletedAt != null) 'deletedAt': e.deletedAt!.toIso8601String(),
      'syncStatus': e.syncStatus.name,
    };

Map<String, dynamic> _journalToJson(Journal j) => {
      'journalId': j.journalId,
      'ownerId': j.ownerId,
      'type': j.type.name,
      'title': j.title,
      'coverColor': j.coverColor,
      'coverPattern': j.coverPattern,
      'coverBinding': j.coverBinding,
      'coverCorner': j.coverCorner,
      'coverBand': j.coverBand,
      'coverRibbon': j.coverRibbon,
      'coverClip': j.coverClip,
      'coverTab': j.coverTab,
      'coverTexture': j.coverTexture,
      'coverFont': j.coverFont,
      'innerPaper': j.innerPaper,
      'innerPaperColor': j.innerPaperColor,
      if (j.icon != null) 'icon': j.icon,
      'iconX': j.iconX,
      'iconY': j.iconY,
      'status': j.status.name,
      if (j.spaceId != null) 'spaceId': j.spaceId,
      'createdAt': j.createdAt.toIso8601String(),
      if (j.deletedAt != null) 'deletedAt': j.deletedAt!.toIso8601String(),
    };

DiaryEntry _entryFromJson(Map<String, dynamic> m) {
  return DiaryEntry(
    entryId: _str(m['entryId'], '기록 ID'),
    userId: (m['userId'] as String?) ?? '',
    journalId: _str(m['journalId'], '기록의 일기장 ID'),
    replyToEntryId: m['replyToEntryId'] as String?,
    lang: (m['lang'] as String?) ?? 'ko',
    title: m['title'] as String?,
    content: (m['content'] as String?) ?? '',
    aiSummary: m['aiSummary'] as String?,
    aiStatus: _enumOr(AiStatus.values, m['aiStatus'], AiStatus.none),
    mood: _enumOrNull(Mood.values, m['mood']),
    visibility:
        _enumOr(EntryVisibility.values, m['visibility'], EntryVisibility.private),
    location: m['location'] as String?,
    createdAt: _dateRequired(m['createdAt'], '작성 시각'),
    updatedAt: _dateRequired(m['updatedAt'], '수정 시각'),
    mediaUrls: _stringList(m['mediaUrls']),
    tags: _stringList(m['tags']),
    pageCanvas: m['pageCanvas'] as String?,
    isFavorite: m['isFavorite'] == true,
    deletedAt: _dateOrNull(m['deletedAt']),
    syncStatus: _enumOr(SyncStatus.values, m['syncStatus'], SyncStatus.synced),
  );
}

Journal _journalFromJson(Map<String, dynamic> m) {
  return Journal(
    journalId: _str(m['journalId'], '일기장 ID'),
    ownerId: (m['ownerId'] as String?) ?? '',
    type: _enumOr(JournalType.values, m['type'], JournalType.personal),
    title: (m['title'] as String?) ?? '제목 없음',
    coverColor: (m['coverColor'] as num?)?.toInt() ?? 0xFF7C6FF0,
    coverPattern: (m['coverPattern'] as String?) ?? 'none',
    coverBinding: (m['coverBinding'] as String?) ?? 'plain',
    coverCorner: (m['coverCorner'] as String?) ?? 'none',
    coverBand: (m['coverBand'] as String?) ?? 'none',
    coverRibbon: (m['coverRibbon'] as String?) ?? 'none',
    coverClip: (m['coverClip'] as String?) ?? 'none',
    coverTab: (m['coverTab'] as String?) ?? 'none',
    coverTexture: (m['coverTexture'] as String?) ?? 'none',
    coverFont: (m['coverFont'] as String?) ?? 'pretendard',
    innerPaper: (m['innerPaper'] as String?) ?? 'plain',
    innerPaperColor: (m['innerPaperColor'] as String?) ?? 'cream',
    icon: m['icon'] as String?,
    iconX: (m['iconX'] as num?)?.toDouble() ?? 0.0,
    iconY: (m['iconY'] as num?)?.toDouble() ?? 0.0,
    status: _enumOr(JournalStatus.values, m['status'], JournalStatus.active),
    spaceId: m['spaceId'] as String?,
    createdAt: _dateRequired(m['createdAt'], '일기장 생성 시각'),
    deletedAt: _dateOrNull(m['deletedAt']),
  );
}

// ── small parse utilities ───────────────────────────────────────────────────

String _str(Object? v, String field) {
  if (v is String && v.isNotEmpty) return v;
  throw BackupParseException('$field 항목이 비어 있어요');
}

List<String> _stringList(Object? v) =>
    v is List ? [for (final e in v) e.toString()] : const [];

T _enumOr<T extends Enum>(List<T> values, Object? raw, T fallback) {
  for (final v in values) {
    if (v.name == raw) return v;
  }
  return fallback;
}

T? _enumOrNull<T extends Enum>(List<T> values, Object? raw) {
  for (final v in values) {
    if (v.name == raw) return v;
  }
  return null;
}

DateTime _dateRequired(Object? v, String field) {
  final d = _dateOrNull(v);
  if (d == null) throw BackupParseException('$field 항목이 손상됐어요');
  return d;
}

DateTime? _dateOrNull(Object? v) {
  if (v is! String) return null;
  return DateTime.tryParse(v);
}
