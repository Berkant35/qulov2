import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

/// Minimum soru sayısına ulaşınca bir kez gösterilen kutlama: "Keşfet'e git".
class QuestionCelebrationDialog extends StatelessWidget {
  final VoidCallback onGoDiscover;

  const QuestionCelebrationDialog({super.key, required this.onGoDiscover});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.md),
          Icon(Icons.celebration, size: 64, color: context.appColors.primary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.tr('question_nudge_celebration_title'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onGoDiscover,
              style: FilledButton.styleFrom(
                backgroundColor: context.appColors.primary,
              ),
              child: Text(context.tr('question_nudge_celebration_button')),
            ),
          ),
        ],
      ),
    );
  }
}
