String dkey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

int computeStreak(Set<String> days, DateTime today) {
  var d = DateTime(today.year, today.month, today.day);
  if (!days.contains(dkey(d))) d = DateTime(d.year, d.month, d.day - 1);
  var n = 0;
  while (days.contains(dkey(d))) {
    n++;
    d = DateTime(d.year, d.month, d.day - 1);
  }
  return n;
}

/// True when the first strong letter of [s] belongs to a right-to-left script.
bool isRtl(String s) {
  for (final r in s.runes) {
    if ((r >= 0x0590 && r <= 0x08FF) ||
        (r >= 0xFB1D && r <= 0xFDFF) ||
        (r >= 0xFE70 && r <= 0xFEFF)) {
      return true;
    }
    if ((r >= 0x41 && r <= 0x5A) || (r >= 0x61 && r <= 0x7A)) return false;
  }
  return false;
}

String fmtDuration(int ms) {
  final s = ms ~/ 1000;
  final m = (s ~/ 60).toString().padLeft(2, '0');
  final r = (s % 60).toString().padLeft(2, '0');
  return '$m:$r';
}

/// Morning 05:00-11:59, afternoon 12:00-18:00, evening 18:01-23:59, late night 00:00-04:59.
String greetingFor(DateTime t) {
  final m = t.hour * 60 + t.minute;
  if (m >= 5 * 60 && m < 12 * 60) return 'Good morning,';
  if (m >= 12 * 60 && m <= 18 * 60) return 'Good afternoon,';
  if (m > 18 * 60) return 'Good evening,';
  return 'Still up,';
}

bool isNightTime(DateTime t) {
  final m = t.hour * 60 + t.minute;
  return m > 18 * 60 || m < 5 * 60;
}

int hourKey(DateTime d) => d.year * 1000000 + d.month * 10000 + d.day * 100 + d.hour;

/// A different pseudo-random quote every hour (never the same as the previous hour).
int quoteIndex(DateTime now, int count) {
  int idx(DateTime d) => ((hourKey(d) * 2654435761) % 4294967296) % count;
  final i = idx(now);
  final prev = idx(DateTime(now.year, now.month, now.day, now.hour).subtract(const Duration(hours: 1)));
  return i == prev ? (i + 1) % count : i;
}
