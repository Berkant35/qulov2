import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';
import 'package:qulo_v2/features/chat/mixins/chat_question_reward_cards_mixin.dart';
import 'package:qulo_v2/features/chat/widgets/power_ledger_card.dart';
import 'package:qulo_v2/providers/rainbow_flag.dart';

/// Sonuç ekranının ödül/harcama kartları: yeşil, Rainbow (yalnız sunucu açtıysa), mor.
class ChatQuestionRewardCards extends ConsumerWidget with ChatQuestionRewardCardsWidgetMixin {
  final List<PowerUsageRecord> powerUsages;

  const ChatQuestionRewardCards({super.key, required this.powerUsages});

  static const greenCardKey = ValueKey('reward_card_green');
  static const rainbowCardKey = ValueKey('reward_card_rainbow');
  static const purpleCardKey = ValueKey('reward_card_purple');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rainbowEnabled = ref.watchRainbowEnabled();
    final totalGreen = powerUsages.totalGreenEarned;
    final totalRainbow = powerUsages.totalRainbowEarned;
    final totalPurple = powerUsages.totalPurpleSpent;
    final purpleByPower = powerUsages.purpleByPower;

    return Column(
      spacing: AppSpacing.md,
      children: [
        if (totalGreen > 0)
          PowerLedgerCard(
            key: greenCardKey,
            color: context.appColors.success,
            icon: const DiamondIcon.green(size: 24, showGlow: false),
            title: countText(context, 'result_green_earned', totalGreen),
            subtitle: context.tr('result_green_subtitle'),
            rows: labeledRows(context, powerUsages.greenByPower),
            amountPrefix: '+',
          ),
        // Market dışı kullanıcıda Rainbow arka planda birikir, gösterilmez (spec §2.4). Güç dökümü
        // yok (tek satır, açılmaz): Rainbow payı ödenmiş morun toplamından gelir.
        if (rainbowEnabled && totalRainbow > 0)
          PowerLedgerCard(
            key: rainbowCardKey,
            color: context.appColors.rainbow,
            icon: const DiamondIcon.rainbow(size: 24, showGlow: false),
            title: countText(context, 'result_rainbow_earned', totalRainbow),
            subtitle: context.tr('result_rainbow_subtitle'),
            rows: const {},
            amountPrefix: '+',
          ),
        if (totalPurple > 0)
          PowerLedgerCard(
            key: purpleCardKey,
            color: context.appColors.primary,
            icon: const DiamondIcon.purple(size: 24, showGlow: false),
            title: countText(context, 'result_purple_spent', totalPurple),
            subtitle: purpleSubtitle(context, purpleByPower),
            rows: labeledRows(context, purpleByPower),
            amountPrefix: '-',
          ),
      ],
    );
  }
}
