import 'package:flutter_test/flutter_test.dart';
import 'package:gato/logic.dart';
import 'package:gato/quotes_data.dart';

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

  test('short date', () {
    expect(shortDate(DateTime(2026, 11, 24)), 'Tues Nov 24');
    expect(shortDate(DateTime(2026, 11, 26)), 'Thurs Nov 26');
    expect(shortDate(DateTime(2026, 1, 5)), 'Mon Jan 5');
  });

  test('cat words never repeat within 10 cards', () {
    expect(catWords.toSet().length, catWords.length);
    expect(catWords.length >= 11, true);
    for (var h = 0; h < 48; h++) {
      final seen = <String>{};
      for (var k = 0; k < 11; k++) {
        seen.add(catWords[(hourCount(DateTime(2026, 11, 23, 0)) + h + k) % catWords.length]);
      }
      expect(seen.length, 11);
    }
  });
}
