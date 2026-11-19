import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ios_liquid_glass_effect/ios_liquid_glass_effect.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('ios_liquid_glass_effect/control');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('non-iOS capability query does not invoke a native channel', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls++;
      return null;
    });
    final capabilities = await LiquidGlass.getCapabilities();
    expect(capabilities.nativeGlassAvailable, false);
    expect(capabilities.systemVersion, isNull);
    expect(calls, 0);
  });

  test('native availability and accessibility are independent flags', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getCapabilities');
      return <String, Object?>{
        'nativeGlassAvailable': true,
        'systemVersion': '26.0',
        'reduceTransparency': true,
        'reduceMotion': true,
        'increaseContrast': false,
      };
    });
    final capabilities = await LiquidGlass.getCapabilities();
    expect(capabilities.nativeGlassAvailable, true);
    expect(capabilities.systemVersion, '26.0');
    expect(capabilities.reduceTransparency, true);
    expect(capabilities.reduceMotion, true);
    expect(capabilities.increaseContrast, false);
  }, skip: kIsWeb);

  test('null capability response reports a setup error', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    messenger.setMockMethodCallHandler(channel, (_) async => null);
    expect(
      LiquidGlass.getCapabilities(),
      throwsA(
        isA<FlutterError>().having(
          (error) => error.toString(),
          'message',
          contains('capability information'),
        ),
      ),
    );
  }, skip: kIsWeb);

  test('missing iOS plugin reports registration failure', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    messenger.setMockMethodCallHandler(channel, null);
    expect(
      LiquidGlass.getCapabilities(),
      throwsA(
        isA<FlutterError>().having(
          (error) => error.toString(),
          'message',
          contains('not registered on iOS'),
        ),
      ),
    );
  }, skip: kIsWeb);
}
