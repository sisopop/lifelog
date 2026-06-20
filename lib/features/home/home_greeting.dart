/// Pure: a friendly greeting for the given hour-of-day (0–23).
/// 새벽(0–5) · 아침(6–11) · 오후(12–17) · 저녁/밤(18–23).
String greetingForHour(int hour) {
  if (hour < 6) return '편안한 새벽이에요';
  if (hour < 12) return '좋은 아침이에요';
  if (hour < 18) return '좋은 오후예요';
  return '편안한 밤 되세요';
}
