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
