import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../logic.dart';
import '../lying_cat.dart';
import '../profile.dart';
import '../quotes_data.dart';
import '../repo.dart';
import '../theme.dart';
import '../widgets.dart';
import 'journal.dart';
import 'settings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _clock, _msgTimer;
  int _msg = 0, _catTap = 0;
  bool _showMsg = false;
  String? _picked;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _msgTimer?.cancel();
    super.dispose();
  }

  Future<void> _pick(Mood m) async {
    final idx = Random().nextInt(moodMessages[m.id]!.length);
    _msgTimer?.cancel();
    setState(() {
      _msg = idx;
      _picked = m.id;
      _showMsg = true;
    });
    _msgTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showMsg = false);
    });
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
    final current = _picked ?? moods[dkey(now)];
    final pickedMood = moodById(_picked);
    final prompt = prompts[dayCount(now) % prompts.length];
    final word = catWords[(hourCount(now) + _catTap) % catWords.length];

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 120),
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
          child: (_showMsg && pickedMood != null) ? _answer(pickedMood) : _ask(night, current),
        ),
        const SizedBox(height: 14),
        LyingCatCard(word: word, onTap: () => setState(() => _catTap++)),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EntryEditor(prompt: prompt))),
          child: Glass(
            radius: 24,
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
            child: Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(color: C.lime, shape: BoxShape.circle),
                child: const Icon(Icons.edit_rounded, color: C.green, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("TODAY'S PROMPT", style: txt(11, color: C.lime, w: FontWeight.w700).copyWith(letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(prompt, style: disp(18).copyWith(height: 1.3)),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded, color: C.muted),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _ask(bool night, String? currentId) {
    return Glass(
      key: const ValueKey('ask'),
      radius: 28,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(night ? 'How was your day?' : "How's your day?", style: disp(26)),
        const SizedBox(height: 2),
        Text(currentId == null ? 'Tap the face that fits.' : 'Tap again any time to change it.',
            style: txt(14, color: C.muted)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          for (final m in moodList)
            InkResponse(
              onTap: () => _pick(m),
              child: SizedBox(
                width: 64,
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: currentId == m.id ? C.white : Colors.transparent, width: 2),
                    ),
                    child: MoodFace(m, size: 50),
                  ),
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
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
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
        const SizedBox(height: 14),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.0, end: 0.0),
          duration: const Duration(seconds: 5),
          builder: (_, v, __) => ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: v, minHeight: 4, color: m.color, backgroundColor: op(C.white, .1)),
          ),
        ),
      ]),
    );
  }
}
