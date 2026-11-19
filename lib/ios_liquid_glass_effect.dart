/// Genuine iOS Liquid Glass for Flutter, with a separate visual fallback.
///
/// iOS 26 or newer uses Apple's native APIs. Earlier iOS versions use native
/// fallback materials, and other Flutter platforms use a blur approximation.
/// Native material availability is not a guarantee that every mixed Flutter /
/// UIKit composition will match a system app; validate the actual screen on iOS.
library;

export 'src/glass_button.dart';
export 'src/glass_capabilities.dart';
export 'src/glass_style.dart';
export 'src/glass_surface.dart';
