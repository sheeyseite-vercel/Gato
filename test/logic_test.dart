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
}
