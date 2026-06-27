import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/cover_paper.dart';

void main() {
  group('coverPaperPalette', () {
    test('첫 항목은 기본(무지)이다', () {
      expect(coverPaperPalette.first.id, kDefaultCoverPaper);
      expect(coverPaperPalette.first.label, '무지');
    });

    test('id에 중복이 없다', () {
      final ids = coverPaperPalette.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('줄노트(ruled)가 포함된다', () {
      expect(coverPaperPalette.any((p) => p.id == 'ruled'), isTrue);
    });

    test('가로줄(lined)이 포함된다', () {
      expect(coverPaperPalette.any((p) => p.id == 'lined'), isTrue);
    });
  });

  group('normalizeCoverPaper', () {
    test('알려진 id는 그대로 둔다', () {
      expect(normalizeCoverPaper('ruled'), 'ruled');
      expect(normalizeCoverPaper('grid'), 'grid');
      expect(normalizeCoverPaper('lined'), 'lined');
    });

    test('알 수 없는 id/빈 문자열은 기본으로 폴백한다', () {
      expect(normalizeCoverPaper('bogus'), kDefaultCoverPaper);
      expect(normalizeCoverPaper(''), kDefaultCoverPaper);
    });
  });

  group('coverPaperLabel', () {
    test('프리셋 라벨을 돌려준다', () {
      expect(coverPaperLabel(kDefaultCoverPaper), '무지');
      expect(coverPaperLabel('ruled'), '줄노트');
      expect(coverPaperLabel('lined'), '가로줄');
    });

    test('알 수 없는 id는 기본 라벨로 폴백한다', () {
      expect(coverPaperLabel('bogus'), '무지');
    });
  });
}
