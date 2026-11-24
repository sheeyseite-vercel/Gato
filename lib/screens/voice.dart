import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../logic.dart';
import '../repo.dart';
import '../theme.dart';
import '../widgets.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});
  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

enum _Phase { idle, recording, stopped }

class _VoiceScreenState extends State<VoiceScreen> {
  final _rec = AudioRecorder();
  final _player = AudioPlayer();
  final _sw = Stopwatch();
  StreamSubscription<Amplitude>? _ampSub;
  StreamSubscription<void>? _doneSub;
  Timer? _timer;
  _Phase _phase = _Phase.idle;
  String? _path;
  int _ms = 0;
  final List<double> _levels = [];
  final List<int> _marks = [];
  String? _playingId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _doneSub = _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingId = null);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ampSub?.cancel();
    _doneSub?.cancel();
    _rec.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      if (!await _rec.hasPermission()) {
        if (mounted) toast(context, 'Microphone permission is needed to record.');
        return;
      }
      await _player.stop();
      final dir = await getTemporaryDirectory();
      final p = '${dir.path}/gato_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _rec.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: p);
      _sw
        ..reset()
        ..start();
      _levels.clear();
      _marks.clear();
      _ampSub = _rec.onAmplitudeChanged(const Duration(milliseconds: 120)).listen((a) {
        final v = ((a.current + 60) / 60).clamp(0.05, 1.0).toDouble();
        if (mounted) {
          setState(() {
            _levels.add(v);
            if (_levels.length > 28) _levels.removeAt(0);
          });
        }
      });
      _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (mounted) setState(() => _ms = _sw.elapsedMilliseconds);
      });
      setState(() {
        _phase = _Phase.recording;
        _path = p;
        _ms = 0;
      });
    } catch (e) {
      if (mounted) toast(context, "Couldn't start recording.");
    }
  }

  Future<void> _stop() async {
    try {
      final p = await _rec.stop();
      _sw.stop();
      _timer?.cancel();
      await _ampSub?.cancel();
      setState(() {
        _phase = _Phase.stopped;
        _path = p ?? _path;
        _ms = _sw.elapsedMilliseconds;
      });
    } catch (e) {
      if (mounted) toast(context, "Couldn't stop recording.");
    }
  }

  void _discard() {
    final p = _path;
    if (p != null) {
      try {
        File(p).deleteSync();
      } catch (_) {}
    }
    setState(() {
      _phase = _Phase.idle;
      _path = null;
      _ms = 0;
      _levels.clear();
      _marks.clear();
    });
  }

  Future<void> _save() async {
    final p = _path;
    if (p == null || _saving) return;
    final title = await askText(context, 'Name this memo',
        initial: 'Voice memo · ${DateFormat('MMM d').format(DateTime.now())}');
    if (title == null) return;
    setState(() => _saving = true);
    try {
      await Repo.saveVoice(File(p), _ms, List<int>.from(_marks), title);
      try {
        File(p).deleteSync();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _phase = _Phase.idle;
          _path = null;
          _ms = 0;
          _levels.clear();
          _marks.clear();
        });
        toast(context, 'Saved');
      }
    } catch (e) {
      if (mounted) toast(context, "Couldn't upload. Check your connection and try again.");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggle(Map<String, dynamic> m) async {
    final id = m['id'] as String;
    try {
      if (_playingId == id) {
        await _player.stop();
        setState(() => _playingId = null);
        return;
      }
      final url = await Repo.voiceUrl(m['storage_path'] as String);
      await _player.stop();
      await _player.play(DeviceFileSource(url));
      setState(() => _playingId = id);
    } catch (e) {
      if (mounted) toast(context, "Couldn't play this memo.");
    }
  }

  Future<void> _delete(Map<String, dynamic> m) async {
    if (!await confirm(context, 'Delete this recording?')) return;
    try {
      if (_playingId == m['id']) await _player.stop();
      await Repo.removeVoice(m);
    } catch (e) {
      if (mounted) toast(context, "Couldn't delete.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final rec = _phase == _Phase.recording;
    final bars = List<double>.generate(28, (i) {
      final idx = i - (28 - _levels.length);
      return idx < 0 ? .05 : _levels[idx];
    });
    return Screen(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            CircleBtn(Icons.arrow_back_rounded, label: 'Back', onTap: () => Navigator.pop(context)),
            Text('Voice memo', style: disp(20)),
            const SizedBox(width: 44),
          ]),
          const SizedBox(height: 20),
          Center(child: Text(fmtDuration(_ms), style: disp(64, color: C.lime))),
          Center(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (rec) Container(width: 10, height: 10, margin: const EdgeInsets.only(right: 8), decoration: const BoxDecoration(color: C.orange, shape: BoxShape.circle)),
              Text(
                rec ? 'Recording' : (_phase == _Phase.stopped ? 'Recorded. Save it?' : 'Ready'),
                style: txt(14, color: C.muted),
              ),
            ]),
          ),
          const SizedBox(height: 4),
          CatCard(
            left: true,
            child: Glass(
              radius: 28,
              padding: EdgeInsets.zero,
              child: SizedBox(
                height: 132,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                  for (final v in bars)
                    Container(
                      width: 5,
                      height: 8 + v * 90,
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      decoration: BoxDecoration(color: rec || _phase == _Phase.stopped ? C.lime : op(C.white, .3), borderRadius: BorderRadius.circular(3)),
                    ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 26),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (rec)
              CircleBtn(Icons.flag_rounded, bg: C.ice, fg: C.green, size: 56, label: 'Add marker', onTap: () {
                setState(() => _marks.add(_sw.elapsedMilliseconds));
                toast(context, 'Marker at ${fmtDuration(_sw.elapsedMilliseconds)}');
              })
            else if (_phase == _Phase.stopped)
              CircleBtn(Icons.delete_outline_rounded, size: 56, label: 'Discard', onTap: _discard)
            else
              const SizedBox(width: 56),
            const SizedBox(width: 26),
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(shape: BoxShape.circle, color: op(C.orange, .22)),
              child: Center(
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: op(C.orange, .4)),
                  child: Center(
                    child: InkResponse(
                      onTap: _saving ? null : (rec ? _stop : (_phase == _Phase.idle ? _start : null)),
                      child: Semantics(
                        button: true,
                        label: rec ? 'Stop recording' : 'Start recording',
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: C.orange),
                          child: Center(
                            child: rec
                                ? Container(width: 26, height: 26, decoration: BoxDecoration(color: C.green, borderRadius: BorderRadius.circular(7)))
                                : const Icon(Icons.mic_rounded, color: C.green, size: 34),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 26),
            if (_phase == _Phase.stopped)
              CircleBtn(_saving ? Icons.hourglass_top_rounded : Icons.check_rounded, bg: C.lime, fg: C.green, size: 56, label: 'Save', onTap: _save)
            else
              const SizedBox(width: 56),
          ]),
          const SizedBox(height: 24),
          Text('Previous recordings', style: txt(16, w: FontWeight.w700)),
          LiveData<Rows>(
            loader: () => Repo.list('gato_voice_memos'),
            builder: (context, memos) {
              if (memos.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text('No recordings yet.', style: txt(14, color: C.muted)),
                );
              }
              return Column(children: [for (final m in memos) _row(m)]);
            },
          ),
        ],
      ),
    );
  }

  Widget _row(Map<String, dynamic> m) {
    final playing = _playingId == m['id'];
    final created = DateTime.tryParse(m['created_at'] as String)?.toLocal() ?? DateTime.now();
    final marks = (m['markers'] as List?)?.length ?? 0;
    final title = (m['title'] as String? ?? '').isEmpty ? 'Voice memo' : m['title'] as String;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Glass(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(children: [
          CircleBtn(playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              bg: C.lime, fg: C.green, label: playing ? 'Pause' : 'Play', onTap: () => _toggle(m)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              dirText(title, txt(15, w: FontWeight.w700), maxLines: 1),
              Text(
                '${fmtDuration((m['duration_ms'] as int?) ?? 0)} · ${DateFormat('MMM d').format(created)}${marks > 0 ? ' · $marks markers' : ''}',
                style: txt(12, color: C.muted),
              ),
            ]),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: () => _delete(m),
            icon: const Icon(Icons.delete_outline_rounded, color: C.muted),
          ),
        ]),
      ),
    );
  }
}
