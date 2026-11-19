import 'package:flutter/material.dart';
import 'package:ios_liquid_glass_effect/ios_liquid_glass_effect.dart';

import 'scene.dart';

void main() => runApp(const GlassExample());

class GlassExample extends StatefulWidget {
  const GlassExample({super.key});

  @override
  State<GlassExample> createState() => _GlassExampleState();
}

class _GlassExampleState extends State<GlassExample> {
  ExampleScene _scene = ExampleScene.colors;
  bool _dark = false;
  int _likes = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iOS Liquid Glass Effect by CodeMicros',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xff536ec1)),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xff9cb4ff),
        brightness: Brightness.dark,
      ),
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Liquid Glass'),
            actions: [
              IconButton(
                tooltip: _dark ? 'Use light mode' : 'Use dark mode',
                onPressed: () => setState(() => _dark = !_dark),
                icon: Icon(
                  _dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(
                  'Glass, in context',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Change the background and scroll it behind the controls.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final scene in ExampleScene.values)
                      ChoiceChip(
                        label: Text(scene.label),
                        selected: _scene == scene,
                        onSelected: (_) => setState(() => _scene = scene),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // The scene clips itself; the native glass remains unclipped.
                SizedBox(
                  height:
                      480 *
                      MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0),
                  child: Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: ExampleBackdrop(scene: _scene),
                      ),
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // A larger card can hold ordinary Flutter content.
                              const GlassSurface(
                                style: GlassStyle.regular,
                                cornerRadius: 28,
                                child: Row(
                                  children: [
                                    Icon(Icons.wb_sunny_outlined, size: 28),
                                    SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Glass card',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text('A surface for your content.'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 16,
                                runSpacing: 16,
                                children: [
                                  // A rounded rectangle demonstrates another shape.
                                  const SizedBox(
                                    width: 170,
                                    height: 68,
                                    child: GlassSurface(
                                      cornerRadius: 16,
                                      style: GlassStyle.clear,
                                      padding: EdgeInsets.zero,
                                      child: Center(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.graphic_eq_rounded),
                                            SizedBox(width: 8),
                                            Text(
                                              'Now playing',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // A circular glass surface with an interactive child.
                                  SizedBox(
                                    width: 68,
                                    height: 68,
                                    child: GlassSurface(
                                      cornerRadius: 34,
                                      style: GlassStyle.clear,
                                      padding: EdgeInsets.zero,
                                      child: Center(
                                        child: IconButton(
                                          tooltip: 'Favorite',
                                          onPressed: () =>
                                              setState(() => _likes++),
                                          icon: const Icon(
                                            Icons.favorite_border,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  // On iOS this is a complete native UIKit button.
                                  GlassButton(
                                    label: _likes == 0
                                        ? 'Like'
                                        : 'Liked · $_likes',
                                    systemImage: 'heart',
                                    fallbackIcon: Icons.favorite_border,
                                    width: 140,
                                    height: 54,
                                    onPressed: () => setState(() => _likes++),
                                  ),
                                  GlassButton(
                                    label: 'Continue',
                                    systemImage: 'arrow.right',
                                    fallbackIcon: Icons.arrow_forward,
                                    width: 150,
                                    height: 54,
                                    prominent: true,
                                    onPressed: () =>
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Continue pressed'),
                                          ),
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Native Liquid Glass requires iOS 26 or later. Other platforms and older iOS versions use a fallback.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
