import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../logic.dart';
import '../repo.dart';
import '../theme.dart';
import '../widgets.dart';
import 'journal.dart';
import 'settings.dart';
import 'voice.dart';

class HomeData {
  final Rows entries, voices, quotes;
  HomeData(this.entries, this.voices, this.quotes);
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static Future<HomeData> _load() async {
    final r = await Future.wait([
      Repo.entries(),
      Repo.list('gato_voice_memos'),
      Repo.list('gato_quotes'),
    ]);
    return HomeData(r[0], r[1], r[2]);
  }

  @override
  Widget build(BuildContext context) => LiveData<HomeData>(loader: _load, builder: _content);

  Widget _content(BuildContext context, HomeData d) {
    final now = DateTime.now();
    final days = d.entries.map((e) => e['entry_date'] as String).toSet();
    final streak = computeStreak(days, now);
    final h = now.hour;
    final greet = h < 12 ? 'Good morning,' : (h < 18 ? 'Good afternoon,' : 'Good evening,');

    Map<String, dynamic>? quote;
    for (final q in d.quotes) {
      if (q['favorite'] == true) {
        quote = q;
        break;
      }
    }
    if (quote == null && d.quotes.isNotEmpty) quote = d.quotes.first;

    final recent = <Map<String, dynamic>>[
      ...d.entries.map((e) => {...e, '_k': 'entry'}),
      ...d.voices.map((v) => {...v, '_k': 'voice'}),
    ];
    recent.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));

    final qText = quote == null ? 'Save your first quote with the + button.' : quote['text'] as String;
    final qSource = quote == null ? '' : (quote['source'] as String? ?? '');

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 120),
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(DateFormat('EEEE · MMM d').format(now), style: txt(14, color: C.muted)),
              const SizedBox(height: 4),
              Text(greet, style: disp(34)),
              Text("how's your day?", style: disp(34, color: C.lime)),
            ]),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            child: const CatLogo(size: 56),
          ),
        ]),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          for (final m in moodList)
            InkResponse(
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => EntryEditor(initialMood: m.id))),
              child: SizedBox(
                width: 64,
                child: Column(children: [
                  MoodFace(m, size: 50),
                  const SizedBox(height: 6),
                  Text(m.label, style: txt(12)),
                ]),
              ),
            ),
        ]),
        const SizedBox(height: 8),
        Stack(clipBehavior: Clip.none, children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 50),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            decoration: const BoxDecoration(
              color: C.lime,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
                bottomRight: Radius.circular(28),
                bottomLeft: Radius.circular(8),
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('”', style: disp(60, color: op(C.green, .35)).copyWith(height: .8)),
              dirText(qText, disp(22, color: C.green).copyWith(height: 1.4)),
              const SizedBox(height: 6),
              Text(qSource.isEmpty ? 'Quote of the day' : 'Quote of the day · $qSource',
                  style: txt(13, color: C.green, w: FontWeight.w700)),
            ]),
          ),
          const Positioned(top: 7, right: 30, child: CatPeek()),
        ]),
        const SizedBox(height: 12),
        Glass(
          radius: 24,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('$streak', style: disp(34, color: C.orange)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(streak == 1 ? 'day streak' : 'day streak, keep going!',
                    style: txt(15, w: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              for (var i = 6; i >= 0; i--) _dayDot(DateTime(now.year, now.month, now.day - i), days, i == 0),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        Text('Recent', style: txt(16, w: FontWeight.w700)),
        const SizedBox(height: 4),
        if (recent.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('Nothing yet. Tap + to write your first entry.', style: txt(14, color: C.muted)),
          ),
        for (final r in recent.take(3)) _recentRow(context, r),
      ],
    );
  }

  Widget _dayDot(DateTime day, Set<String> days, bool today) {
    final done = days.contains(dkey(day));
    final color = done ? C.lime : (today ? C.orange : Colors.transparent);
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: color == Colors.transparent ? Border.all(color: op(C.white, .25)) : null,
      ),
      child: Text(DateFormat('E').format(day)[0],
          style: disp(15, color: color == Colors.transparent ? C.muted : C.green)),
    );
  }

  Widget _recentRow(BuildContext context, Map<String, dynamic> r) {
    final isVoice = r['_k'] == 'voice';
    final created = DateTime.tryParse(r['created_at'] as String)?.toLocal() ?? DateTime.now();
    final title = (r['title'] as String? ?? '').isEmpty
        ? (isVoice ? 'Voice memo' : 'Untitled entry')
        : r['title'] as String;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => isVoice ? const VoiceScreen() : EntryEditor(entry: Map<String, dynamic>.from(r))),
        ),
        child: Glass(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle, color: isVoice ? C.ice : C.mint),
              child: Icon(isVoice ? Icons.mic_rounded : Icons.menu_book_rounded, color: C.green, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                dirText(title, txt(15, w: FontWeight.w700), maxLines: 1),
                Text(
                  '${isVoice ? 'Voice' : 'Journal'} · ${DateFormat('MMM d').format(created)}',
                  style: txt(12, color: C.muted),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
