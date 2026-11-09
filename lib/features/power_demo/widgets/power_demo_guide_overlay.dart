import 'package:flutter/material.dart';
import 'package:qulo_v2/core/coach_mark/coach_mark_painter.dart';
import 'package:qulo_v2/core/coach_mark/coach_mark_step.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/power_effects/power_effect_timing.dart';
import 'package:qulo_v2/core/widgets/power_effects/reduce_motion.dart';

/// "Bir anda tek talimat": ekranın geri kalanı kararır, yalnız [targetKey] (dokunulacak güç)
/// açıkta kalır ve üstünde tek cümle durur.
///
/// Delik içindeki dokunuş hedefe geçer; dışındaki yutulur (yanlış yere dokunmak bir şey
/// yapmaz). Katman yalnız bulunduğu alanı örter — demonun "Atla"sı dışarıda kalır.
class PowerDemoGuideOverlay extends StatefulWidget {
  const PowerDemoGuideOverlay({
    super.key,
    required this.targetKey,
    required this.text,
  });

  final GlobalKey targetKey;
  final String text;

  @override
  State<PowerDemoGuideOverlay> createState() => _PowerDemoGuideOverlayState();
}

class _PowerDemoGuideOverlayState extends State<PowerDemoGuideOverlay> {
  /// Hedefin bu katmana göre dikdörtgeni; ilk kare çizilene kadar bilinmez (tam karartma).
  Rect? _hole;

  @override
  Widget build(BuildContext context) {
    // Ekran boyutu/yazı ölçeği değişince yeniden kurulup delik yeniden ölçülsün.
    MediaQuery.sizeOf(context);
    final hole = _hole;
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduceMotionOf(context)
          ? Duration.zero
          : PowerEffectTiming.enter,
      curve: PowerEffectTiming.curve,
      builder: (context, opacity, child) =>
          Opacity(opacity: opacity, child: child),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Her yeniden kurulumda VE her yerleşim değişiminde (ör. carousel'in alt çubuğu
          // animasyonla küçülürken sahne yeniden boyutlanır, katman kurulmaz) delik yeniden
          // ölçülür; yoksa delik eski yerde kalır, güce dokunuş yutulur, demo kilitlenir.
          WidgetsBinding.instance.addPostFrameCallback((_) => _measureHole());
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: PowerDemoGuidePainter(
                    holeRect: hole,
                    barrierColor: AppColors.scrimDark,
                  ),
                ),
              ),
              if (hole != null)
                Positioned(
                  left: AppSpacing.pagePadding,
                  right: AppSpacing.pagePadding,
                  // Hedefin hemen üstündeki "hediye" çipini de örtmeden.
                  bottom: constraints.maxHeight - hole.top + AppSpacing.xxl,
                  child: IgnorePointer(
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          child: Text(
                            widget.text,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _measureHole() {
    if (!mounted) return;
    final target = widget.targetKey.currentContext?.findRenderObject();
    final overlay = context.findRenderObject();
    if (target is! RenderBox ||
        overlay is! RenderBox ||
        !target.hasSize ||
        !overlay.hasSize) {
      return;
    }
    final rect =
        target.localToGlobal(Offset.zero, ancestor: overlay) & target.size;
    if (rect != _hole) setState(() => _hole = rect);
  }
}

/// Koç işaretinin karartma boyacısı + dokunma kuralı: delik içi geçer, dışı yakalanır.
class PowerDemoGuidePainter extends CoachMarkPainter {
  PowerDemoGuidePainter({required super.holeRect, required super.barrierColor})
    : super(shape: CoachMarkShape.rect);

  @override
  bool hitTest(Offset position) =>
      !(holeRect?.inflate(padding).contains(position) ?? false);
}
