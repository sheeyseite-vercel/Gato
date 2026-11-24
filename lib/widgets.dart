import 'package:flutter/material.dart';
import 'repo.dart';
import 'theme.dart';

class Backdrop extends StatelessWidget {
  final Widget child;
  const Backdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: C.green,
      child: Stack(children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(1.1, -1.1),
                radius: 1.0,
                colors: [op(C.lime, .22), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-1.2, .4),
                radius: .9,
                colors: [op(C.orange, .20), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ]),
    );
  }
}

class Screen extends StatelessWidget {
  final Widget child;
  const Screen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.green,
      body: Backdrop(child: SafeArea(child: child)),
    );
  }
}

class Splash extends StatelessWidget {
  const Splash({super.key});
  @override
  Widget build(BuildContext context) =>
      const Screen(child: Center(child: CatLogo(size: 96)));
}

// ---------- cat artwork ----------

/// The cat as a transparent sticker (no circle, no background).
class CatLogo extends StatelessWidget {
  final double size;
  const CatLogo({super.key, this.size = 56});
  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/cat.png', width: size, fit: BoxFit.contain);
}

/// The cat peeking over the top edge of a card (120 x 44).
class CatPeek extends StatelessWidget {
  const CatPeek({super.key});
  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 120, height: 44, child: CustomPaint(painter: _PeekPainter()));
}

class _PeekPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    c.scale(s.width / 120);
    final p = Path()
      ..moveTo(8, 44)
      ..lineTo(16, 4)
      ..lineTo(44, 24)
      ..quadraticBezierTo(60, 19, 76, 24)
      ..lineTo(104, 4)
      ..lineTo(112, 44)
      ..close();
    c.drawPath(p, Paint()..color = Colors.black);
    final e = Paint()
      ..color = C.eye
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    c.drawCircle(const Offset(42, 33), 6, e);
    c.drawCircle(const Offset(78, 33), 6, e);
  }

  @override
  bool shouldRepaint(CustomPainter old) => false;
}

/// The cat's belly, paws and tail hanging under a card (170 x 44).
class CatBody extends StatelessWidget {
  final bool mirror;
  const CatBody({super.key, this.mirror = false});
  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 170, height: 44, child: CustomPaint(painter: _BodyPainter(mirror)));
}

class _BodyPainter extends CustomPainter {
  final bool mirror;
  _BodyPainter(this.mirror);

  @override
  void paint(Canvas c, Size s) {
    if (mirror) {
      c.translate(s.width, 0);
      c.scale(-1, 1);
    }
    final black = Paint()..color = Colors.black;
    final belly = Path()
      ..moveTo(14, 0)
      ..cubicTo(14, 30, 34, 40, 61, 40)
      ..cubicTo(88, 40, 108, 30, 108, 0)
      ..close();
    c.drawPath(belly, black);
    c.drawOval(Rect.fromCenter(center: const Offset(40, 38), width: 24, height: 13), black);
    c.drawOval(Rect.fromCenter(center: const Offset(82, 38), width: 24, height: 13), black);
    final tail = Path()
      ..moveTo(104, 12)
      ..cubicTo(138, 26, 166, 22, 160, 3);
    c.drawPath(
        tail,
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _BodyPainter old) => old.mirror != mirror;
}

/// A card with the cat split around it: head above, belly and tail below.
class CatCard extends StatelessWidget {
  final Widget child;
  final bool left;
  const CatCard({super.key, required this.child, this.left = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 43, bottom: 44),
      child: Stack(clipBehavior: Clip.none, children: [
        child,
        Positioned(top: -43, left: left ? 30 : null, right: left ? null : 30, child: const CatPeek()),
        Positioned(bottom: -44, left: left ? 30 : null, right: left ? null : 29, child: CatBody(mirror: !left)),
      ]),
    );
  }
}

// ---------- moods ----------

class Mood {
  final String id, label, kind;
  final Color color;
  const Mood(this.id, this.label, this.color, this.kind);
}

const moodList = [
  Mood('great', 'Great', C.lime, 'big'),
  Mood('good', 'Good', C.ice, 'smile'),
  Mood('okay', 'Okay', C.white, 'flat'),
  Mood('tired', 'Tired', C.orange, 'sad'),
];

Mood? moodById(String? id) {
  for (final m in moodList) {
    if (m.id == id) return m;
  }
  return null;
}

class MoodFace extends StatelessWidget {
  final Mood mood;
  final double size;
  const MoodFace(this.mood, {super.key, this.size = 48});
  @override
  Widget build(BuildContext context) =>
      SizedBox(width: size, height: size, child: CustomPaint(painter: _FacePainter(mood)));
}

class _FacePainter extends CustomPainter {
  final Mood m;
  _FacePainter(this.m);

