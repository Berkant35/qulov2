# Splash Screen Redesign — Glitch Reveal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current splash screen (question rain + flow story + text) with a minimal, kinetic glitch reveal animation — only the logo with a deep gradient background.

**Architecture:** Slice-based glitch effect via `CustomPainter`. Logo is divided into horizontal slices, each displaced with RGB channel separation and opacity flicker during "chaos" phase, then stabilized. A single glow pulse settles the logo. Auth check runs in parallel with a minimum display time of ~3 seconds.

**Tech Stack:** Flutter `CustomPainter`, `AnimationController`, `Canvas.clipRect`, `ColorFilter`/`BlendMode` for RGB separation, `flutter_svg` for logo rendering.

---

## File Structure

```
lib/features/splash/
├── splash_screen.dart              # MODIFY — remove old widgets, use new GlitchLogo
├── mixins/
│   └── splash_screen_mixin.dart    # REWRITE — new controllers (glitch, glow), parallel auth
└── widgets/
    ├── splash_logo.dart            # REWRITE — glitch reveal wrapper + glow settle
    ├── glitch_painter.dart         # CREATE — CustomPainter for slice-based glitch
    ├── splash_text.dart            # DELETE
    ├── splash_flow_story.dart      # DELETE
    └── question_rain.dart          # DELETE

lib/core/constants/
├── app_durations.dart              # MODIFY — replace old splash durations with new ones
```

---

### Task 1: Update AppDurations — new splash timing constants

**Files:**
- Modify: `lib/core/constants/app_durations.dart`

- [ ] **Step 1: Replace splash duration constants**

Replace the existing splash section in `lib/core/constants/app_durations.dart` with:

```dart
// Splash — Glitch Reveal
static const splashGlitch = Duration(milliseconds: 1000);
static const splashGlowSettle = Duration(milliseconds: 500);
static const splashMinDisplay = Duration(milliseconds: 3000);
static const splashFadeOut = Duration(milliseconds: 300);
```

Remove the old constants: `splashInitDelay`, `splashLogo`, `splashTextDelay`, `splashText`, `splashHold`, `splashParticles`, `splashGlowPulse`, `splashShimmer`, `splashStaggeredText`, `splashRingExpand`.

- [ ] **Step 2: Run analyzer**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze lib/core/constants/app_durations.dart`
Expected: No errors in this file (other files referencing old constants will break — that's expected, we fix them next)

- [ ] **Step 3: Commit**

```bash
git add lib/core/constants/app_durations.dart
git commit -m "refactor(splash): update AppDurations with glitch reveal timing"
```

---

### Task 2: Create GlitchPainter — slice-based glitch CustomPainter

**Files:**
- Create: `lib/features/splash/widgets/glitch_painter.dart`

- [ ] **Step 1: Create the GlitchPainter class**

Create `lib/features/splash/widgets/glitch_painter.dart`:

```dart
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Renders a [ui.Image] with horizontal-slice displacement and RGB channel
/// separation.  [progress] drives the animation:
///   0.0 = full chaos   →   1.0 = fully stabilized
class GlitchPainter extends CustomPainter {
  final ui.Image image;
  final double progress;
  final int sliceCount;
  final Color tintColor;

  /// Pre-computed per-slice random seeds — created once per widget lifecycle
  /// and passed in so the painter stays deterministic across repaints.
  final List<GlitchSliceSeed> seeds;

