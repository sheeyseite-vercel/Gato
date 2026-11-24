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

int hourCount(DateTime d) => DateTime.utc(d.year, d.month, d.day, d.hour).millisecondsSinceEpoch ~/ 3600000;

int dayCount(DateTime d) => DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/ 86400000;

/// Short date such as "Tues Nov 24".
String shortDate(DateTime d) {
  const wd = ['Mon', 'Tues', 'Wed', 'Thurs', 'Fri', 'Sat', 'Sun'];
  const mo = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${wd[d.weekday - 1]} ${mo[d.month - 1]} ${d.day}';
}
