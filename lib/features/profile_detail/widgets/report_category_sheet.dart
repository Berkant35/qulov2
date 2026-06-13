import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

class ReportCategorySheet extends StatelessWidget {
  final void Function(String category) onSelected;

  const ReportCategorySheet({super.key, required this.onSelected});

  static const List<_ReportCategory> _categories = [
    _ReportCategory(value: 'INAPPROPRIATE_CONTENT', l10nKey: 'report_cat_inappropriate', icon: Icons.warning_amber_outlined),
    _ReportCategory(value: 'FAKE_PROFILE', l10nKey: 'report_cat_fake', icon: Icons.person_off_outlined),
    _ReportCategory(value: 'SPAM', l10nKey: 'report_cat_spam', icon: Icons.mark_email_unread_outlined),
    _ReportCategory(value: 'HARASSMENT', l10nKey: 'report_cat_harassment', icon: Icons.sentiment_very_dissatisfied_outlined),
    _ReportCategory(value: 'UNDERAGE', l10nKey: 'report_cat_underage', icon: Icons.child_care_outlined),
    _ReportCategory(value: 'SCAM', l10nKey: 'report_cat_scam', icon: Icons.money_off_outlined),
    _ReportCategory(value: 'OFFENSIVE_PHOTOS', l10nKey: 'report_cat_offensive_photos', icon: Icons.hide_image_outlined),
    _ReportCategory(value: 'THREATENING', l10nKey: 'report_cat_threatening', icon: Icons.gavel_outlined),
    _ReportCategory(value: 'IMPERSONATION', l10nKey: 'report_cat_impersonation', icon: Icons.masks_outlined),
    _ReportCategory(value: 'OTHER', l10nKey: 'report_cat_other', icon: Icons.more_horiz),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.sm),
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
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
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _categories.length,
            itemBuilder: (ctx, index) {
              final cat = _categories[index];
              return ListTile(
                leading: Icon(cat.icon, color: context.appColors.warning, size: 22),
                title: Text(ctx.tr(cat.l10nKey)),
                onTap: () {
                  Navigator.pop(context);
                  onSelected(cat.value);
                },
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _ReportCategory {
  final String value;
  final String l10nKey;
  final IconData icon;

  const _ReportCategory({
    required this.value,
    required this.l10nKey,
    required this.icon,
  });
}
