import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Internal native view adapter. Keeps the platform view stable across updates.
class NativeGlassView extends StatefulWidget {
  const NativeGlassView({
    super.key,
    required this.viewType,
    required this.configuration,
    this.onTap,
  });

  final String viewType;
  final Map<String, Object?> configuration;
  final VoidCallback? onTap;

  @override
  State<NativeGlassView> createState() => _NativeGlassViewState();
}

class _NativeGlassViewState extends State<NativeGlassView> {
  MethodChannel? _channel;
  Map<String, Object?>? _pendingConfiguration;
  bool _updating = false;

  @override
  void didUpdateWidget(covariant NativeGlassView oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(oldWidget.viewType == widget.viewType);
    if (!mapEquals(oldWidget.configuration, widget.configuration)) {
      _queueUpdate();
    }
  }

  void _onPlatformViewCreated(int viewId) {
    if (!mounted) return;
    _channel = MethodChannel('ios_liquid_glass_effect/view/$viewId');
    _channel!.setMethodCallHandler((call) async {
      if (call.method == 'tap' && mounted) {
        // Read the latest widget rather than capturing an obsolete callback.
        widget.onTap?.call();
      }
    });
    // A rebuild can happen while the native view is being created. Always
    // synchronize the latest configuration when creation finishes.
    _queueUpdate();
  }

  void _queueUpdate() {
    _pendingConfiguration = Map<String, Object?>.of(widget.configuration);
    if (_channel != null && !_updating) {
      unawaited(_flushUpdates());
    }
  }

  Future<void> _flushUpdates() async {
    _updating = true;
    try {
      while (mounted && _channel != null && _pendingConfiguration != null) {
        final configuration = _pendingConfiguration!;
        _pendingConfiguration = null;
        await _channel!.invokeMethod<void>('update', configuration);
      }
    } catch (error, stackTrace) {
      // Report asynchronous platform failures through Flutter's error handler
      // rather than losing them as unhandled Future errors or hiding them.
      if (mounted) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: FlutterError(
              'ios_liquid_glass_effect could not update its native view: $error. '
              'Verify native plugin registration and rebuild the iOS app.',
            ),
            stack: stackTrace,
            library: 'ios_liquid_glass_effect',
            context: ErrorDescription('while updating a native glass view'),
          ),
        );
      }
      _pendingConfiguration = null;
    } finally {
      _updating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return UiKitView(
      viewType: widget.viewType,
      layoutDirection: Directionality.of(context),
      creationParams: widget.configuration,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onPlatformViewCreated,
      // Keep normal platform-view gesture arbitration so a button does not
      // greedily consume every drag that begins inside a Flutter scroll view.
    );
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    _channel = null;
    _pendingConfiguration = null;
    super.dispose();
  }
}
