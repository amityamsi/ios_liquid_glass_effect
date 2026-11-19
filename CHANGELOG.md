# Changelog

## 0.1.0-alpha.3

- Migrated to `cupertino_ui` and `material_ui` to fix deprecated imports on Flutter 3.50.
- Raised the minimum SDK versions to Flutter 3.47 and Dart 3.13. Use the standalone `cupertino_ui` types for Cupertino theme overrides and dynamic tints.

## 0.1.0-alpha.2

- Fixed the screenshot and animated demo links in the README and pub.dev Example tab.

## 0.1.0-alpha.1

- Added `GlassSurface` with regular and clear UIKit Liquid Glass on iOS 26 and later.
- Added `GlassButton` with standard and prominent styles, SF Symbols, and a Dart press callback.
- Added conventional UIKit materials on older iOS versions and Flutter effects on other platforms.
- Added `LiquidGlass.getCapabilities()` for native availability and iOS accessibility settings.
- Included CocoaPods and Swift Package Manager manifests, an interactive example, and integration guides.
- Added the Glass Studio example gallery with adjustable material, light and dark previews, and an animated walkthrough.
- Verified the release with Flutter analysis, 14 tests, and an iOS simulator build using CocoaPods.
