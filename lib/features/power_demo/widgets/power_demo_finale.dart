import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/features/quiz/widgets/celebration_stats_card.dart';

/// Demonun kapanışı: eşleşme kutlaması (saf istatistik kartı) + tek not + İleri.
///
/// Gerçek kutlama ekranı (`MatchCelebrationScreen`) KULLANILMAZ: o, gerçek eşleşme olayını
/// atar ve ilk-eşleşme teklifini tüketir; demo hiçbir gerçek metriğe ya da bayrağa dokunmaz.
class PowerDemoFinale extends StatelessWidget {
  const PowerDemoFinale({
    super.key,
    required this.totalQuestions,
    required this.seconds,
    required this.powersUsed,
    required this.note,
    required this.onContinue,
  });

  final int totalQuestions;
  final int seconds;
  final int powersUsed;

  /// Hediye ya da "gerçek quiz'de seni bekliyor" cümlesi; `null` → not yok.
  final String? note;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final note = this.note;
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_rounded, size: AppSpacing.xxxl, color: AppColors.matchPink),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      context.tr('power_demo_finale_title'),
                      style: textTheme.headlineSmall?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    CelebrationStatsCard(
                      totalCorrect: totalQuestions,
                      totalQuestions: totalQuestions,
                      totalTimeSpent: seconds,
                      powersUsed: powersUsed,
                    ),
                    if (note != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        note,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(label: context.tr('next'), onPressed: onContinue),
        ],
      ),
    );
  }
}
