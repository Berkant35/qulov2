import 'package:flutter/material.dart';
import 'package:qulo_v2/core/coach_mark/coach_mark_controller.dart';
import 'package:qulo_v2/core/coach_mark/coach_mark_painter.dart';
import 'package:qulo_v2/core/coach_mark/coach_mark_registry.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';

class CoachMarkOverlay extends StatefulWidget {
  const CoachMarkOverlay({super.key, required this.controller});

  final CoachMarkController controller;

  @override
  State<CoachMarkOverlay> createState() => _CoachMarkOverlayState();
}

class _CoachMarkOverlayState extends State<CoachMarkOverlay> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.controller.start());
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  Rect? _resolveRect(String? anchorId) {
    if (anchorId == null) return null;
    final ctx = CoachMarkRegistry.maybeKey(anchorId)?.currentContext;
    final box = ctx?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final offset = box.localToGlobal(Offset.zero);
    return offset & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final step = controller.current;
    final screen = MediaQuery.of(context).size;
    final hole = _resolveRect(step.anchorId);
    const barrier = AppColors.scrimDark;

    // Card on the opposite half from the target (or centered when no anchor).
    final targetBelowHalf = hole != null && hole.center.dy > screen.height / 2;
    final Alignment cardAlign = hole == null
        ? Alignment.center
        : (targetBelowHalf ? Alignment.topCenter : Alignment.bottomCenter);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: CoachMarkPainter(
                  holeRect: hole, barrierColor: barrier, shape: step.shape),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: AppColors.onScrim),
                onPressed: controller.skipAll,
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: cardAlign,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
                child: Container(
                  margin: const EdgeInsets.all(AppSpacing.lg),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr(step.titleKey),
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      step.bodyBuilder != null
                          ? step.bodyBuilder!(context)
                          : Text(context.tr(step.bodyKey),
                              style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: AppSpacing.md),
                      _StepDots(count: controller.stepCount, index: controller.index),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(label: context.tr(step.ctaKey), onPressed: controller.next),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return Container(
          width: active ? 10 : 6,
          height: active ? 10 : 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).disabledColor,
          ),
        );
      }),
    );
  }
}
