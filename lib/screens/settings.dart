import 'package:flutter/material.dart';
import '../lock.dart';
import '../pin_pad.dart';
import '../theme.dart';
import '../widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hasPin = false;
  int _auto = 60;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final h = await Lock.hasPin();
    final a = await Lock.autoLockSeconds();
    if (mounted) {
      setState(() {
        _hasPin = h;
        _auto = a;
        _loaded = true;
      });
    }
  }

  String get _autoLabel => _auto == 0 ? 'Immediately' : (_auto == 60 ? '1 min' : '${_auto ~/ 60} min');

  Future<void> _togglePin(bool on) async {
    if (on) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (ctx) => SetPinScreen(canSkip: false, onDone: () => Navigator.pop(ctx))),
      );
    } else {
      final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const VerifyPinScreen()));
      if (ok == true) {
        await Lock.clear();
        await Lock.setSkipped(true);
      }
    }
    _refresh();
  }

  Future<void> _changePin() async {
    final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const VerifyPinScreen()));
    if (ok != true || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => SetPinScreen(canSkip: false, onDone: () => Navigator.pop(ctx))),
    );
    _refresh();
  }

  Future<void> _pickAuto() async {
    final v = await showDialog<int>(
      context: context,
      builder: (_) => SimpleDialog(
        backgroundColor: C.deep,
        title: Text('Auto-lock', style: txt(17, w: FontWeight.w700)),
        children: [
          for (final e in const {'Immediately': 0, '1 minute': 60, '5 minutes': 300}.entries)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, e.value),
              child: Text(e.key, style: txt(16, color: e.value == _auto ? C.lime : C.white, w: FontWeight.w700)),
            ),
        ],
      ),
    );
    if (v != null) {
      await Lock.setAutoLock(v);
      _refresh();
    }
  }

  Widget _row(String label, Widget trailing, {VoidCallback? onTap, bool first = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(border: first ? null : Border(top: BorderSide(color: op(C.white, .1)))),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(label, style: txt(15))),
          trailing,
        ]),
      ),
    );
  }

  Widget _val(String v) => Row(mainAxisSize: MainAxisSize.min, children: [
        Text(v, style: txt(14, color: C.muted)),
        const Icon(Icons.chevron_right_rounded, color: C.muted),
      ]);

  Widget _group(String title, List<Widget> rows) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 6),
          child: Text(title.toUpperCase(), style: txt(12, color: C.lime, w: FontWeight.w700).copyWith(letterSpacing: 1)),
        ),
        Container(
          decoration: BoxDecoration(
            color: op(C.white, .08),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: op(C.white, .14)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: rows),
        ),
      ]);

  @override
  Widget build(BuildContext context) {
    const name = 'GATO';
    const email = 'Stored privately on this device';
    return Screen(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
        children: [
          Row(children: [
            CircleBtn(Icons.arrow_back_rounded, label: 'Back', onTap: () => Navigator.pop(context)),
            const SizedBox(width: 12),
            Text('Settings', style: disp(26)),
          ]),
          const SizedBox(height: 16),
          Glass(
            radius: 24,
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              const CatLogo(size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  dirText(name, disp(20), maxLines: 1),
                  Text(email, style: txt(13, color: C.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
            ]),
          ),
          if (_loaded) ...[
            _group('Privacy', [
              _row(
                'PIN lock',
                Switch(
                  value: _hasPin,
                  onChanged: _togglePin,
                  activeColor: C.green,
                  activeTrackColor: C.lime,
                  inactiveTrackColor: op(C.white, .2),
                  inactiveThumbColor: C.white,
                ),
                first: true,
              ),
              if (_hasPin) _row('Change PIN', _val(''), onTap: _changePin),
              if (_hasPin) _row('Auto-lock', _val(_autoLabel), onTap: _pickAuto),
            ]),
            _group('Writing', [
              _row('Any language, including Arabic', const Icon(Icons.check_circle_rounded, color: C.lime), first: true),
              _row('Text direction', _val('Auto')),
            ]),
            _group('Data', [
              _row('Storage', Text('This device', style: txt(14, color: C.lime, w: FontWeight.w700)), first: true),
            ]),
          ],
        ],
      ),
    );
  }
}