  @override
  void paint(Canvas c, Size s) {
    c.scale(s.width / 40);
    c.drawCircle(const Offset(20, 20), 20, Paint()..color = m.color);
    final dark = Paint()..color = C.green;
    c.drawCircle(const Offset(14, 16), 2.4, dark);
    c.drawCircle(const Offset(26, 16), 2.4, dark);
    final p = Path();
    switch (m.kind) {
      case 'big':
        p.moveTo(11, 23);
        p.quadraticBezierTo(20, 37, 29, 23);
        break;
      case 'smile':
        p.moveTo(12, 25);
        p.quadraticBezierTo(20, 33, 28, 25);
        break;
      case 'flat':
        p.moveTo(13, 27);
        p.lineTo(27, 27);
        break;
      default:
        p.moveTo(12, 30);
        p.quadraticBezierTo(20, 22, 28, 30);
    }
    c.drawPath(
        p,
        Paint()
          ..color = C.green
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _FacePainter old) => old.m != m;
}

class RuledPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = op(C.green, .13)
      ..strokeWidth = 1;
    for (double y = 30; y < s.height; y += 32) {
      c.drawLine(Offset(0, y), Offset(s.width, y), p);
    }
  }

  @override
  bool shouldRepaint(CustomPainter old) => false;
}

// ---------- building blocks ----------

class Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  const Glass(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(14),
      this.radius = 22});

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: op(C.white, .08),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: op(C.white, .14)),
        ),
        child: child,
      );
}

class CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? bg;
  final Color fg;
  final double size;
  final String label;
  const CircleBtn(this.icon,
      {super.key,
      this.onTap,
      this.bg,
      this.fg = C.white,
      this.size = 44,
      this.label = ''});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkResponse(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bg ?? op(C.white, .08),
            border: bg == null ? Border.all(color: op(C.white, .14)) : null,
          ),
          child: Icon(icon, color: fg, size: size * .5),
        ),
      ),
    );
  }
}

class GChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const GChip(this.label, {super.key, this.selected = false, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? C.lime : op(C.white, .10),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(label, style: txt(14, color: selected ? C.green : C.white, w: FontWeight.w700)),
        ),
      );
}

class PillBar extends StatelessWidget {
  final List<Widget> children;
  const PillBar({super.key, required this.children});

  @override
  Widget build(BuildContext context) => Container(
        height: 68,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        decoration: BoxDecoration(
          color: op(C.deep, .94),
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: op(C.white, .14)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: children),
      );
}

Widget dirText(String text, TextStyle style, {int? maxLines}) => Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      textDirection: _rtl(text) ? TextDirection.rtl : TextDirection.ltr,
    );

bool _rtl(String s) {
  for (final r in s.runes) {
    if ((r >= 0x0590 && r <= 0x08FF) || (r >= 0xFB1D && r <= 0xFDFF) || (r >= 0xFE70 && r <= 0xFEFF)) return true;
    if ((r >= 0x41 && r <= 0x5A) || (r >= 0x61 && r <= 0x7A)) return false;
  }
  return false;
}

void toast(BuildContext c, String m) {
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(m, style: txt(14, color: C.green, w: FontWeight.w700)),
      backgroundColor: C.lime,
      behavior: SnackBarBehavior.floating,
    ));
}

Future<bool> confirm(BuildContext c, String message, {String ok = 'Delete'}) async {
  final r = await showDialog<bool>(
    context: c,
    builder: (_) => AlertDialog(
      backgroundColor: C.deep,
      title: Text(message, style: txt(17, w: FontWeight.w700)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text('Cancel', style: txt(14, color: C.muted))),
        TextButton(onPressed: () => Navigator.pop(c, true), child: Text(ok, style: txt(14, color: C.orange, w: FontWeight.w700))),
      ],
    ),
  );
  return r ?? false;
}

Future<String?> askText(BuildContext c, String title, {String initial = '', String hint = ''}) async {
  final ctl = TextEditingController(text: initial);
  final r = await showDialog<String>(
    context: c,
    builder: (_) => AlertDialog(
      backgroundColor: C.deep,
      title: Text(title, style: txt(17, w: FontWeight.w700)),
      content: TextField(
        controller: ctl,
        autofocus: true,
        decoration: InputDecoration(hintText: hint),
        style: txt(16),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: Text('Cancel', style: txt(14, color: C.muted))),
        TextButton(onPressed: () => Navigator.pop(c, ctl.text.trim()), child: Text('OK', style: txt(14, color: C.lime, w: FontWeight.w700))),
      ],
    ),
  );
  ctl.dispose();
  return (r == null || r.isEmpty) ? null : r;
}

/// Loads data and reloads whenever [Repo.version] changes.
class LiveData<T> extends StatefulWidget {
  final Future<T> Function() loader;
  final Widget Function(BuildContext, T) builder;
  const LiveData({super.key, required this.loader, required this.builder});

  @override
  State<LiveData<T>> createState() => _LiveDataState<T>();
}

class _LiveDataState<T> extends State<LiveData<T>> {
  late Future<T> _f;

  @override
  void initState() {
    super.initState();
    _f = widget.loader();
    Repo.version.addListener(_reload);
  }

  void _reload() {
    if (mounted) setState(() => _f = widget.loader());
  }

  @override
  void dispose() {
    Repo.version.removeListener(_reload);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _f,
      builder: (context, snap) {
        if (snap.hasData) return widget.builder(context, snap.data as T);
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text("Couldn't load. Check your connection.", style: txt(15, color: C.muted), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                GChip('Retry', selected: true, onTap: _reload),
              ]),
            ),
          );
        }
        return const Center(child: CircularProgressIndicator(color: C.lime));
      },
    );
  }
}
