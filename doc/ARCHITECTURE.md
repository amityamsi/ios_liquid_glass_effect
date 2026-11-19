# Architecture

## Goal and fidelity contract

The iOS backend delegates rendering to public UIKit APIs. This is the route to
the actual Apple material on an eligible runtime. Rendering the same material
does not prove that the complete composition matches a reference screen. That
requires a matching control, background, geometry, OS/settings, and device
comparison.

The Flutter fallback uses a tinted backdrop with edge refraction when the
renderer supports shader filters. Other renderers use a backdrop blur.
Flutter paints and composites the fallback independently of UIKit.

## Component ownership

| Concern | GlassSurface on iOS | GlassButton on iOS | Flutter fallback |
| --- | --- | --- | --- |
| Material | UIKit effect | UIKit button configuration | Flutter refraction or backdrop blur |
| Text/icons | Flutter child | UIKit title and SF Symbol | Flutter |
| Touch target | Flutter child if interactive | UIKit button | Flutter TextButton |
| Native press appearance | Not provided | UIKit, subject to gesture delivery | Not provided |
| Semantics | Flutter child | Native UIKit semantics | Flutter semantics |
| Shape | Native corner configuration | Native capsule button | Flutter clip |
| Accessibility material adaptation | UIKit on iOS 26+ | UIKit on iOS 26+ | High-contrast solid treatment |

`GlassSurface` builds a stack: a positioned native platform view under an
independently clipped Flutter child. The native view is excluded from hit
testing and semantics. Its host is not rounded or faded in Flutter.

`GlassButton` embeds one complete native button. No Flutter-painted title or
GestureDetector overlays it. This preserves the correct ownership of native
control state; device validation must still confirm how Flutter's gesture
arena delivers press sequences in the surrounding app.

## Source layout

- `lib/ios_liquid_glass_effect.dart`: public exports.
- `lib/src/glass_surface.dart`: surface API and renderer selection.
- `lib/src/glass_button.dart`: button API and renderer selection.
- `lib/src/native_glass_view.dart`: per-view channel and lifecycle.
- `lib/src/glass_capabilities.dart`: capability snapshot and platform routing.
- `lib/src/fallback_surface.dart`: explicitly approximate Flutter material.
- `ios/ios_liquid_glass_effect/Sources/ios_liquid_glass_effect/IosLiquidGlassEffectPlugin.swift`:
  native registration, factories, views, availability checks, decoding.
- `ios/ios_liquid_glass_effect/Package.swift`: SwiftPM manifest.
- `ios/ios_liquid_glass_effect.podspec`: CocoaPods manifest using the same Swift file.

## Runtime selection

The Dart widgets use native views only when running on native iOS and
`forceFallback` is false. Web is excluded explicitly, including Safari on an
iPhone. No `dart:io` dependency is required for selection.

Once on iOS, Swift chooses the native material using `#available(iOS 26.0, *)`.
This avoids a pre-render capability query for every surface. Older iOS receives
a conventional material; `nativeGlassAvailable` remains false there.

`LiquidGlass.getCapabilities()` is a diagnostic snapshot. It does not decide
the widget backend, subscribe to native settings, measure a frame rate, or
certify that the material successfully sampled the app's backdrop.

## Channel contract

### Global channel

Channel: `ios_liquid_glass_effect/control`

Method: `getCapabilities`, no arguments.

| Reply key | Type | Meaning |
| --- | --- | --- |
| nativeGlassAvailable | bool | iOS 26+ API availability |
| systemVersion | string | Native iOS version |
| reduceTransparency | bool | Current iOS Reduce Transparency flag |
| reduceMotion | bool | Current iOS Reduce Motion flag |
| increaseContrast | bool | Current iOS darker-system-colors flag |

On non-iOS Dart returns an unsupported snapshot without invoking a native
channel. `systemVersion` is null there. False accessibility flags mean no iOS
query was made, not that the other platform's preferences are disabled.

### Platform views

- `ios_liquid_glass_effect/surface`
- `ios_liquid_glass_effect/button`

Creation uses `StandardMessageCodec`. Each native view owns a
`ios_liquid_glass_effect/view/<viewId>` method channel with `StandardMethodCodec`.

`update` sends a complete configuration map. The native side updates the
existing view and returns null. The Dart adapter coalesces pending updates and
resynchronizes after asynchronous view creation, covering rebuilds that happen
before `onPlatformViewCreated` runs.

