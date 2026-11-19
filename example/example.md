# Liquid Glass example

The Flutter web demo shows a glass card, clear surfaces, and buttons over
three backdrops. Choose **Colors**, **Grid**, or **Landscape** and scroll the
backdrop to see how the glass changes. These previews show the Flutter fallback.
Run the example on iOS 26 or later to see native UIKit Liquid Glass.

<img width="300" alt="Flutter web example showing glass cards and buttons over a colored backdrop" src="https://pub.dev/packages/ios_liquid_glass_effect/versions/0.1.0-alpha.1/gen-res/gen/doc/media/web-example.webp">
<img width="300" alt="Animated web example scrolling the backdrop and switching from Colors to Grid and Landscape" src="https://pub.dev/packages/ios_liquid_glass_effect/versions/0.1.0-alpha.1/gen-res/gen/doc/media/web-example-scroll.webp">

## Run the demo

The app’s entry point is `example/lib/main.dart`. If `example/web/` is missing,
run `bash tool/bootstrap_example.sh web` from the package root first.

```sh
cd example
flutter pub get
flutter run -d chrome
```
