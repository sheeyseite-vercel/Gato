import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'lock.dart';
import 'theme.dart';
import 'widgets.dart';

/// Four-digit keypad. [onComplete] returns an error message, or null on success.
class PinPad extends StatefulWidget {
  final String title, subtitle;
  final Future<String?> Function(String pin) onComplete;
  final Widget? footer;
  const PinPad({super.key, required this.title, required this.subtitle, required this.onComplete, this.footer});

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';
  String? _err;
  bool _busy = false;

  Future<void> _tap(String d) async {
    if (_busy || _pin.length >= 4) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pin += d;
      _err = null;
    });
    if (_pin.length == 4) {
      _busy = true;
      final err = await widget.onComplete(_pin);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _err = err;
        _pin = '';
      });
    }
  }

  void _del() {
    if (_busy || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Widget _key(String label, {VoidCallback? onTap, Widget? child, Color? bg}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: bg ?? op(C.white, .09),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: op(C.white, .14)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap ?? () => _tap(label),
          child: SizedBox(
            width: 76,
            height: 76,
            child: Center(child: child ?? Text(label, style: disp(30))),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CatLogo(size: 104),
          const SizedBox(height: 16),
          Text(widget.title, style: disp(30)),
          const SizedBox(height: 4),
          Text(widget.subtitle, style: txt(15, color: C.muted)),
          const SizedBox(height: 22),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < 4; i++)
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.symmetric(horizontal: 9),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _pin.length ? C.eye : Colors.transparent,
                  border: Border.all(color: C.eye, width: 3),
                ),
              ),
          ]),
          SizedBox(
            height: 28,
            child: Center(child: Text(_err ?? '', style: txt(13, color: C.orange, w: FontWeight.w700))),
          ),
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            Row(mainAxisSize: MainAxisSize.min, children: [for (final k in row) _key(k)]),
          Row(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(width: 92, height: 92),
            _key('0'),
            _key('', onTap: _del, bg: C.orange, child: const Icon(Icons.backspace_outlined, color: C.green)),
          ]),
          if (widget.footer != null) widget.footer!,
        ]),
      ),
    );
  }
}

class LockScreen extends StatelessWidget {
  final VoidCallback onUnlocked;
  const LockScreen({super.key, required this.onUnlocked});

  @override
  Widget build(BuildContext context) {
    return Screen(
      child: PinPad(
        title: 'Welcome back',
        subtitle: 'Enter your PIN to open GATO',
        onComplete: (pin) async {
          if (await Lock.verify(pin)) {
            onUnlocked();
            return null;
          }
          HapticFeedback.heavyImpact();
          return 'Wrong PIN, try again';
        },
      ),
    );
  }
}

class VerifyPinScreen extends StatelessWidget {
  const VerifyPinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Screen(
      child: Stack(children: [
        PinPad(
          title: 'Enter your PIN',
          subtitle: 'Confirm it is you',
          onComplete: (pin) async {
            if (await Lock.verify(pin)) {
              if (context.mounted) Navigator.pop(context, true);
              return null;
            }
            return 'Wrong PIN, try again';
          },
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: CircleBtn(Icons.arrow_back_rounded, label: 'Back', onTap: () => Navigator.pop(context, false)),
        ),
      ]),
    );
  }
}

class SetPinScreen extends StatefulWidget {
  final VoidCallback onDone;
  final bool canSkip;
  const SetPinScreen({super.key, required this.onDone, this.canSkip = true});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  String? _first;

  @override
  Widget build(BuildContext context) {
    return Screen(
      child: Stack(children: [
        PinPad(
          key: ValueKey(_first == null),
          title: _first == null ? 'Create a PIN' : 'Confirm your PIN',
          subtitle: _first == null ? 'Choose 4 digits to protect GATO' : 'Enter the same 4 digits again',
          footer: widget.canSkip
              ? TextButton(
                  onPressed: () async {
                    await Lock.setSkipped(true);
                    widget.onDone();
                  },
                  child: Text('Skip for now', style: txt(15, color: C.lime, w: FontWeight.w700)),
                )
              : null,
          onComplete: (pin) async {
            if (_first == null) {
              setState(() => _first = pin);
              return null;
            }
            if (pin == _first) {
              await Lock.setPin(pin);
              widget.onDone();
              return null;
            }
            setState(() => _first = null);
            return "PINs didn't match. Start again";
          },
        ),
        if (!widget.canSkip)
          Padding(
            padding: const EdgeInsets.all(12),
            child: CircleBtn(Icons.arrow_back_rounded, label: 'Back', onTap: () => Navigator.pop(context)),
          ),
      ]),
    );
  }
}
