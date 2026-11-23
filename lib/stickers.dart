import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'theme.dart';

const stickerShapes = ['circle', 'rounded', 'heart', 'star', 'cat', 'flower', 'blob'];

/// Shape outlines in a 0..1 box.
Path shapePath(String shape) {
  final p = Path();
  switch (shape) {
    case 'rounded':
      p.addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 1, 1), const Radius.circular(.28)));
      break;
    case 'heart':
      p.moveTo(.5, .94);
      p.cubicTo(.08, .64, .0, .32, .22, .15);
      p.cubicTo(.36, .04, .50, .12, .5, .27);
      p.cubicTo(.50, .12, .64, .04, .78, .15);
      p.cubicTo(1.0, .32, .92, .64, .5, .94);
      p.close();
      break;
    case 'star':
      for (var i = 0; i < 10; i++) {
        final r = i.isEven ? .5 : .23;
        final a = -pi / 2 + i * pi / 5;
        final x = .5 + r * cos(a);
        final y = .5 + r * sin(a);
        if (i == 0) {
          p.moveTo(x, y);
        } else {
          p.lineTo(x, y);
        }
      }
      p.close();
      break;
    case 'cat':
      p.moveTo(.048, 0);
      p.lineTo(.333, .209);
      p.quadraticBezierTo(.5, .174, .667, .209);
      p.lineTo(.952, 0);
      p.lineTo(1.0, .512);
      p.quadraticBezierTo(1.0, .977, .5, 1.0);
      p.quadraticBezierTo(0.0, .977, 0.0, .512);
      p.close();
      break;
    case 'flower':
      for (var i = 0; i < 8; i++) {
        final a = i * pi / 4;
        p.addOval(Rect.fromCircle(center: Offset(.5 + .30 * cos(a), .5 + .30 * sin(a)), radius: .2));
      }
      p.addOval(Rect.fromCircle(center: const Offset(.5, .5), radius: .3));
      break;
    case 'blob':
      p.moveTo(.5, .05);
      p.cubicTo(.8, .0, .98, .25, .95, .5);
      p.cubicTo(.92, .78, .72, .98, .45, .95);
      p.cubicTo(.18, .92, .02, .72, .05, .45);
      p.cubicTo(.08, .2, .25, .1, .5, .05);
      p.close();
      break;
    default:
      p.addOval(const Rect.fromLTWH(0, 0, 1, 1));
  }
  return p;
}

class _ShapeClipper extends CustomClipper<Path> {
  final String shape;
  const _ShapeClipper(this.shape);

  @override
  Path getClip(Size size) =>
      shapePath(shape).transform(Matrix4.diagonal3Values(size.width, size.height, 1).storage);

  @override
  bool shouldReclip(covariant _ShapeClipper old) => old.shape != shape;
}

/// A photo cut into a sticker shape with a white outline.
class StickerView extends StatelessWidget {
  final String path, shape;
  final double size;
  const StickerView({super.key, required this.path, required this.shape, this.size = 84});

  @override
  Widget build(BuildContext context) {
    final inner = size * .86;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        ClipPath(
          clipper: _ShapeClipper(shape),
          child: Container(width: size, height: size, color: Colors.white),
        ),
        ClipPath(
          clipper: _ShapeClipper(shape),
          child: SizedBox(
            width: inner,
            height: inner,
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: C.mint,
                child: const Icon(Icons.broken_image_outlined, color: C.green),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
