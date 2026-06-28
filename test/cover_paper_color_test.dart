import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/cover_paper_color.dart';

void main() {
  group('paperColorPalette', () {
    test('첫 항목은 기본(크림)이다', () {
      expect(paperColorPalette.first.id, kDefaultPaperColor);
      expect(paperColorPalette.first.label, '크림');
    });

    test('id에 중복이 없다', () {
      final ids = paperColorPalette.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });

  group('normalizePaperColor', () {
    test('알려진 id는 그대로 둔다', () {
      expect(normalizePaperColor('blue'), 'blue');
      expect(normalizePaperColor('pink'), 'pink');
    });

    test('알 수 없는 id/빈 문자열은 기본으로 폴백한다', () {
      expect(normalizePaperColor('bogus'), kDefaultPaperColor);
      expect(normalizePaperColor(''), kDefaultPaperColor);
    });
  });

  group('paperColorOf', () {
    test('프리셋 색을 돌려준다', () {
      expect(paperColorOf(kDefaultPaperColor), const Color(0xFFFFFDF7));
      expect(paperColorOf('blue'), const Color(0xFFEFF4FB));
    });

    test('알 수 없는 id는 기본 색으로 폴백한다', () {
      expect(paperColorOf('bogus'), const Color(0xFFFFFDF7));
    });
  });

  group('paperColorLabel', () {
    test('프리셋 라벨을 돌려준다', () {
      expect(paperColorLabel('green'), '그린');
    });

    test('알 수 없는 id는 기본 라벨로 폴백한다', () {
      expect(paperColorLabel('bogus'), '크림');
    });
  });
}