  GlitchPainter({
    required this.image,
    required this.progress,
    required this.seeds,
    required this.tintColor,
    this.sliceCount = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final imgW = image.width.toDouble();
    final imgH = image.height.toDouble();
    final sliceH = imgH / sliceCount;

    // chaos = 1.0 at start, 0.0 when stabilized
    final chaos = (1.0 - progress).clamp(0.0, 1.0);

    // Flicker: random opacity bursts during chaos phase
    final flickerAlpha = chaos > 0.05
        ? (0.3 + 0.7 * (0.5 + 0.5 * sin(progress * pi * 20 + seeds[0].phase)))
        : 1.0;

    // Scale image to fit the target size
    final scaleX = size.width / imgW;
    final scaleY = size.height / imgH;

    for (var i = 0; i < sliceCount; i++) {
      final seed = seeds[i];
      final srcTop = sliceH * i;
      final srcRect = Rect.fromLTWH(0, srcTop, imgW, sliceH);

      final dstTop = sliceH * scaleY * i;
      final dstH = sliceH * scaleY;

      // X displacement decays with progress (chaos → stable)
      final maxDisplacement = seed.displacement * 40.0;
      final dx = maxDisplacement * chaos * sin(progress * pi * 8 + seed.phase);

      // RGB channel offsets
      final rgbOffset = chaos * seed.rgbShift * 6.0;

      // Draw R channel (shifted left)
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, dstTop, size.width, dstH));

      // Red channel
      canvas.drawImageRect(
        image,
        srcRect,
        Rect.fromLTWH(dx - rgbOffset, dstTop, imgW * scaleX, dstH),
        Paint()
          ..colorFilter = const ColorFilter.mode(Colors.red, BlendMode.modulate)
          ..color = Colors.white.withValues(alpha: flickerAlpha * 0.5),
      );

      // Green channel (center)
      canvas.drawImageRect(
        image,
        srcRect,
        Rect.fromLTWH(dx, dstTop, imgW * scaleX, dstH),
        Paint()
          ..colorFilter =
              const ColorFilter.mode(Colors.green, BlendMode.modulate)
          ..color = Colors.white.withValues(alpha: flickerAlpha * 0.5),
      );

      // Blue channel (shifted right)
      canvas.drawImageRect(
        image,
        srcRect,
        Rect.fromLTWH(dx + rgbOffset, dstTop, imgW * scaleX, dstH),
        Paint()
          ..colorFilter =
              const ColorFilter.mode(Colors.blue, BlendMode.modulate)
          ..color = Colors.white.withValues(alpha: flickerAlpha * 0.5),
      );

      canvas.restore();
    }

    // Scan lines overlay during chaos
    if (chaos > 0.05) {
      final scanPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.08 * chaos)
        ..strokeWidth = 1;
      for (var y = 0.0; y < size.height; y += 3) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), scanPaint);
      }
    }

    // Normal composited image fades in as chaos fades out
    // This is the "clean" version that replaces the RGB split
    if (progress > 0.4) {
      final cleanAlpha = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, imgW, imgH),
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..colorFilter = ColorFilter.mode(tintColor, BlendMode.srcIn)
          ..color = Colors.white.withValues(alpha: cleanAlpha),
      );
    }
  }

  @override
  bool shouldRepaint(GlitchPainter old) =>
      old.progress != progress || old.image != image;
}

/// Random seed data for one horizontal slice.
class GlitchSliceSeed {
  final double displacement; // 0–1
  final double rgbShift; // 0–1
  final double phase; // 0–2π

  const GlitchSliceSeed({
    required this.displacement,
    required this.rgbShift,
    required this.phase,
  });

  static List<GlitchSliceSeed> generate(int count, [int seed = 42]) {
    final rng = Random(seed);
    return List.generate(count, (_) {
      return GlitchSliceSeed(
        displacement: rng.nextDouble(),
        rgbShift: 0.3 + rng.nextDouble() * 0.7,
        phase: rng.nextDouble() * pi * 2,
      );
    });
  }
}
```

- [ ] **Step 2: Run analyzer**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze lib/features/splash/widgets/glitch_painter.dart`
Expected: 0 issues

- [ ] **Step 3: Commit**

```bash
git add lib/features/splash/widgets/glitch_painter.dart
git commit -m "feat(splash): add GlitchPainter — slice-based glitch CustomPainter"
```

---

### Task 3: Rewrite SplashLogo — glitch reveal + glow settle

**Files:**
- Rewrite: `lib/features/splash/widgets/splash_logo.dart`

This widget rasterizes the SVG logo to a `ui.Image`, then passes it to `GlitchPainter`. After stabilization, renders a neon glow settle.

- [ ] **Step 1: Rewrite splash_logo.dart**

Replace entire content of `lib/features/splash/widgets/splash_logo.dart`:

