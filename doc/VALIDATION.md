# Validation and visual acceptance

## Alpha validation status

The alpha has passed local static analysis, widget tests, and an iOS simulator
build. Physical-device validation is pending.

| Gate | Status |
| --- | --- |
| API/reference research | Checked against current Apple and Flutter primary documentation |
| Dart/Swift contract | Reviewed at source level |
| Dart formatter / Flutter analyzer | Passed |
| Flutter widget/channel tests | 14 passed |
| Xcode compilation / iOS linking | iOS simulator debug build passed |
| CocoaPods / SwiftPM integration builds | CocoaPods simulator build passed; SwiftPM not verified |
| Native taps / VoiceOver / device graphics | Not run |
| Visual parity with a particular iOS reference | Not established; reference not supplied |
| Performance targets | Not measured |

Source inspection and a parseable pubspec are not substitutes for compiling
the plugin. Mocked method-channel tests do not run `UIGlassEffect` or UIKit.

## Build and test on your Mac

Use Flutter 3.47+ / Dart 3.13+, and select Xcode 26+ with the iOS 26 SDK.

From the package root:

```sh
flutter doctor -v
xcodebuild -version
xcrun --sdk iphoneos --show-sdk-version
flutter pub get
dart format lib test example/lib
flutter analyze
flutter test
bash tool/bootstrap_example.sh ios,android,web
cd example
flutter build ios --simulator --debug
flutter devices
flutter run -d YOUR_IOS_DEVICE_ID
```

If you already generated runners, skip bootstrap. It deliberately refuses to
overwrite existing runner directories. A physical-device build needs your
normal Apple development signing configuration. Do not hardcode a signing
team or certificates into the distributable plugin.

Build with the dependency manager used by your target app. Before publishing
support for both managers, also validate the example once with CocoaPods and
once with SwiftPM using Flutter's documented migration/configuration steps.
`Package.swift` relies on Flutter supplying its sibling `FlutterFramework`
package, so a standalone `swift build` in the plugin folder is not the intended
integration build.

For performance and final appearance, also run a profile or release build on
a physical device. Debug builds are useful for diagnostics, not final timing.

## What the automated tests cover

The included widget and channel tests exercise:

- Non-iOS routing and usable child controls.
- Forced fallback on iOS.
- A high-contrast fallback without blur.
- Enabled and disabled button callbacks.
- Accessible fallback button labels.
- Button layout growth at large text sizes.
- Native material configuration serialization through mocked channels.
- Property updates without deliberately recreating the platform view.
- Native callback routing to the latest Dart callback.
- Capability parsing, unsupported routing, and missing-registration errors.

They do not establish native optical rendering, gesture timing, UIKit
accessibility, Swift memory behavior, or frame rate.

## Visual reference protocol

For an “exact” comparison, collect a short screen recording of the intended
iOS component as well as a still image. Record the device, iOS version, light
or dark appearance, material settings, accessibility settings, text size,
control dimensions, and underlying background.

Compare against the same public UIKit control configured with the same values.
An arbitrary screenshot of Apple's Control Center may use app-specific
geometry and behavior; it is not automatically a specification for a generic
`UIGlassEffect` surface.

Do not tune a fixed opacity until one still image looks similar and assume the
effect is matched. Scroll the background, press the control, and compare the
transition. Native settings can deliberately alter transparency and animation.

| Scenario | Check |
| --- | --- |
| Light and dark appearance | Readable foreground, correct inherited appearance |
| Colorful image, checkerboard, fine text | Backdrop remains live; visible edge behavior |
| Scrolling content under fixed surface | No frozen texture, missing slices, or misalignment |
| Regular and clear surface | Material choice matches reference and retains contrast |
| Native regular and prominent button | Enabled, disabled, press, release, and cancellation states |
| Rapid rebuilds / resizing | Current tint/title/corners; no unintended view replacement |
| Button inside a scrollable | Tap works; scrolling/cancelled touches do not fire taps |
| RTL text and symbols | Direction, padding, and readable order |
| Large accessibility text | No clipped label or undersized target |
| Reduce Transparency / Increase Contrast | Native system adaptation and readable content |
| Reduce Motion | Native behavior respects setting; no plugin-generated perpetual motion |
| VoiceOver | Single understandable button with correct enabled state |
| Route transition / modal / keyboard | Correct z-order and backdrop through transitions |
| Native video/map behind or near glass | Composition checked for this exact combination |
| Navigate away and return repeatedly | No stale callbacks or growing native view count |
| Older iOS / Android / web | Fallback usable and labeled honestly |

## Performance acceptance

Use the host app's real screen and intended device range. Profile a small
number of glass controls, then the maximum number your UI actually needs.
Capture Flutter UI/raster timings and investigate native compositing as well;
a smooth Dart timeline alone does not prove the native compositor is cheap.
Do not advertise a frame-rate guarantee without recorded measurements.

## Publishing a release

1. Update the changelog and match the version in `pubspec.yaml` and
   `ios/ios_liquid_glass_effect.podspec`.
2. Remove `publish_to: none` from the root `pubspec.yaml`. Keep the opt-out in
   `example/pubspec.yaml` because the example is part of the plugin archive.
3. Run `flutter pub publish --dry-run` and review the files and validation output.
4. Run `flutter pub publish` and follow the Google account prompts. For a new
   package, publish the first version using an authorized account, then use the
   package’s **Admin** tab to transfer it to the `codemicros.com` publisher.

## Primary documentation

- [Flutter package development and testing](https://docs.flutter.dev/packages-and-plugins/developing-packages)
- [Dart package publishing and publisher transfers](https://dart.dev/tools/pub/publishing)
- [Flutter SwiftPM support for plugins](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-plugin-authors)
- [Flutter iOS platform views and limitations](https://docs.flutter.dev/platform-integration/ios/platform-views)
- [Apple material and accessibility guidance](https://developer.apple.com/design/human-interface-guidelines/materials)
