import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ios_liquid_glass_effect/ios_liquid_glass_effect.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  Widget host(Widget child, {bool highContrast = false}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(highContrast: highContrast),
        child: Scaffold(body: Center(child: child)),
      ),
    );
  }

  testWidgets('non-iOS surface stays in Flutter and preserves child input', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    var taps = 0;
    await tester.pumpWidget(
      host(
        GlassSurface(
          child: TextButton(
            onPressed: () => taps++,
            child: const Text('Child control'),
          ),
        ),
      ),
    );
    expect(find.byType(UiKitView), findsNothing);
    expect(find.byType(BackdropFilter), findsOneWidget);
    await tester.tap(find.text('Child control'));
    expect(taps, 1);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('forceFallback skips iOS platform views', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await tester.pumpWidget(
      host(
        const GlassSurface(
          forceFallback: true,
          child: Text('Flutter fallback'),
        ),
      ),
    );
    expect(find.byType(UiKitView), findsNothing);
    expect(find.byType(BackdropFilter), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('high contrast fallback removes backdrop blur', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.pumpWidget(
      host(const GlassSurface(child: Text('Readable')), highContrast: true),
    );
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.text('Readable'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('fallback button enables input only with a callback', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    var taps = 0;
    await tester.pumpWidget(
      host(GlassButton(label: 'Continue', onPressed: () => taps++)),
    );
    await tester.tap(find.text('Continue'));
    expect(taps, 1);
    await tester.pumpWidget(
      host(const GlassButton(label: 'Continue', onPressed: null)),
    );
    final button = tester.widget<TextButton>(find.byType(TextButton));
    expect(button.onPressed, isNull);
    await tester.tap(find.text('Continue'));
    expect(taps, 1);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('fallback button magnifies the backdrop', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.pumpWidget(
      host(GlassButton(label: 'Continue', onPressed: () {})),
    );
    expect(
      tester.widget<RawMagnifier>(find.byType(RawMagnifier)).magnificationScale,
      1.15,
    );

    await tester.pumpWidget(
      host(
        GlassButton(label: 'Continue', onPressed: () {}),
        highContrast: true,
      ),
    );
    expect(find.byType(RawMagnifier), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('fallback button centers its icon and label', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.pumpWidget(
      host(
        GlassButton(
          label: 'Continue',
          fallbackIcon: Icons.arrow_forward,
          onPressed: () {},
        ),
      ),
    );
    final button = find.byType(GlassButton);
    final row = find.descendant(of: button, matching: find.byType(Row));
    expect(tester.getCenter(row).dy, closeTo(tester.getCenter(button).dy, 0.1));
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('fallback button supplies its accessibility label', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        GlassButton(
          label: 'Save',
          accessibilityLabel: 'Save this item',
          fallbackIcon: Icons.bookmark_border,
          onPressed: () {},
        ),
      ),
    );
    expect(find.bySemanticsLabel('Save this item'), findsOneWidget);
    semantics.dispose();
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('button height accommodates text scaling', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(3)),
          child: Center(child: GlassButton(label: 'Save', onPressed: null)),
        ),
      ),
    );
    expect(tester.getSize(find.byType(GlassButton)).height, greaterThan(52));
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  group('native view contract (mocked, not an iOS rendering test)', () {
    final channels = <String>[];
    final created = <Map<Object?, Object?>>[];
    final updates = <Map<Object?, Object?>>[];
    late TestDefaultBinaryMessenger messenger;

    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      created.clear();
      updates.clear();
      channels.clear();
      messenger.setMockMethodCallHandler(SystemChannels.platform_views, (
        call,
      ) async {
        if (call.method == 'create') {
          final arguments = call.arguments as Map<Object?, Object?>;
          created.add(arguments);
          final name = 'ios_liquid_glass_effect/view/${arguments['id']}';
          channels.add(name);
          messenger.setMockMethodCallHandler(MethodChannel(name), (call) async {
            if (call.method == 'update') {
              updates.add(call.arguments as Map<Object?, Object?>);
            }
            return null;
          });
        }
        return null;
      });
    });

    tearDown(() {
      messenger.setMockMethodCallHandler(SystemChannels.platform_views, null);
      for (final name in channels) {
        messenger.setMockMethodCallHandler(MethodChannel(name), null);
      }
    });

    Future<void> nativeTap() async {
      final response = Completer<void>();
      await messenger.handlePlatformMessage(
        channels.single,
        const StandardMethodCodec().encodeMethodCall(const MethodCall('tap')),
        (_) => response.complete(),
      );
      await response.future;
    }

    testWidgets('surface serializes its complete material configuration', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const GlassSurface(
            style: GlassStyle.clear,
            cornerRadius: 31,
            tintColor: Color(0xffe65b36),
            child: SizedBox(width: 120, height: 48),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(created, hasLength(1));
      expect(created.single['viewType'], 'ios_liquid_glass_effect/surface');
      expect(updates.last, <String, Object?>{
        'style': 'clear',
        'cornerRadius': 31.0,
        'tintColor': 0xffe65b36,
        'brightness': 'light',
      });
      expect(
        find.ancestor(
          of: find.byType(UiKitView),
          matching: find.byType(IgnorePointer),
        ),
        findsWidgets,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets(
      'rebuild updates in place and native taps use latest callback',
      (tester) async {
        var firstTaps = 0;
        var secondTaps = 0;
        await tester.pumpWidget(
          host(
            GlassButton(
              label: 'First',
              systemImage: 'plus',
              onPressed: () => firstTaps++,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(created, hasLength(1));
        await nativeTap();
        expect(firstTaps, 1);

        await tester.pumpWidget(
          host(
            GlassButton(
              label: 'Second',
              prominent: true,
              systemImage: 'checkmark',
              onPressed: () => secondTaps++,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(created, hasLength(1));
        expect(updates.last['label'], 'Second');
        expect(updates.last['prominent'], true);
        expect(updates.last['systemImage'], 'checkmark');
        await nativeTap();
        expect(firstTaps, 1);
        expect(secondTaps, 1);

        await tester.pumpWidget(
          host(const GlassButton(label: 'Disabled', onPressed: null)),
        );
        await tester.pumpAndSettle();
        expect(updates.last['enabled'], false);
        await nativeTap();
        expect(secondTaps, 1);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        debugDefaultTargetPlatformOverride = null;
      },
    );
  }, skip: kIsWeb);
}
