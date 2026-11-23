import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../logic.dart';
import '../repo.dart';
import '../theme.dart';
import '../widgets.dart';

class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});
  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  bool _month = false;
  DateTime _cursor = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    return Screen(
      child: LiveData<Map<String, String>>(loader: Repo.moodDays, builder: _content),
    );
  }

  Widget _content(BuildContext context, Map<String, String> moods) {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final List<DateTime> days = _month
        ? [for (var d = 1; d <= DateTime(_cursor.year, _cursor.month + 1, 0).day; d++) DateTime(_cursor.year, _cursor.month, d)]
        : [for (var i = 6; i >= 0; i--) DateTime(now.year, now.month, now.day - i)];

    final counts = <String, int>{for (final m in moodList) m.id: 0};
    for (final d in days) {
      final id = moods[dkey(d)];
      if (id != null && counts.containsKey(id)) counts[id] = counts[id]! + 1;
    }
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    Mood? top;
    var best = 0;
    for (final m in moodList) {
      if (counts[m.id]! > best) {
        best = counts[m.id]!;
        top = m;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
      children: [
        Row(children: [
          CircleBtn(Icons.arrow_back_rounded, label: 'Back', onTap: () => Navigator.pop(context)),
          const SizedBox(width: 12),
          Text('Mood', style: disp(26)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          GChip('Week', selected: !_month, onTap: () => setState(() => _month = false)),
          const SizedBox(width: 8),
          GChip('Month', selected: _month, onTap: () => setState(() => _month = true)),
        ]),
        const SizedBox(height: 16),
        if (_month)
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            CircleBtn(Icons.chevron_left_rounded,
                label: 'Previous month', onTap: () => setState(() => _cursor = DateTime(_cursor.year, _cursor.month - 1))),
            Text(DateFormat('MMMM yyyy').format(_cursor), style: disp(20)),
            Opacity(
              opacity: _cursor.isBefore(thisMonth) ? 1 : .35,
              child: CircleBtn(Icons.chevron_right_rounded,
                  label: 'Next month',
                  onTap: _cursor.isBefore(thisMonth)
                      ? () => setState(() => _cursor = DateTime(_cursor.year, _cursor.month + 1))
                      : null),
            ),
          ]),
        if (_month) const SizedBox(height: 12),
        Glass(
          radius: 24,
          padding: const EdgeInsets.all(14),
          child: _month ? _monthGrid(days, moods) : _weekRow(days, moods),
        ),
        const SizedBox(height: 16),
        Glass(
          radius: 24,
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Summary', style: txt(15, w: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              total == 0
                  ? 'No moods yet. Pick how you feel on Home.'
                  : 'Most common: ${top!.label.toLowerCase()} ($best of $total days logged)',
              style: txt(14, color: C.muted),
            ),
            const SizedBox(height: 12),
            for (final m in moodList)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  MoodFace(m, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : counts[m.id]! / total,
                        minHeight: 12,
                        color: m.color,
                        backgroundColor: op(C.white, .1),
                      ),
                    ),
                  ),
                  SizedBox(width: 32, child: Text('${counts[m.id]}', textAlign: TextAlign.right, style: txt(14, w: FontWeight.w700))),
                ]),
              ),
          ]),
        ),
      ],
    );
  }

  Widget _weekRow(List<DateTime> days, Map<String, String> moods) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      for (final d in days)
        Column(children: [
          _dot(d, moods, 38),
          const SizedBox(height: 6),
          Text(DateFormat('E').format(d), style: txt(12, color: C.muted)),
        ]),
    ]);
  }

  Widget _monthGrid(List<DateTime> days, Map<String, String> moods) {
    final offset = DateTime(_cursor.year, _cursor.month, 1).weekday - 1;
    return Column(children: [
      Row(children: [
        for (final l in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
          Expanded(child: Center(child: Text(l, style: txt(12, color: C.muted)))),
      ]),
      const SizedBox(height: 8),
      GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 6,
        crossAxisSpacing: 4,
        children: [
          for (var i = 0; i < offset; i++) const SizedBox(),
          for (final d in days) Center(child: _dot(d, moods, 34, number: true)),
        ],
      ),
    ]);
  }

  Widget _dot(DateTime d, Map<String, String> moods, double size, {bool number = false}) {
    final m = moodById(moods[dkey(d)]);
    if (m != null) return MoodFace(m, size: size);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: op(C.white, .25))),
      child: number ? Text('${d.day}', style: txt(12, color: C.muted)) : null,
    );
  }
}
