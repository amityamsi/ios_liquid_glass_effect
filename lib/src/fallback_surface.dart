import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';

import 'glass_style.dart';

/// Internal Flutter approximation. It deliberately makes no native-fidelity claim.
class FallbackSurface extends StatefulWidget {
  const FallbackSurface({
    super.key,
    required this.child,
    required this.cornerRadius,
    required this.style,
    this.tintColor,
    this.magnification = 1,
  });

  final Widget child;
  final double cornerRadius;
  final GlassStyle style;
  final Color? tintColor;
  final double magnification;

  @override
  State<FallbackSurface> createState() => _FallbackSurfaceState();
}

class _FallbackSurfaceState extends State<FallbackSurface> {
  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    if (ui.ImageFilter.isShaderFilterSupported) _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'packages/ios_liquid_glass_effect/shaders/glass_refraction.frag',
      );
      final shader = program.fragmentShader();
      if (!mounted) {
        shader.dispose();
        return;
      }
      setState(() => _shader = shader);
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'ios_liquid_glass_effect',
          context: ErrorDescription(
            'while loading the glass refraction shader',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cornerRadius = widget.cornerRadius;
    final style = widget.style;
    final tintColor = widget.tintColor;
    final magnification = widget.magnification;
    final child = widget.child;
    final brightness =
        CupertinoTheme.maybeBrightnessOf(context) ?? Brightness.light;
    final dark = brightness == Brightness.dark;
    final highContrast = MediaQuery.maybeOf(context)?.highContrast ?? false;
    final tint = tintColor == null
        ? null
        : CupertinoDynamicColor.resolve(tintColor, context);
    final baseColor = dark ? const Color(0xff242424) : const Color(0xfff4f4f4);
    final fill = highContrast
        ? baseColor
        : Color.alphaBlend(
            (tint ?? baseColor).withValues(
              alpha: tint == null ? 0 : tint.a * 0.16,
            ),
            baseColor.withValues(
              alpha: style == GlassStyle.regular ? 0.66 : 0.12,
            ),
          );
    final body = DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(cornerRadius),
        border: highContrast
            ? Border.all(
                color: dark ? const Color(0xffeeeeee) : const Color(0xff333333),
                width: 1.5,
              )
            : null,
      ),
      child: child,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(cornerRadius),
      child: highContrast
          ? body
          : Stack(
              fit: StackFit.passthrough,
              children: [
                if (magnification != 1)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: LayoutBuilder(
                        builder: (context, constraints) => RawMagnifier(
                          size: constraints.biggest,
                          magnificationScale: magnification,
                        ),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final shader = _shader;
                      final shortest = constraints.biggest.shortestSide;
                      if (shader != null && shortest > 0 && shortest.isFinite) {
                        shader.setFloat(
                          2,
                          (cornerRadius / shortest).clamp(0, 0.5),
                        );
                      }
                      return BackdropFilter(
                        filter:
                            shader != null && shortest > 0 && shortest.isFinite
                            ? ui.ImageFilter.shader(shader)
                            : ui.ImageFilter.blur(
                                sigmaX: style == GlassStyle.regular ? 20 : 4,
                                sigmaY: style == GlassStyle.regular ? 20 : 4,
                              ),
                        child: const SizedBox.expand(),
                      );
                    },
                  ),
                ),
                body,
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _GlassRimPainter(cornerRadius, dark),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// A shaded inner rim suggests the thickness of the glass at its edges.
class _GlassRimPainter extends CustomPainter {
  const _GlassRimPainter(this.radius, this.dark);

  final double radius;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final bounds = Offset.zero & size;
    final r = radius.clamp(0.0, size.shortestSide / 2);
    final outer = RRect.fromRectAndRadius(bounds, Radius.circular(r));
    final thickness = (size.shortestSide * 0.075).clamp(0.0, 4.0);
    final inner = RRect.fromRectAndRadius(
      bounds.deflate(thickness),
      Radius.circular((r - thickness).clamp(0.0, r)),
    );
    final rim = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0x38ffffff),
          const Color(0x08ffffff),
          dark ? const Color(0x25000000) : const Color(0x14000000),
          const Color(0x35ffffff),
        ],
        stops: const [0, 0.38, 0.72, 1],
      ).createShader(bounds);
    canvas.drawDRRect(outer, inner, rim);

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x60ffffff), Color(0x08ffffff), Color(0x40ffffff)],
      ).createShader(bounds);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds.deflate(0.5), Radius.circular(r)),
      outline,
    );
  }

  @override
  bool shouldRepaint(covariant _GlassRimPainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.dark != dark;
}
