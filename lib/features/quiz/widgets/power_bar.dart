import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/core/widgets/safe_tap_button.dart';
import 'package:qulo_v2/core/widgets/power_effects/power_effect_timing.dart';
import 'package:qulo_v2/core/widgets/power_effects/reduce_motion.dart';
import 'package:qulo_v2/features/quiz/mixins/power_bar_mixin.dart';
import 'package:qulo_v2/features/quiz/mixins/power_help_mixin.dart';
import 'package:qulo_v2/features/quiz/widgets/power_help_bubble.dart';
import 'package:qulo_v2/features/quiz/widgets/power_help_button.dart';
import 'package:qulo_v2/providers/economy_config_provider.dart';
import 'package:qulo_v2/providers/exchange_provider.dart';
import 'package:qulo_v2/providers/quiz_provider.dart';

/// Quiz guc bari.
///
/// Envanter kapisi YOK: envanterde hak varsa oradan duser, yoksa dogrudan mor
/// elmastan odenir (sunucu `tryUseInventory` false donunce `spendPurple`'a dusuyor).
/// Eskiden envanteri olmayan herkes 6 gri ikon goruyordu → prod'da 0 guc kullanimi.
///
/// Her gucun ustunde ayri dokunma alanli "?" ([PowerHelpButton]) → o guce ozel baloncuk
/// ([PowerHelpBubble]) cubugun hemen ustunde acilir. Yalniz gercek quiz; sohbetin
/// `ChatQuestionPowerBar`'inda yok (spec §13.2/6).
class PowerBar extends ConsumerStatefulWidget {
  final String sessionId;
  final bool hasHint;
  final void Function(String power)? onPowerUsed;

  const PowerBar({
    super.key,
    required this.sessionId,
    this.hasHint = false,
    this.onPowerUsed,
  });

  @override
  ConsumerState<PowerBar> createState() => _PowerBarState();
}

class _PowerBarState extends ConsumerState<PowerBar>
    with PowerBarMixin, PowerHelpMixin<PowerBar> {
  @override
  Widget build(BuildContext context) {
    final exchangeState = ref.watch(exchangeProvider);
    final quiz = ref.watch(quizProvider);
    final (oracleAccuracy, extendSeconds) = ref.watch(economyConfigProvider
        .select((c) => (c.oracleAccuracy, c.timing.timeExtendSeconds)));

    final powers = visiblePowers(quiz, hasHint: widget.hasHint);
    final help = visibleHelp(powers);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          duration: reduceMotionOf(context) ? Duration.zero : PowerEffectTiming.exit,
          curve: PowerEffectTiming.curve,
          alignment: Alignment.bottomCenter,
          child: help == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: PowerHelpBubble(
                    type: help,
                    title: powerLabel(context, help),
                    oracleAccuracy: oracleAccuracy,
                    timeExtendSeconds: extendSeconds,
                    onClose: closeHelp,
                  ),
                ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: powers.map((type) {
            final count = exchangeState.getCount(type.apiName);
            final isUsed = quiz.usedPowers.contains(type.apiName);

            return Column(
              key: ValueKey(type),
              mainAxisSize: MainAxisSize.min,
              children: [
                PowerHelpButton(
                  type: type,
                  isOpen: help == type,
                  onTap: () => toggleHelp(type),
                ),
                // "?" ile guc butonu arasinda bosluk: yanlis dokunus mor harcatmasin.
                const SizedBox(height: PowerHelpButton.gap),
                PowerBarButton(
                  type: type,
                  count: count,
                  isUsed: isUsed,
                  purpleCost: quiz.purpleCostOf(type.apiName),
                  label: powerLabel(context, type),
                  onTap: isUsed
                      ? null
                      : () async => widget.onPowerUsed?.call(type.apiName),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Tek guc butonu. Fiyat olarak SADECE mor gosterilir — dogrudan harcamada sunucu
/// yalnizca mor elmas dusuyor (`spendPurple`); yesil hedefe giden ODUL, alternatif
/// fiyat degil. Yan yana gostermek "yesille de odeyebilirim" yanilgisi yaratirdi.
class PowerBarButton extends StatelessWidget {
  final PowerType type;
  final int count;
  final bool isUsed;
  final int purpleCost;
  final String label;
  final Future<void> Function()? onTap;

  const PowerBarButton({
    super.key,
    required this.type,
    required this.count,
    required this.isUsed,
    required this.purpleCost,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = type.color;
    final hasInventory = count > 0;
    // Fiyat sadece envanter bitince anlamli — hakki varken fiyat gostermek kafa karistirir.
    final showCost = !isUsed && !hasInventory && purpleCost > 0;

    return SafeTapButton(
      onTap: onTap,
      builder: (context, isLoading, safeTap) => GestureDetector(
        onTap: safeTap,
        child: SizedBox(
          width: 56,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isUsed
                          ? context.appColors.surfaceElevated
                          : color.withValues(alpha: 0.15),
                      border: Border.all(
                        color: isUsed
                            ? context.appColors.textHint.withValues(alpha: 0.3)
                            : color.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: isLoading
                          ? const AppLoadingWidget.small()
                          : isUsed
                              ? Icon(Icons.check,
                                  size: 20, color: context.appColors.textHint)
                              : QIcon(type.iconPath, size: 22, color: color),
                    ),
                  ),
                  if (!isUsed && hasInventory && !isLoading)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: AppColors.inkOnDark,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: isUsed ? context.appColors.textHint : color,
                ),
                textAlign: TextAlign.center,
              ),
              if (showCost)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xxs),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const DiamondIcon.purple(size: 8, showGlow: false),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        '$purpleCost',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: color.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
