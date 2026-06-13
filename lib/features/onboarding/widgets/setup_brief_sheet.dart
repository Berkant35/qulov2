import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/interest_constants.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';

class SetupBriefSheet extends StatefulWidget {
  final void Function(List<String> interests) onGenerate;
  final VoidCallback onSkip;

  const SetupBriefSheet({
    super.key,
    required this.onGenerate,
    required this.onSkip,
  });

  @override
  State<SetupBriefSheet> createState() => _SetupBriefSheetState();
}

class _SetupBriefSheetState extends State<SetupBriefSheet> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    final canGenerate = _selected.length >= InterestConstants.minSelect;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.hintColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Title
            Text(
              context.tr('brief_sheet_title'),
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),

            // Hint
            Text(
              context.tr('brief_sheet_hint'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Interest chips
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: InterestConstants.tagPool.map((tag) {
                final isSelected = _selected.contains(tag);
                return FilterChip(
                  label: Text(context.tr(InterestConstants.localeKey(tag))),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      if (isSelected) {
                        _selected.remove(tag);
                      } else {
                        _selected.add(tag);
                      }
                    });
                  },
                  selectedColor: colors.primarySurface,
                  backgroundColor: theme.colorScheme.surface,
                  checkmarkColor: colors.primary,
                  side: BorderSide(
                    color: isSelected ? colors.primary : colors.border,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Generate CTA
            AppButton(
              label: context.tr('brief_sheet_generate_cta'),
              onPressed: canGenerate
                  ? () => widget.onGenerate(_selected.toList())
                  : null,
              fullWidth: true,
            ),
            const SizedBox(height: AppSpacing.md),

            // Skip link
            TextButton(
              onPressed: widget.onSkip,
              child: Text(
                context.tr('brief_sheet_skip_link'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
