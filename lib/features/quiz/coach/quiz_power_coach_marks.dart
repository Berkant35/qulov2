import 'package:flutter/material.dart';
import 'package:qulo_v2/core/coach_mark/coach_mark_step.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';

/// Single-step tour highlighting the whole power bar. [onPause] is called when
/// the card appears (timer freezes); [onDismiss] is called on every close path
/// — Got it, ✕ skip, or back — so resume is guaranteed.
List<CoachMarkStep> buildQuizPowerCoachSteps({
  required VoidCallback onPause,
  required VoidCallback onResume,
}) =>
    [
      CoachMarkStep(
        anchorId: 'quiz_powerbar',
        shape: CoachMarkShape.rect,
        titleKey: 'coach_quiz_powers_title',
        bodyKey: 'coach_quiz_powers_body',
        ctaKey: 'coach_cta_got_it',
        onShow: onPause,
        onDismiss: onResume,
        bodyBuilder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('coach_quiz_powers_body'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            _powerRow(context, PowerType.oracle, 'coach_quiz_power_oracle'),
            _powerRow(context, PowerType.half, 'coach_quiz_power_half'),
            _powerRow(context, PowerType.skip, 'coach_quiz_power_skip'),
            _powerRow(context, PowerType.hint, 'coach_quiz_power_hint'),
            _powerRow(
                context, PowerType.timeExtend, 'coach_quiz_power_time_extend'),
            _powerRow(
                context, PowerType.skipAll, 'coach_quiz_power_skip_all'),
          ],
        ),
      ),
    ];

Widget _powerRow(BuildContext context, PowerType type, String key) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          PowerIcon(type: type, size: 24),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.tr(key),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