```dart
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qulo_v2/core/constants/app_assets.dart';
import 'package:qulo_v2/core/constants/app_sizes.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/features/splash/widgets/glitch_painter.dart';

class SplashLogo extends StatefulWidget {
  /// 0→1: glitch chaos→stable
  final Animation<double> glitch;

  /// 0→1: glow pulse settle
  final Animation<double> glow;

  const SplashLogo({
    super.key,
    required this.glitch,
    required this.glow,
  });

  @override
  State<SplashLogo> createState() => _SplashLogoState();
}

class _SplashLogoState extends State<SplashLogo> {
  ui.Image? _rasterImage;
  static const _sliceCount = 12;
  final _seeds = GlitchSliceSeed.generate(_sliceCount);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_rasterImage == null) {
      _rasterizeSvg();
    }
  }

  Future<void> _rasterizeSvg() async {
    final pictureInfo = await vg.loadPicture(
      SvgAssetLoader(AppAssets.logoSvg),
      null,
    );

    // Render at 2x for sharpness
    const targetSize = AppSizes.logoLg * 2;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final scale = targetSize / pictureInfo.size.width;
    canvas.scale(scale, scale);
    canvas.drawPicture(pictureInfo.picture);
    pictureInfo.picture.dispose();

    final image = await recorder
        .endRecording()
        .toImage(targetSize.toInt(), targetSize.toInt());

    if (mounted) {
      setState(() => _rasterImage = image);
    }
  }

  @override
  void dispose() {
    _rasterImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = context.appColors.primary;

    if (_rasterImage == null) {
      return const SizedBox(
        width: AppSizes.logoLg,
        height: AppSizes.logoLg,
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([widget.glitch, widget.glow]),
      builder: (context, _) {
        final glowValue = widget.glow.value;
        // Glow settle: 0→0.4→0.2
        final glowAlpha = glowValue < 0.5
            ? glowValue * 0.8 // 0→0.4
            : 0.4 - (glowValue - 0.5) * 0.4; // 0.4→0.2
        final glowRadius = 40.0 + 20.0 * glowValue;

        return SizedBox(
          width: AppSizes.logoLg,
          height: AppSizes.logoLg,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Neon glow (visible after glitch stabilizes)
              if (widget.glitch.value > 0.8)
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: glowAlpha),
                        blurRadius: glowRadius,
                        spreadRadius: 10,
                      ),
                      BoxShadow(
                        color: primary.withValues(alpha: glowAlpha * 0.5),
                        blurRadius: glowRadius * 1.6,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              // Glitch painter
              RepaintBoundary(
                child: CustomPaint(
                  size: const Size(AppSizes.logoLg, AppSizes.logoLg),
                  painter: GlitchPainter(
                    image: _rasterImage!,
                    progress: widget.glitch.value,
                    seeds: _seeds,
                    tintColor: primary,
                    sliceCount: _sliceCount,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 2: Run analyzer**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze lib/features/splash/widgets/splash_logo.dart`
Expected: 0 issues (might need to adjust `vg.loadPicture` import — see step 3)

- [ ] **Step 3: Fix SVG rasterization import if needed**

The `vg.loadPicture` comes from `flutter_svg`. If the import is different, check how the project uses `flutter_svg` and adjust. The alternative approach is:

```dart
import 'package:flutter_svg/flutter_svg.dart' as vg;
```

Or use `SvgPicture`'s built-in rasterization. Adjust as needed and re-run analyzer.

- [ ] **Step 4: Commit**

```bash
git add lib/features/splash/widgets/splash_logo.dart
git commit -m "feat(splash): rewrite SplashLogo with glitch reveal + glow settle"
```

---

### Task 4: Rewrite SplashScreenMixin — new animation timeline

**Files:**
- Rewrite: `lib/features/splash/mixins/splash_screen_mixin.dart`

New timeline: glitch (1000ms) → glow settle (500ms) → hold until auth done (min 3s total). Auth starts immediately on init (parallel).

- [ ] **Step 1: Rewrite splash_screen_mixin.dart**

