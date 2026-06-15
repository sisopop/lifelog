import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_keys.dart';
import '../../shared/models/diary_entry.dart';
import '../../shared/models/enums.dart';
import 'ai_summary.dart';

/// Calls Google Gemini 2.5 Flash to summarize diary entries and build a
/// monthly review. Falls back to the local mock when no key is configured
/// or the request fails (so the app never breaks).
class GeminiService {
  GeminiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _model = 'gemini-2.5-flash';
  static const _base =
      'https://generativelanguage.googleapis.com/v1beta/models';

  bool get enabled => ApiKeys.hasGemini;

  /// One short, warm Korean one-liner summarizing the entry.
  Future<String> summarize(DiaryEntry entry) async {
    if (!enabled) return mockSummarize(entry);

    final mood = switch (entry.mood) {
      Mood.good => '좋음',
      Mood.neutral => '보통',
      Mood.hard => '힘듦',
      null => '미지정',
    };
    final prompt = '''
다음은 사용자가 쓴 일기입니다. 따뜻하고 담백한 한국어 한 문장(최대 50자)으로 요약해 주세요.
- 평가나 조언 없이, 그날의 핵심과 감정만 담백하게.
- 따옴표나 머리말 없이 문장만 출력.

제목: ${entry.title ?? '(없음)'}
감정: $mood
태그: ${entry.tags.isEmpty ? '(없음)' : entry.tags.join(', ')}
내용: ${entry.content}
''';

    try {
      final text = await _generate(prompt, maxTokens: 100);
      final cleaned = text?.trim();
      if (cleaned != null && cleaned.isNotEmpty) return cleaned;
    } catch (_) {/* fall through to mock */}
    return mockSummarize(entry);
  }

  /// A 2-3 sentence Korean monthly reflection from aggregated stats text.
  Future<String?> monthlyReport(String statsContext) async {
    if (!enabled) return null;
    final prompt = '''
다음은 사용자의 한 달치 일기 통계입니다. 이를 바탕으로 따뜻한 회고 리포트를
한국어 2~3문장으로 작성해 주세요. 과장 없이, 사용자가 자신의 한 달을
돌아볼 수 있도록 담백하게 써 주세요. 문장만 출력하세요.

$statsContext
''';
    try {
      final text = await _generate(prompt, maxTokens: 200);
      return text?.trim();
    } catch (_) {
      return null;
    }
  }

  Future<String?> _generate(String prompt, {required int maxTokens}) async {
    final uri = Uri.parse('$_base/$_model:generateContent?key=${ApiKeys.gemini}');
    final res = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.7,
              'maxOutputTokens': maxTokens,
            },
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode != 200) return null;
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final candidates = body['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return null;
    final parts = (candidates.first['content']?['parts']) as List?;
    if (parts == null || parts.isEmpty) return null;
    return parts.first['text'] as String?;
  }
}
