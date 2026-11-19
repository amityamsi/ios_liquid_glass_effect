import 'package:flutter/material.dart';

enum ExampleScene {
  landscape('Photo', 'Glacial lake'),
  colors('Color', 'Color bands'),
  grid('Grid', 'Contrast grid');

  const ExampleScene(this.label, this.title);
  final String label;
  final String title;
}

/// Keeps the backdrop scrollable while the glass stays fixed above it.
class ExampleBackdrop extends StatelessWidget {
  const ExampleBackdrop({super.key, required this.scene});

  final ExampleScene scene;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        key: PageStorageKey(scene),
        primary: false,
        child: SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight + 245,
          child: switch (scene) {
            ExampleScene.landscape => Image.asset(
              'assets/glacial-lake.webp',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              excludeFromSemantics: true,
            ),
            ExampleScene.colors => const CustomPaint(painter: _ColorBands()),
            ExampleScene.grid => const CustomPaint(painter: _ContrastGrid()),
          },
        ),
      ),
    );
  }
}

class _ColorBands extends CustomPainter {
  const _ColorBands();

  @override
  void paint(Canvas canvas, Size size) {
    const colors = [
      Color(0xff465a89),
      Color(0xff357b79),
      Color(0xff6b527b),
      Color(0xff93594d),
    ];
    final paint = Paint();
    for (var i = 0; i * 92 < size.height; i++) {
      final y = i * 92.0;
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, 92),
        paint..color = colors[i % colors.length],
      );
      canvas.drawCircle(
        Offset(size.width * (i.isEven ? .28 : .72), y + 46),
        33,
        paint..color = const Color(0x73ffffff),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ColorBands oldDelegate) => false;
}

class _ContrastGrid extends CustomPainter {
  const _ContrastGrid();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xff27343b), BlendMode.src);
    final line = Paint()
      ..color = const Color(0xff546871)
      ..strokeWidth = .7;
    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    final text = TextPainter(
      text: const TextSpan(
        text: 'LIQUID GLASS   0123456789',
        style: TextStyle(
          color: Color(0xffa5c3c8),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 24);
    for (double y = 45; y < size.height; y += 96) {
      text.paint(canvas, Offset(12, y));
    }
    text.dispose();
  }

  @override
  bool shouldRepaint(covariant _ContrastGrid oldDelegate) => false;
}