Replace entire content of `lib/features/splash/mixins/splash_screen_mixin.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/app_durations.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/models/app_dialog.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/app_config_provider.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/providers/economy_config_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/features/splash/splash_screen.dart';

mixin SplashScreenMixin on ConsumerState<SplashScreen>
    implements TickerProvider {
  // ─── Animation Controllers ───
  late final AnimationController glitchController;
  late final AnimationController glowController;
  late final AnimationController fadeOutController;

  // ─── Animations ───
  late final Animation<double> glitchAnimation;
  late final Animation<double> glowAnimation;
  late final Animation<double> fadeOutAnimation;

  final Stopwatch _splashStopwatch = Stopwatch()..start();
  bool _authCheckDone = false;
  bool _animationDone = false;

  void initMixin() {
    _setupControllers();
    _setupAnimations();
    _startAnimation();
    _startAuthCheckInParallel();
  }

  void _setupControllers() {
    glitchController = AnimationController(
      vsync: this,
      duration: AppDurations.splashGlitch,
    );

    glowController = AnimationController(
      vsync: this,
      duration: AppDurations.splashGlowSettle,
    );

    fadeOutController = AnimationController(
      vsync: this,
      duration: AppDurations.splashFadeOut,
    );
  }

  void _setupAnimations() {
    // Glitch: slow start → fast stabilization
    glitchAnimation = CurvedAnimation(
      parent: glitchController,
      curve: Curves.easeOutCubic,
    );

    glowAnimation = CurvedAnimation(
      parent: glowController,
      curve: Curves.easeOut,
    );

    fadeOutAnimation = CurvedAnimation(
      parent: fadeOutController,
      curve: Curves.easeIn,
    );
  }

  void disposeMixin() {
    glitchController.dispose();
    glowController.dispose();
    fadeOutController.dispose();
  }

  Future<void> _startAnimation() async {
    // Faz 1-2: Glitch kaos → stabilize (1000ms)
    if (!mounted) return;
    glitchController.forward();

    // Wait for glitch to finish before glow
    await glitchController.forward().orCancel.catchError((_) {});
    if (!mounted) return;

    // Faz 3: Glow settle (500ms)
    glowController.forward();
    await glowController.forward().orCancel.catchError((_) {});
    if (!mounted) return;

    // Ensure minimum display time
    final elapsed = _splashStopwatch.elapsedMilliseconds;
    final remaining = AppDurations.splashMinDisplay.inMilliseconds - elapsed;
    if (remaining > 0) {
      await Future.delayed(Duration(milliseconds: remaining));
    }
    if (!mounted) return;

    _animationDone = true;
    _tryProceed();
  }

  /// Auth + config checks start in parallel with the animation.
  Future<void> _startAuthCheckInParallel() async {
    _splashStopwatch.stop();
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.appSplashDuration,
      params: {
        AnalyticsEvents.paramDurationMs: _splashStopwatch.elapsedMilliseconds,
      },
    );

    final status = await ref.read(appConfigProvider.notifier).checkVersion();
    if (!mounted) return;

    await ref.read(economyConfigProvider.notifier).fetch();
    if (!mounted) return;

    switch (status) {
      case UpdateStatus.maintenance:
        AnalyticsManager.instance
            .logEvent(AnalyticsEvents.appMaintenanceShown);
        ref.read(navigationServiceProvider).go(RouteNames.maintenance);
        return;
      case UpdateStatus.forceUpdate:
        AnalyticsManager.instance
            .logEvent(AnalyticsEvents.appForceUpdateShown);
        ref.read(navigationServiceProvider).go(RouteNames.forceUpdate);
        return;
      case UpdateStatus.optionalUpdate:
        AnalyticsManager.instance
            .logEvent(AnalyticsEvents.appOptionalUpdateShown);
        await _showOptionalUpdateThenContinue();
        return;
      case UpdateStatus.none:
        break;
    }

    _authCheckDone = true;
    _tryProceed();
  }

  /// Only proceed when BOTH animation and auth check are done.
  void _tryProceed() {
    if (!_animationDone || !_authCheckDone || !mounted) return;
    ref.read(authProvider.notifier).checkAuth();
  }

  Future<void> _showOptionalUpdateThenContinue() async {
    final notifier = ref.read(appConfigProvider.notifier);
    final isDismissed = await notifier.isOptionalUpdateDismissed();

    if (isDismissed) {
      _authCheckDone = true;
      _tryProceed();
      return;
    }

    if (!mounted) return;

    final config = ref.read(appConfigProvider).config;
    final result =
        await ref.read(navigationServiceProvider).showAppDialog<bool>(
              ConfirmDialog(
                name: 'optional_update',
                title: context.tr('update_available_title'),
                message: context.tr('update_available_message'),
                confirmText: context.tr('update_button'),
                cancelText: context.tr('update_later'),
              ),
            );

    if (result == true && config != null && config.storeUrl.isNotEmpty) {
      ref.read(urlLauncherManagerProvider).launch(config.storeUrl);
    } else {
      await notifier.dismissOptionalUpdate();
    }

    _authCheckDone = true;
    _tryProceed();
  }
}
```

