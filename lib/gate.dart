import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'lock.dart';
import 'pin_pad.dart';
import 'shell.dart';
import 'widgets.dart';

/// Action requested from the home screen widget (entry / voice / quote).
class Pending {
  static final action = ValueNotifier<String?>(null);
}

class Gate extends StatefulWidget {
  const Gate({super.key});
  @override
  State<Gate> createState() => _GateState();
}

class _GateState extends State<Gate> with WidgetsBindingObserver {
  bool _ready = false, _hasPin = false, _skipped = false, _locked = false;
  DateTime? _pausedAt;
  String? _lastUri;
  DateTime _lastAt = DateTime.fromMillisecondsSinceEpoch(0);
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _links();
  }

  Future<void> _load() async {
    final h = await Lock.hasPin();
    final k = await Lock.skipped();
    if (!mounted) return;
    setState(() {
      _hasPin = h;
      _skipped = k;
      _locked = h;
      _ready = true;
    });
  }

  Future<void> _links() async {
    final al = AppLinks();
    try {
      final u = await al.getInitialLink();
      if (u != null) _onUri(u);
    } catch (_) {}
    _linkSub = al.uriLinkStream.listen(_onUri);
  }

  void _onUri(Uri u) {
    final s = u.toString();
    final now = DateTime.now();
    if (s == _lastUri && now.difference(_lastAt).inSeconds < 2) return;
    _lastUri = s;
    _lastAt = now;
    if (u.scheme == 'gato' && u.host == 'new' && u.pathSegments.isNotEmpty) {
      Pending.action.value = u.pathSegments.first;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final p = _pausedAt;
      _pausedAt = null;
      if (_hasPin && p != null) {
        final secs = await Lock.autoLockSeconds();
        if (mounted && DateTime.now().difference(p).inSeconds >= secs) {
          setState(() => _locked = true);
        }
      }
    }
  }

  Future<void> _setupDone() async {
    final h = await Lock.hasPin();
    final k = await Lock.skipped();
    if (!mounted) return;
    setState(() {
      _hasPin = h;
      _skipped = k;
      _locked = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const Splash();
    if (!_hasPin && !_skipped) return SetPinScreen(onDone: _setupDone);
    if (_locked) return LockScreen(onUnlocked: () => setState(() => _locked = false));
    return const Shell();
  }
}
