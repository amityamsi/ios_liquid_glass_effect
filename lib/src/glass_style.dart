/// Apple's public glass material variants for `GlassSurface`.
///
/// The fallback approximates the variants; it does not reproduce Apple's
/// optical rendering. Native buttons use UIKit's button configurations instead.
enum GlassStyle {
  /// The default adaptable material, intended to keep controls readable.
  regular,

  /// A more transparent material, best used over visually rich backgrounds.
  clear,
}
