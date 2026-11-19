import 'package:flutter/material.dart';

enum ExampleScene {
  colors('Colors'),
  grid('Grid'),
  landscape('Landscape');

  const ExampleScene(this.label);
  final String label;
}

/// Scrollable backgrounds make it easy to see the material change in motion.
class ExampleBackdrop extends StatelessWidget {
  const ExampleBackdrop({super.key, required this.scene});

  final ExampleScene scene;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: ValueKey(scene),
      child: CustomPaint(
        painter: _ScenePainter(scene),
        child: const SizedBox(width: double.infinity, height: 1100),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  const _ScenePainter(this.scene);
  final ExampleScene scene;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    switch (scene) {
      case ExampleScene.colors:
        const colors = [
          Color(0xffec806d),
          Color(0xffe9bc69),
          Color(0xff78bda6),
          Color(0xff7a9fda),
          Color(0xffaa8bc9),
        ];
        for (var i = 0; i < 11; i++) {
          final y = i * 100.0;
          canvas.drawRect(
            Rect.fromLTWH(0, y, size.width, 100),
            Paint()..color = colors[i % colors.length],
          );
          canvas.drawCircle(
            Offset(size.width * (i.isEven ? .24 : .76), y + 50),
            36,
            Paint()..color = Colors.white.withValues(alpha: .5),
          );
        }
      case ExampleScene.grid:
        canvas.drawRect(bounds, Paint()..color = const Color(0xffe6e9ed));
        final line = Paint()
          ..color = const Color(0xffa1aebd)
          ..strokeWidth = .7;
        for (double x = 0; x < size.width; x += 24) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
        }
        for (double y = 0; y < size.height; y += 24) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
        }
        for (double y = 58; y < size.height; y += 144) {
          final text = TextPainter(
            text: const TextSpan(
              text: 'Liquid glass 0123456789',
              style: TextStyle(
                color: Color(0xff273545),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: size.width);
          text.paint(canvas, Offset(12, y));
        }
      case ExampleScene.landscape:
        canvas.drawRect(
          bounds,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xffa8c8de),
                Color(0xfff2cbb4),
                Color(0xff598a84),
                Color(0xff263e58),
              ],
            ).createShader(bounds),
        );
        for (var i = 0; i < 8; i++) {
          final y = 100.0 + i * 150;
          final path = Path()
            ..moveTo(0, y + 65)
            ..quadraticBezierTo(
              size.width * .32,
              y - 75,
              size.width * .6,
              y + 30,
            )
            ..quadraticBezierTo(size.width * .8, y + 85, size.width, y - 20)
            ..lineTo(size.width, y + 110)
            ..lineTo(0, y + 110)
            ..close();
          canvas.drawPath(
            path,
            Paint()
              ..color =
                  (i.isEven ? const Color(0xff426f72) : const Color(0xffe8d5c3))
                      .withValues(alpha: .45),
          );
        }
    }
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) =>
      oldDelegate.scene != scene;
}