| Surface key | Type |
| --- | --- |
| style | `regular` or `clear` |
| cornerRadius | double, nonnegative |
| tintColor | packed ARGB integer or null |
| brightness | `light` or `dark` |

| Button key | Type |
| --- | --- |
| label | string |
| systemImage | SF Symbol string or null |
| prominent | bool |
| enabled | bool |
| tintColor | packed ARGB integer or null |
| brightness | `light` or `dark` |
| accessibilityLabel | string or null |
| fontSize | double, already scaled by Flutter text settings |
| layoutDirection | `ltr` or `rtl`, from Flutter Directionality |

Native button `touchUpInside` sends `tap` with null arguments. Dart reads the
current callback rather than capturing the callback from initial creation.
When disabled, both native state and a null Dart callback prevent activation.

The Swift handler captures its owner weakly, and deinitialization unregisters
it. The Dart state also unregisters its incoming handler during disposal.
The plugin retains no global per-view map, screenshot cache, or timer.

## Backdrop composition

Flutter documents that iOS platform views use hybrid composition. A native
view participates in the UIKit hierarchy, making a native backdrop effect a
reasonable implementation route without a screenshot-copy loop.

This is an engineering basis, not a blanket guarantee for every combination
of Flutter clips, opacity layers, native videos, route transitions, or third-
party widgets. Verify the assembled app. Flutter's platform-view limitations
and UIKit's alpha/masking rules apply.

Keep the effect's ancestors opaque in the compositing sense (`alpha == 1`);
the glass material itself supplies transparency. Avoid redundant Flutter
rounded clips around the native view. The surface's Flutter child may be
clipped separately because that clip does not contain the native effect.

## Accessibility

Native iOS 26 materials use UIKit's system behavior. Older iOS fallbacks
observe Reduce Transparency changes and replace blur with a solid material.
The Flutter fallback responds to `MediaQuery.highContrast`; it does not query
every platform's transparency preferences. Forced Flutter fallback on iOS is
a comparison path, not an equivalent accessibility/material implementation.

Button text size comes from Flutter's `MediaQuery.textScaler`, so native and
Flutter typography share the app's scaling choice. Native automatic font
rescaling is disabled to avoid applying the scale twice. The widget reserves
extra line-height and insets; long labels and large accessibility sizes still
require layout checks. The native button owns its accessible label so no
duplicated Flutter semantics node is added around it.

## Extending this package

### Shared glass groups

Use one native platform view containing `UIGlassContainerEffect`, then manage
native child effect views inside its `contentView`. Send child geometry and
stable IDs from Dart. This enables UIKit to produce its combined effect.
Independent `UiKitView` instances cannot be assumed to merge automatically.

For arbitrary Flutter children, define ownership, clipping, transforms, focus,
and hit testing before introducing a group API. A convenient Dart wrapper
alone does not solve cross-renderer animation synchronization.

### Native navigation controls

A native tab bar, toolbar, slider, or switch should be its own native component
with a typed state/event contract. A generic glass surface cannot substitute
for the layout, state machine, accessibility, and motion of these controls.

### Cross-platform refraction

A future custom backend could use a signed-distance shape, normal-derived
backdrop displacement, an edge Fresnel highlight, blur, and contrast handling.
Its goal should be a tuned visual approximation. Apple's material should not
be described as an exposed shader that can be transferred to Android.

Flutter now documents `ImageFilter.shader` with an engine-provided input
sampler on supported Impeller backends. Check
`ImageFilter.isShaderFilterSupported` at runtime; this is not an unconditional
web/desktop solution. Do not use per-frame `RepaintBoundary.toImage()` readback
as the default architecture for live glass. No custom shader backend is
included in this alpha.

## Sources

- [Apple UIGlassEffect](https://developer.apple.com/documentation/uikit/uiglasseffect)
- [Apple native glass button](https://developer.apple.com/documentation/uikit/uibutton/configuration-swift.struct/glass())
- [Apple UIVisualEffectView composition rules](https://developer.apple.com/documentation/uikit/uivisualeffectview)
- [Apple combined glass effect](https://developer.apple.com/documentation/uikit/uiglasscontainereffect)
- [Flutter iOS platform views](https://docs.flutter.dev/platform-integration/ios/platform-views)
- [Flutter platform-view gesture recognition](https://api.flutter.dev/flutter/widgets/UiKitView/gestureRecognizers.html)
- [Flutter shader image filters](https://api.flutter.dev/flutter/dart-ui/ImageFilter/ImageFilter.shader.html)
