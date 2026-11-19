import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A snapshot of native material availability and iOS accessibility settings.
///
/// Re-query after returning to the app if displaying these values. UIKit
/// controls also respond to their native settings; this object is not a stream.
@immutable
class GlassCapabilities {
  const GlassCapabilities({
    required this.nativeGlassAvailable,
    required this.systemVersion,
    required this.reduceTransparency,
    required this.reduceMotion,
    required this.increaseContrast,
  });

  /// Whether this device exposes the iOS 26+ Liquid Glass APIs.
  ///
  /// This does not measure rendered fidelity, performance, or accessibility
  /// settings that may make glass deliberately appear less transparent.
  final bool nativeGlassAvailable;

  /// The native iOS version, or null when not running on native iOS.
  final String? systemVersion;

  /// The current iOS Reduce Transparency setting, or false off iOS.
  final bool reduceTransparency;

  /// The current iOS Reduce Motion setting, or false off iOS.
  final bool reduceMotion;

  /// The current iOS Increase Contrast setting, or false off iOS.
  final bool increaseContrast;

  /// No native iOS implementation is selected on the current platform.
  ///
  /// False accessibility flags here mean "not queried", not that a different
  /// platform's accessibility preferences are disabled.
  static const unsupported = GlassCapabilities(
    nativeGlassAvailable: false,
    systemVersion: null,
    reduceTransparency: false,
    reduceMotion: false,
    increaseContrast: false,
  );

  factory GlassCapabilities.fromMap(Map<Object?, Object?> map) {
    return GlassCapabilities(
      nativeGlassAvailable: map['nativeGlassAvailable'] == true,
      systemVersion: map['systemVersion'] as String?,
      reduceTransparency: map['reduceTransparency'] == true,
      reduceMotion: map['reduceMotion'] == true,
      increaseContrast: map['increaseContrast'] == true,
    );
  }
}

/// Access to the plugin's native capabilities.
abstract final class LiquidGlass {
  static const _channel = MethodChannel('ios_liquid_glass_effect/control');

  /// Queries the native implementation on iOS, without calling a channel on
  /// Android, desktop, or web (including a web browser running on iOS).
  ///
  /// Throws [FlutterError] if the iOS plugin has not been registered. A complete
  /// rebuild is required after adding a native plugin; hot reload is not enough.
  static Future<GlassCapabilities> getCapabilities() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return GlassCapabilities.unsupported;
    }
    try {
      final result = await _channel.invokeMapMethod<Object?, Object?>(
        'getCapabilities',
      );
      if (result == null) {
        throw FlutterError(
          'ios_liquid_glass_effect returned no capability information. '
          'Check that the Dart and native plugin versions match.',
        );
      }
      return GlassCapabilities.fromMap(result);
    } on MissingPluginException {
      throw FlutterError(
        'ios_liquid_glass_effect is not registered on iOS. Stop the app and perform '
        'a full iOS build with Xcode 26 or newer after adding the dependency. '
        'Check GeneratedPluginRegistrant registration in custom Flutter hosts.',
      );
    }
  }
}
