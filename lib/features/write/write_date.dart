import 'package:intl/intl.dart';

/// Pure: format a day as the `date` query parameter used by the write route
/// (`/write?date=yyyy-MM-dd`). Only the date part is kept.
String writeDateParam(DateTime day) =>
    DateFormat('yyyy-MM-dd').format(DateTime(day.year, day.month, day.day));

/// Pure: parse the write route's `date` query parameter back into a day.
/// Returns null for null, empty, or malformed input. The time-of-day is
/// dropped so callers get a clean calendar day.
DateTime? parseWriteDate(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final d = DateTime.tryParse(raw.trim());
  if (d == null) return null;
  return DateTime(d.year, d.month, d.day);
}
