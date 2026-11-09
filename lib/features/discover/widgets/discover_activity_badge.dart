import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

/// Kartta son görülme kovası: "Bugün aktif" (canlı nokta) / "Bu hafta aktif".
/// Kullanıcı quiz'e emek harcamadan cevap gelme ihtimalini görür (2.0.18 madde 8).
class DiscoverActivityBadge extends StatelessWidget {
  final String label;

  /// Son 24 saatte görüldü: nokta başarı rengiyle vurgulanır.
  final bool isRecent;

  const DiscoverActivityBadge({super.key, required this.label, required this.isRecent});

  static const _dotSize = AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: AppColors.scrimBase.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: _dotSize,
            height: _dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isRecent ? colors.success : AppColors.onScrim.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onScrim),
          ),
        ],
      ),
    );
  }
}
