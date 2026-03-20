import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/profile_detail/models/profile_detail_args.dart';

class ProfileActionBar extends StatelessWidget {
  final ProfileDetailContext detailContext;
  final VoidCallback? onSolveQuestions;
  final VoidCallback? onReject;
  final VoidCallback? onSendMessage;
  final bool isMatched;

  const ProfileActionBar({
    super.key,
    required this.detailContext,
    this.onSolveQuestions,
    this.onReject,
    this.onSendMessage,
    this.isMatched = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.pagePadding,
        right: AppSpacing.pagePadding,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: context.appColors.scaffold,
        border: Border(
          top: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: _buildButtons(context),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return switch (detailContext) {
      ProfileDetailContext.discover => Row(
          children: [
            // Reject button
            SizedBox(
              width: 56,
              height: 56,
              child: OutlinedButton(
                onPressed: onReject,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  side: BorderSide(
                    color: AppColors.error.withValues(alpha: 0.5),
                  ),
                  shape: const CircleBorder(),
                ),
                child: const Icon(
                  Icons.close,
                  color: AppColors.error,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Solve questions button
            Expanded(
              child: SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: onSolveQuestions,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusLg,
                      ),
                    ),
                  ),
                  child: Text(
                    context.tr('solve_questions'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ProfileDetailContext.match || ProfileDetailContext.chat => SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: onSendMessage,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
            ),
            child: Text(
              context.tr('send_message'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ProfileDetailContext.quizResult => SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: isMatched ? onSendMessage : onSolveQuestions,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
            ),
            child: Text(
              isMatched
                  ? context.tr('send_message')
                  : context.tr('solve_questions'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
    };
  }
}
