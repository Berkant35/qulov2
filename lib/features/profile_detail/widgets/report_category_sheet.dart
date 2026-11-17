import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/profile_detail/mixins/report_category_sheet_mixin.dart';

/// Şikâyet kategorisi seçimi. Liste kaydırılabilir: sheet varsayılan olarak
/// ekranın 9/16'sıyla sınırlı; küçük ekranda 11 satırın sonuncusu ("Diğer")
/// yoksa kesilirdi.
class ReportCategorySheet extends StatelessWidget with ReportCategorySheetMixin {
  static const double _handleWidth = 40;
  static const double _handleHeight = 4;
  static const double _handleAlpha = 0.3;
  static const double _iconSize = 22;

  final void Function(String category) onSelected;

  /// Quiz sorusu medyalıysa (ses/görsel) "Uygunsuz medya" da sunulur (2.0.19).
  final bool includeMediaCategory;

  const ReportCategorySheet({
    super.key,
    required this.onSelected,
    this.includeMediaCategory = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = categoriesFor(includeMedia: includeMediaCategory);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.sm),
          // Handle bar
          Container(
            width: _handleWidth,
            height: _handleHeight,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: _handleAlpha),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXxs),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
            child: Text(
              context.tr('report_select_category'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (ctx, index) {
                final cat = categories[index];
                return ListTile(
                  leading: Icon(cat.icon, color: context.appColors.warning, size: _iconSize),
                  title: Text(ctx.tr(cat.l10nKey)),
                  onTap: () {
                    Navigator.pop(context);
                    onSelected(cat.value);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
