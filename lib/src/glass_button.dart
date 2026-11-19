import 'dart:math' as math;

import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoDynamicColor, CupertinoTheme;
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'fallback_surface.dart';
import 'glass_style.dart';
import 'native_glass_view.dart';

/// A complete native UIButton on iOS, with a Flutter button elsewhere.
///
/// On iOS 26+, UIKit's glass / prominentGlass configuration owns the material,
/// title, SF Symbol, accessibility, and interaction. Earlier iOS uses a native
/// fallback. For exact system button rendering, prefer this API over placing
/// a Flutter button on a GlassSurface.
///
/// [systemImage] is an SF Symbol name used only on iOS. Supply [fallbackIcon]
/// separately for Flutter fallback platforms; symbols are not translated.
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.systemImage,
    this.fallbackIcon,
    this.prominent = false,
    this.width = 180,
    this.height = 52,
    this.tintColor,
    this.accessibilityLabel,
    this.forceFallback = false,
  }) : assert(width > 0 && width < double.infinity),
       assert(height >= 44 && height < double.infinity);

  final String label;

  /// A null callback disables both native and fallback buttons.
  final VoidCallback? onPressed;
  final String? systemImage;
  final IconData? fallbackIcon;
  final bool prominent;
  final double width;

  /// Minimum height; increases to accommodate the current text scaling.
  final double height;
  final Color? tintColor;
  final String? accessibilityLabel;
  final bool forceFallback;

  @override
  Widget build(BuildContext context) {
    final brightness =
        CupertinoTheme.maybeBrightnessOf(context) ?? Brightness.light;
    final tint = tintColor == null
        ? null
        : CupertinoDynamicColor.resolve(tintColor!, context);
    final textScaler =
        MediaQuery.maybeOf(context)?.textScaler ?? TextScaler.noScaling;
    final fontSize = textScaler.scale(17);
    // Reserve line-height as well as vertical insets at large accessibility
    // sizes; point size alone is smaller than a rendered font's line box.
    final effectiveHeight = math.max(height, fontSize * 1.4 + 24);
    final useNative =
        !forceFallback &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS;
    if (useNative) {
      return SizedBox(
        width: width,
        height: effectiveHeight,
        child: NativeGlassView(
          viewType: 'ios_liquid_glass_effect/button',
          configuration: <String, Object?>{
            'label': label,
            'systemImage': systemImage,
            'prominent': prominent,
            'enabled': onPressed != null,
            'tintColor': tint?.toARGB32(),
            'brightness': brightness.name,
            'accessibilityLabel': accessibilityLabel,
            'fontSize': fontSize,
            'layoutDirection': Directionality.of(context).name,
          },
          onTap: onPressed,
        ),
      );
    }
    final dark = brightness == Brightness.dark;
    final foreground = dark ? const Color(0xfff8f8f8) : const Color(0xff171717);
    final button = TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: foreground,
        disabledForegroundColor: foreground.withValues(alpha: 0.45),
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: const StadiumBorder(),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        alignment: Alignment.center,
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (fallbackIcon != null) ...[
            ExcludeSemantics(child: Icon(fallbackIcon, size: 20)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              semanticsLabel: accessibilityLabel,
            ),
          ),
        ],
      ),
    );
    return SizedBox(
      width: width,
      height: effectiveHeight,
      child: FallbackSurface(
        cornerRadius: effectiveHeight / 2,
        style: prominent ? GlassStyle.regular : GlassStyle.clear,
        magnification: 1.15,
        tintColor: tint,
        child: Material.maybeOf(context) == null
            ? Material(type: MaterialType.transparency, child: button)
            : button,
      ),
    );
  }
}
