import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoTheme, CupertinoThemeData;
import 'package:flutter/foundation.dart';
import 'package:ios_liquid_glass_effect/ios_liquid_glass_effect.dart';
import 'package:material_ui/material_ui.dart';

import 'scene.dart';

void main() => runApp(const GlassExample());

class GlassExample extends StatefulWidget {
  const GlassExample({super.key});

  @override
  State<GlassExample> createState() => _GlassExampleState();
}

enum _DemoSection {
  surfaces('Surfaces', Icons.layers_outlined),
  buttons('Buttons', Icons.touch_app_outlined),
  renderer('Renderer', Icons.tune_rounded);

  const _DemoSection(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _GlassExampleState extends State<GlassExample> {
  _DemoSection _section = _DemoSection.surfaces;
  ExampleScene _scene = ExampleScene.landscape;
  bool _dark = true;
  bool _clear = false;
  bool _forceFallback = false;
  bool _favorite = false;
  double _tintStrength = 0;
  int _likes = 0;

  late final Future<GlassCapabilities> _capabilities =
      LiquidGlass.getCapabilities();

  static ThemeData _theme(Brightness brightness) {
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xff318c8d),
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: colors,
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? const Color(0xff101518)
          : const Color(0xfff1f5f4),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glass Studio by CodeMicros',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Builder(builder: _buildGallery),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGallery(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final content = switch (_section) {
      _DemoSection.surfaces => _surfaces(context),
      _DemoSection.buttons => _buttons(context),
      _DemoSection.renderer => _renderer(context),
    };
    return Stack(
      children: [
        ListView(
          key: PageStorageKey(_section),
          padding: EdgeInsets.fromLTRB(20, 14, 20, 112 + bottomInset),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CodeMicros',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Glass Studio',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: _dark
                      ? 'Use light appearance'
                      : 'Use dark appearance',
                  onPressed: () => setState(() => _dark = !_dark),
                  icon: Icon(
                    _dark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 23),
            ...content,
          ],
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 14 + bottomInset,
          child: _DemoDock(
            selected: _section,
            forceFallback: _forceFallback,
            onSelected: (section) => setState(() => _section = section),
          ),
        ),
      ],
    );
  }

  Color? _tint(ColorScheme colors) => _tintStrength == 0
      ? null
      : colors.primary.withValues(alpha: _tintStrength);

  List<Widget> _surfaces(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return [
      Text('Backdrop', style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final scene in ExampleScene.values)
            ChoiceChip(
              label: Text(scene.label),
              selected: _scene == scene,
              showCheckmark: false,
              shape: const StadiumBorder(),
              onSelected: (_) => setState(() => _scene = scene),
            ),
        ],
      ),
      const SizedBox(height: 12),
      _BackdropStage(
        scene: _scene,
        overlays: [
          PositionedDirectional(
            top: 14,
            end: 14,
            child: GlassSurface(
              style: GlassStyle.clear,
              cornerRadius: 25,
              padding: EdgeInsets.zero,
              forceFallback: _forceFallback,
              child: IconButton(
                tooltip: _favorite ? 'Remove favorite' : 'Add favorite',
                color: Colors.white,
                onPressed: () => setState(() => _favorite = !_favorite),
                icon: Icon(_favorite ? Icons.favorite : Icons.favorite_border),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: GlassSurface(
              style: _clear ? GlassStyle.clear : GlassStyle.regular,
              cornerRadius: 20,
              tintColor: _tint(colors),
              forceFallback: _forceFallback,
              child: Row(
                children: [
                  const Icon(
                    Icons.blur_on_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _scene.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _clear ? 'Clear glass' : 'Regular glass',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        'Scroll the backdrop behind the glass.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 19),
      Text('Material', style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
      _Panel(
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Clear glass'),
              value: _clear,
              onChanged: (value) => setState(() => _clear = value),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tint'),
                  Text('${(_tintStrength * 100).round()}%'),
                ],
              ),
            ),
            Slider(
              value: _tintStrength,
              onChanged: (value) => setState(() => _tintStrength = value),
              semanticFormatterCallback: (value) =>
                  'Tint ${(value * 100).round()} percent',
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buttons(BuildContext context) {
    final theme = Theme.of(context);
    final tint = _tint(theme.colorScheme);
    return [
      Text('Button styles', style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
      _BackdropStage(
        scene: _scene,
        overlays: [
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                GlassButton(
                  label: _likes == 0 ? 'Like' : 'Liked · $_likes',
                  systemImage: 'heart',
                  fallbackIcon: Icons.favorite_border,
                  width: 132,
                  height: 50,
                  tintColor: tint,
                  forceFallback: _forceFallback,
                  onPressed: () => setState(() => _likes++),
                ),
                GlassButton(
                  label: 'Continue',
                  systemImage: 'arrow.right',
                  fallbackIcon: Icons.arrow_forward_rounded,
                  prominent: true,
                  width: 150,
                  height: 50,
                  tintColor: tint,
                  forceFallback: _forceFallback,
                  onPressed: () => _showSheet(context),
                ),
                GlassButton(
                  label: 'Disabled',
                  width: 132,
                  height: 50,
                  forceFallback: _forceFallback,
                  onPressed: null,
                ),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  Future<void> _showSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Button pressed',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text('The glass button called its Flutter press handler.'),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _renderer(BuildContext context) {
    final theme = Theme.of(context);
    final isIos = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    return [
      Text('Active renderer', style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
      _Panel(
        child: Column(
          children: [
            FutureBuilder<GlassCapabilities>(
              future: _capabilities,
              builder: (context, snapshot) {
                final title = switch (snapshot) {
                  _ when _forceFallback || !isIos => 'Flutter fallback',
                  _ when snapshot.hasError => 'iOS plugin unavailable',
                  _ when !snapshot.hasData => 'Checking iOS renderer…',
                  _ when snapshot.data!.nativeGlassAvailable =>
                    'Native Liquid Glass',
                  _ => 'UIKit fallback',
                };
                final version = snapshot.data?.systemVersion;
                return ListTile(
                  leading: const Icon(Icons.blur_on_rounded),
                  title: Text(title),
                  subtitle: switch (version) {
                    final String version => Text('iOS $version'),
                    _ when !isIos => const Text(
                      'Web, Android and desktop use Flutter glass',
                    ),
                    _ => null,
                  },
                );
              },
            ),
            if (isIos) ...[
              const Divider(height: 1, indent: 16, endIndent: 16),
              SwitchListTile(
                title: const Text('Use Flutter fallback'),
                value: _forceFallback,
                onChanged: (value) => setState(() => _forceFallback = value),
              ),
            ],
          ],
        ),
      ),
    ];
  }
}

class _BackdropStage extends StatelessWidget {
  const _BackdropStage({required this.scene, required this.overlays});
  final ExampleScene scene;
  final List<Widget> overlays;

  @override
  Widget build(BuildContext context) {
    final textGrowth = (MediaQuery.textScalerOf(context).scale(16) - 16).clamp(
      0.0,
      40.0,
    );
    return CupertinoTheme(
      data: const CupertinoThemeData(brightness: Brightness.dark),
      child: SizedBox(
        height: 278 + textGrowth * 3,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: ExampleBackdrop(scene: scene),
            ),
            ...overlays,
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: child,
    );
  }
}

class _DemoDock extends StatelessWidget {
  const _DemoDock({
    required this.selected,
    required this.forceFallback,
    required this.onSelected,
  });
  final _DemoSection selected;
  final bool forceFallback;
  final ValueChanged<_DemoSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GlassSurface(
      cornerRadius: 30,
      padding: const EdgeInsets.all(5),
      forceFallback: forceFallback,
      child: Material(
        type: MaterialType.transparency,
        child: Row(
          children: [
            for (final section in _DemoSection.values)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: selected == section,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25),
                    onTap: () => onSelected(section),
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: selected == section
                            ? colors.primaryContainer
                            : Colors.transparent,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            section.icon,
                            color: selected == section
                                ? colors.onPrimaryContainer
                                : colors.onSurfaceVariant,
                            size: 21,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            section.label,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: selected == section
                                      ? colors.onPrimaryContainer
                                      : colors.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
