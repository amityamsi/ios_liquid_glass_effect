import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'fallback_surface.dart';
import 'glass_style.dart';
import 'native_glass_view.dart';

/// A passive glass material behind a regular Flutter [child].
///
/// On native iOS this hosts a UIVisualEffectView: Liquid Glass on iOS 26+, and
/// a native blur material on older iOS. Other platforms use a Flutter blur
/// approximation. The child remains Flutter-rendered; it is not reparented into
/// the UIKit effect's contentView and does not gain native vibrancy, native
/// button interactions, or native merging with neighboring surfaces.
///
/// Keep the host unclipped to preserve the native material's outer highlights.
/// The child itself is clipped to the requested rounded shape. Use a native
/// GlassButton when system button appearance and interaction are required.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.style = GlassStyle.regular,
    this.cornerRadius = 24,
    this.tintColor,
    this.padding = const EdgeInsets.all(16),
    this.forceFallback = false,
  }) : assert(cornerRadius >= 0 && cornerRadius < double.infinity);

  final Widget child;
  final GlassStyle style;
  final double cornerRadius;
  final Color? tintColor;
  final EdgeInsetsGeometry padding;

  /// Selects the Flutter approximation even on iOS. Useful for comparison.
  final bool forceFallback;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    final useNative =
        !forceFallback &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS;
    if (!useNative) {
      return FallbackSurface(
        cornerRadius: cornerRadius,
        style: style,
        tintColor: tintColor,
        child: content,
      );
    }
    final brightness =
        CupertinoTheme.maybeBrightnessOf(context) ?? Brightness.light;
    final tint = tintColor == null
        ? null
        : CupertinoDynamicColor.resolve(tintColor!, context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: NativeGlassView(
                viewType: 'ios_liquid_glass_effect/surface',
                configuration: <String, Object?>{
                  'style': style.name,
                  'cornerRadius': cornerRadius,
                  'tintColor': tint?.toARGB32(),
                  'brightness': brightness.name,
                },
              ),
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(cornerRadius),
          child: content,
        ),
      ],
    );
  }
}
