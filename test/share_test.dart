import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/share/share_screen.dart';

void main() {
  test('shareUrlFor builds a stable lifelog link', () {
    final url = shareUrlFor('entry-123');
    expect(url.startsWith('https://lifelog.app/s/'), isTrue);
    // deterministic for the same id
    expect(shareUrlFor('entry-123'), url);
    // different ids produce different links
    expect(shareUrlFor('entry-999'), isNot(url));
  });
}