- [ ] **Step 2: Run analyzer**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze lib/features/splash/mixins/splash_screen_mixin.dart`
Expected: 0 issues

- [ ] **Step 3: Commit**

```bash
git add lib/features/splash/mixins/splash_screen_mixin.dart
git commit -m "feat(splash): rewrite SplashScreenMixin with parallel auth + glitch timeline"
```

---

### Task 5: Rewrite SplashScreen — new gradient background + GlitchLogo

**Files:**
- Rewrite: `lib/features/splash/splash_screen.dart`

- [ ] **Step 1: Rewrite splash_screen.dart**

Replace entire content of `lib/features/splash/splash_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/features/splash/mixins/splash_screen_mixin.dart';
import 'package:qulo_v2/features/splash/widgets/splash_logo.dart';
import 'package:qulo_v2/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin, SplashScreenMixin {
  @override
  void initState() {
    super.initState();
    initMixin();
  }

  @override
  void dispose() {
    disposeMixin();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authProvider);

    return AppScaffold(
      padding: EdgeInsets.zero,
      body: FadeTransition(
        opacity: ReverseAnimation(fadeOutAnimation),
        child: Stack(
          children: [
            // Deep gradient background
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF0D0015),
                      Color(0xFF1A0A2E),
                    ],
                  ),
                ),
              ),
            ),
            // Radial spotlight overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.6,
                    colors: [
                      const Color(0xFF2D1B4E).withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Glitch logo centered
            Center(
              child: SplashLogo(
                glitch: glitchAnimation,
                glow: glowAnimation,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run analyzer**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze lib/features/splash/`
Expected: 0 issues

- [ ] **Step 3: Commit**

```bash
git add lib/features/splash/splash_screen.dart
git commit -m "feat(splash): rewrite SplashScreen with gradient bg + glitch logo"
```

---

### Task 6: Delete old widget files

**Files:**
- Delete: `lib/features/splash/widgets/splash_text.dart`
- Delete: `lib/features/splash/widgets/splash_flow_story.dart`
- Delete: `lib/features/splash/widgets/question_rain.dart`

- [ ] **Step 1: Delete the three old widget files**

```bash
cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2
rm lib/features/splash/widgets/splash_text.dart
rm lib/features/splash/widgets/splash_flow_story.dart
rm lib/features/splash/widgets/question_rain.dart
```

- [ ] **Step 2: Check for stale imports anywhere in the project**

Run: `grep -r "splash_text\|splash_flow_story\|question_rain" lib/`

If any imports remain, remove them.

- [ ] **Step 3: Full project analyze**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter analyze`
Expected: 0 issues

- [ ] **Step 4: Commit**

```bash
git add -u lib/features/splash/widgets/
git commit -m "refactor(splash): remove SplashText, SplashFlowStory, QuestionRain"
```

---

### Task 7: Test on device & fine-tune

**Files:**
- Possibly modify: `lib/features/splash/widgets/glitch_painter.dart` (tuning values)
- Possibly modify: `lib/features/splash/widgets/splash_logo.dart` (SVG rasterization)

- [ ] **Step 1: Run the app on simulator/device**

Run: `cd /Users/berkantcalikusu/IdeaProjects/qulo/qulov2 && flutter run`

Verify:
1. Deep gradient background renders correctly
2. Logo appears with glitch effect (slices displaced, RGB split visible)
3. Glitch stabilizes into clean logo (~1s)
4. Neon glow pulse settles after stabilization
5. Transition to auth/home screen happens after ~3s
6. No jank or dropped frames

- [ ] **Step 2: Adjust GlitchPainter values if needed**

Tune these in `glitch_painter.dart` for visual quality:
- `maxDisplacement` (line with `* 40.0`) — how far slices shift horizontally
- `rgbOffset` multiplier (`* 6.0`) — how much RGB channels separate
- `sin(progress * pi * 8 ...)` — oscillation frequency
- `sliceCount` (default 12) — number of horizontal slices
- Scan line spacing (`y += 3`) and opacity (`0.08 * chaos`)

- [ ] **Step 3: Fix SVG rasterization if needed**

If `vg.loadPicture` doesn't work with the project's `flutter_svg` version, alternative approach using `PictureProvider`:

```dart
final svgString = await DefaultAssetBundle.of(context)
    .loadString(AppAssets.logoSvg);
final pictureInfo = await vg.loadPicture(SvgStringLoader(svgString), null);
```

Or render the SVG to a `RenderRepaintBoundary` and capture via `toImage()`.

- [ ] **Step 4: Commit final tuned version**

```bash
git add lib/features/splash/
git commit -m "feat(splash): fine-tune glitch reveal animation values"
```

---

### Task 8: Clean up unused localization keys (optional)

**Files:**
- Modify: localization JSON files under `lib/core/l10n/` or `assets/l10n/`

- [ ] **Step 1: Search for splash flow localization keys**

Run: `grep -r "splash_flow_ask\|splash_flow_answer\|splash_flow_match" lib/ assets/`

- [ ] **Step 2: Remove the keys if not used elsewhere**

Remove `splash_flow_ask`, `splash_flow_answer`, `splash_flow_match` from all locale files.

- [ ] **Step 3: Commit**

```bash
git add -A lib/core/l10n/ assets/l10n/
git commit -m "chore(i18n): remove unused splash flow localization keys"
```
