import 'package:flutter_test/flutter_test.dart';
import 'package:gato/logic.dart';

void main() {
  test('streak counts consecutive days ending today or yesterday', () {
    final today = DateTime(2026, 11, 22);
    expect(computeStreak({'2026-11-22', '2026-11-21', '2026-11-20'}, today), 3);
    expect(computeStreak({'2026-11-21'}, today), 1);
    expect(computeStreak({'2026-11-19'}, today), 0);
    expect(computeStreak(<String>{}, today), 0);
  });

  test('rtl detection uses first strong letter', () {
    expect(isRtl('مرحبا'), true);
    expect(isRtl('Hello'), false);
    expect(isRtl('123 مرحبا'), true);
    expect(isRtl(''), false);
  });

  test('duration format', () {
    expect(fmtDuration(134000), '02:14');
  });

  test('greeting follows the time of day', () {
    expect(greetingFor(DateTime(2026, 1, 1, 5, 0)), 'Good morning,');
    expect(greetingFor(DateTime(2026, 1, 1, 11, 59)), 'Good morning,');
    expect(greetingFor(DateTime(2026, 1, 1, 12, 0)), 'Good afternoon,');
    expect(greetingFor(DateTime(2026, 1, 1, 18, 0)), 'Good afternoon,');
    expect(greetingFor(DateTime(2026, 1, 1, 18, 1)), 'Good evening,');
    expect(greetingFor(DateTime(2026, 1, 1, 23, 59)), 'Good evening,');
    expect(greetingFor(DateTime(2026, 1, 1, 0, 30)), 'Still up,');
    expect(greetingFor(DateTime(2026, 1, 1, 4, 59)), 'Still up,');
    expect(isNightTime(DateTime(2026, 1, 1, 12, 0)), false);
    expect(isNightTime(DateTime(2026, 1, 1, 19, 0)), true);
  });

  test('quote changes every hour', () {
    for (var h = 1; h < 24; h++) {
      final a = quoteIndex(DateTime(2026, 11, 23, h - 1), 50);
      final b = quoteIndex(DateTime(2026, 11, 23, h), 50);
      expect(a == b, false);
      expect(b >= 0 && b < 50, true);
    }
  });
}
