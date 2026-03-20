import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/features/diamonds/widgets/paywall_bottom_sheet.dart';

class LockedFeatureButton extends ConsumerWidget {
  final Widget child;
  final bool isLocked;
  final String trigger;
  final Widget? lockedChild;

  const LockedFeatureButton({
    super.key,
    required this.child,
    required this.isLocked,
    required this.trigger,
    this.lockedChild,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isLocked) return child;

    return GestureDetector(
      onTap: () => PaywallBottomSheetContent.show(ref, trigger: trigger),
      child: lockedChild ??
          Stack(
            alignment: Alignment.center,
            children: [
              Opacity(opacity: 0.4, child: IgnorePointer(child: child)),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: context.appColors.surfaceElevated,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: QIcon(QIcons.icLock, size: 14, color: AppColors.primary),
                ),
              ),
            ],
          ),
    );
  }
}
