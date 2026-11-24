import 'package:flutter/material.dart';
import 'theme.dart';

/// A card with a cat lying on its side, saying a word.
class LyingCatCard extends StatelessWidget {
  final String word;
  final VoidCallback? onTap;
  const LyingCatCard({super.key, required this.word, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 172,
        decoration: const BoxDecoration(
          color: C.lime,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
            bottomRight: Radius.circular(28),
            bottomLeft: Radius.circular(8),
          ),
        ),
        child: Stack(children: [
          Positioned(
            left: 20,
            bottom: 14,
            child: SizedBox(width: 240, height: 112, child: CustomPaint(painter: _LyingCatPainter())),
          ),
          Positioned(
            left: 100,
            top: 20,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Column(
                key: ValueKey(word),
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(color: C.white, borderRadius: BorderRadius.circular(18)),
                    child: Text(word, style: disp(24, color: C.green)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 18),
                    child: CustomPaint(size: const Size(16, 10), painter: _TipPainter()),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _TipPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Path()
      ..moveTo(0, 0)
      ..lineTo(s.width, 0)
      ..lineTo(s.width * .3, s.height)
      ..close();
    c.drawPath(p, Paint()..color = C.white);
  }

  @override
  bool shouldRepaint(CustomPainter old) => false;
}

class _LyingCatPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final black = Paint()..color = Colors.black;
    // tail
    final tail = Path()
      ..moveTo(206, 84)
      ..cubicTo(236, 88, 240, 58, 224, 46);
    c.drawPath(
        tail,
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 11
          ..strokeCap = StrokeCap.round);
    // body
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(50, 44, 218, 104), const Radius.circular(30)), black);
    // paws
    c.drawOval(Rect.fromCenter(center: const Offset(100, 104), width: 32, height: 13), black);
    c.drawOval(Rect.fromCenter(center: const Offset(138, 106), width: 28, height: 12), black);
    // head, slightly tilted
    c.save();
    c.translate(52, 66);
    c.rotate(-0.17);
    c.translate(-52, -66);
    c.drawCircle(const Offset(52, 66), 38, black);
    c.drawPath(
        Path()
          ..moveTo(20, 50)
          ..lineTo(24, 14)
          ..lineTo(50, 32)
          ..close(),
        black);
    c.drawPath(
        Path()
          ..moveTo(84, 50)
          ..lineTo(80, 14)
          ..lineTo(54, 32)
          ..close(),
        black);
    final eye = Paint()
      ..color = C.eye
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    c.drawCircle(const Offset(40, 64), 8, eye);
    c.drawCircle(const Offset(66, 64), 8, eye);
    c.restore();
  }

  @override
  bool shouldRepaint(CustomPainter old) => false;
}
