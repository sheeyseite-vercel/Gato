import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shared_preferences/shared_preferences.dart';
import '../logic.dart';
import '../profile.dart';
import '../quotes_data.dart';
import '../repo.dart';
import '../theme.dart';
import '../widgets.dart';
import 'mood.dart';
import 'settings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _clock;
  int _msg = 0;
  bool _changing = false;
  String? _picked;

  @override
  void initState() {
    super.initState();
    _loadMsg();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  Future<void> _loadMsg() async {
    final p = await SharedPreferences.getInstance();
    final parts = (p.getString('home_msg') ?? '').split('|');
    if (parts.length == 2 && parts[0] == dkey(DateTime.now())) {
      if (mounted) setState(() => _msg = int.tryParse(parts[1]) ?? 0);
    }
  }

  Future<void> _pick(Mood m) async {
    final idx = Random().nextInt(moodMessages[m.id]!.length);
    setState(() {
      _msg = idx;
      _changing = false;
      _picked = m.id;
    });
    final p = await SharedPreferences.getInstance();
    await p.setString('home_msg', '${dkey(DateTime.now())}|$idx');
    try {
      await Repo.setMood(dkey(DateTime.now()), m.id);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) =>
      LiveData<Map<String, String>>(loader: Repo.moodDays, builder: _content);

  Widget _content(BuildContext context, Map<String, String> moods) {
    final now = DateTime.now();
    final night = isNightTime(now);
    final today = _changing ? null : moodById(_picked ?? moods[dkey(now)]);
    final quote = quotePool[quoteIndex(now, quotePool.length)];

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 120),
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(DateFormat('EEEE · MMM d').format(now), style: txt(14, color: C.muted)),
              const SizedBox(height: 4),
              Text(greetingFor(now), style: disp(34)),
              ValueListenableBuilder<String?>(
                valueListenable: Profile.name,
                builder: (_, n, __) => dirText(n ?? 'friend', disp(34, color: C.lime), maxLines: 1),
              ),
            ]),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            child: const CatLogo(size: 76),
          ),
        ]),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SizeTransition(sizeFactor: anim, axisAlignment: -1, child: child),
          ),
          child: today == null ? _ask(night) : _answer(today),
        ),
        Stack(clipBehavior: Clip.none, children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 58),
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
              Text(quote, style: disp(22, color: C.green).copyWith(height: 1.4)),
              const SizedBox(height: 6),
              Text('Quote of the day', style: txt(13, color: C.green, w: FontWeight.w700)),
            ]),
          ),
          const Positioned(top: 15, right: 30, child: CatPeek()),
        ]),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MoodScreen())),
          child: Glass(
            radius: 24,
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('Your mood this week', style: txt(15, w: FontWeight.w700))),
                const Icon(Icons.chevron_right_rounded, color: C.muted),
              ]),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  for (var i = 6; i >= 0; i--) _dayFace(DateTime(now.year, now.month, now.day - i), moods),
                ]),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _ask(bool night) {
    return Glass(
      key: const ValueKey('ask'),
      radius: 28,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(night ? 'How was your day?' : "How's your day?", style: disp(26)),
        const SizedBox(height: 2),
        Text('Tap the face that fits.', style: txt(14, color: C.muted)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          for (final m in moodList)
            InkResponse(
              onTap: () => _pick(m),
              child: SizedBox(
                width: 64,
                child: Column(children: [
                  MoodFace(m, size: 56),
                  const SizedBox(height: 6),
                  Text(m.label, style: txt(12)),
                ]),
              ),
            ),
        ]),
      ]),
    );
  }

  Widget _answer(Mood m) {
    final msgs = moodMessages[m.id]!;
    return Container(
      key: ValueKey('answer-${m.id}-$_msg'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: BoxDecoration(
        color: op(m.color, .14),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: op(m.color, .55)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          MoodFace(m, size: 44),
          const SizedBox(width: 12),
          Text('Feeling ${m.label.toLowerCase()}', style: txt(15, color: m.color, w: FontWeight.w700)),
        ]),
        const SizedBox(height: 14),
        Text(msgs[_msg % msgs.length], style: disp(22).copyWith(height: 1.35)),
        const SizedBox(height: 12),
        GChip('Change', onTap: () => setState(() => _changing = true)),
      ]),
    );
  }

  Widget _dayFace(DateTime d, Map<String, String> moods) {
    final m = moodById(moods[dkey(d)]);
    return Column(children: [
      m != null
          ? MoodFace(m, size: 34)
          : Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: op(C.white, .25))),
            ),
      const SizedBox(height: 4),
      Text(DateFormat('E').format(d)[0], style: txt(12, color: C.muted)),
    ]);
  }
}
