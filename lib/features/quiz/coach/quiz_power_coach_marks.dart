import 'package:flutter/material.dart';
import 'package:qulo_v2/core/coach_mark/coach_mark_step.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/features/quiz/widgets/coach_power_row.dart';
import 'package:qulo_v2/features/quiz/widgets/coach_wallet_note.dart';

/// Güç turunun kimliği — `coach_quiz_powers_seen` bayrağı (eski sürümde turu
/// görmüş kullanıcıya tekrar gösterilmez).
const String quizPowersTourId = 'quiz_powers';

/// İlk quiz'den ÖNCE (oturum başlamadan, soru yüklenmeden) gösterilen ortalı
/// güç kartı. Eskiden ilk sorunun üstünde açılıyordu: istemci sayacı
/// duruyordu ama sunucunun oturum süresi (`expires_at` = soru süreleri
/// toplamı + 10 sn) işlemeye devam ediyordu — yavaş okuyan kullanıcı ilk
/// quiz'inde TIME_UP alabiliyordu.
List<CoachMarkStep> buildQuizPowerCoachSteps() => [
      CoachMarkStep(
        titleKey: 'coach_quiz_powers_title',
        bodyKey: 'coach_quiz_powers_body',
        ctaKey: 'coach_cta_got_it',
        bodyBuilder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('coach_quiz_powers_body'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            const CoachWalletNote(),
            const CoachPowerRow(type: PowerType.oracle, labelKey: 'coach_quiz_power_oracle'),
            const CoachPowerRow(type: PowerType.half, labelKey: 'coach_quiz_power_half'),
            const CoachPowerRow(type: PowerType.skip, labelKey: 'coach_quiz_power_skip'),
            const CoachPowerRow(type: PowerType.hint, labelKey: 'coach_quiz_power_hint'),
            const CoachPowerRow(type: PowerType.timeExtend, labelKey: 'coach_quiz_power_time_extend'),
            const CoachPowerRow(type: PowerType.skipAll, labelKey: 'coach_quiz_power_skip_all'),
          ],
        ),
      ),
    ];
