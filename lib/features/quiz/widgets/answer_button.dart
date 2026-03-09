import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

class AnswerButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isDisabled;

  const AnswerButton({
    super.key,
    required this.text,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDisabled ? Theme.of(context).colorScheme.outline : AppColors.primary,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            color: isDisabled ? Theme.of(context).colorScheme.surfaceContainerHigh : Theme.of(context).colorScheme.surface,
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDisabled ? Theme.of(context).hintColor : Theme.of(context).colorScheme.onSurface,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
