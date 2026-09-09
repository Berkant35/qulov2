import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/questions/mixins/question_step_settings_mixin.dart';
import 'package:qulo_v2/features/questions/widgets/time_preset_card.dart';

class QuestionStepSettings extends StatelessWidget
    with QuestionStepSettingsMixin {
  final int selectedTimeLimit;
  final List<int> timePresets;
  final ValueChanged<int> onTimeLimitChanged;

  const QuestionStepSettings({
    super.key,
    required this.selectedTimeLimit,
    required this.timePresets,
    required this.onTimeLimitChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            // Sabit 4 yaziliydi: secenekler economy config'ten geliyor ve
            // sayisi degisebiliyor. 4'ten az preset RangeError ile cokerdi,
            // fazlasi sessizce gosterilmezdi.
            itemCount: timePresets.length,
            itemBuilder: (_, i) {
              final seconds = timePresets[i];
              final isSelected = selectedTimeLimit == seconds;
              final labelKey = timeLabelKey(i);
              final descKey = timeDescKey(i);
              return TimePresetCard(
                seconds: seconds,
                label: labelKey != null ? context.tr(labelKey) : '$seconds sn',
                description: descKey != null ? context.tr(descKey) : '',
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
