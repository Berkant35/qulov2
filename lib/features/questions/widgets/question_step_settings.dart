import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/questions/widgets/time_preset_card.dart';

class QuestionStepSettings extends StatelessWidget {
  final int selectedTimeLimit;
  final ValueChanged<int> onTimeLimitChanged;

  const QuestionStepSettings({
    super.key,
    required this.selectedTimeLimit,
    required this.onTimeLimitChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timePresets = AppConstants.timePresets;
    final timeLabels = [
      'question_time_fast',
      'question_time_normal',
      'question_time_relaxed',
      'question_time_thoughtful',
    ];
    final timeDescs = [
      'question_time_fast_desc',
      'question_time_normal_desc',
      'question_time_relaxed_desc',
      'question_time_thoughtful_desc',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('question_create_select_time'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.4,
            ),
            itemCount: 4,
            itemBuilder: (_, i) {
              final seconds = timePresets[i];
              final isSelected = selectedTimeLimit == seconds;
              return TimePresetCard(
                seconds: seconds,
                label: context.tr(timeLabels[i]),
                description: context.tr(timeDescs[i]),
                isSelected: isSelected,
                onTap: () => onTimeLimitChanged(seconds),
              );
            },
          ),
        ],
      ),
    );
  }
}
