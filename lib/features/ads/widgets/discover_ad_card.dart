import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/circle_icon_button.dart';
import 'package:qulo_v2/features/ads/mixins/discover_ad_card_mixin.dart';
import 'package:qulo_v2/features/ads/widgets/ad_label_bar.dart';
import 'package:qulo_v2/features/discover/widgets/discover_solve_button.dart';

/// Discover destesinde profil kartının yerine geçen "Reklam" kartı: aynı yerleşim
/// ([DiscoverCardView] ile aynı dış boşluk, kart köşesi ve alt buton alanı),
/// tam ekran değil, geçilebilir.
class DiscoverAdCard extends ConsumerWidget with DiscoverAdCardMixin {
  const DiscoverAdCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ad = currentAd(ref);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: ColoredBox(
                color: AppColors.surface,
                child: Column(
                  children: [
                    AdLabelBar(onDragEnd: (d) => onLabelDragEnd(ref, d)),
                    Expanded(child: ad?.build() ?? const SizedBox.shrink()),
                  ],
                ),
              ),
            ),
          ),
          // Reklamın kendi CTA'sı ile "Devam" arasında net boşluk: yanlışlıkla dokunma
          // (AdMob geçersiz tıklama / politika) riskini azaltır.
          const SizedBox(height: AppSpacing.lg),
          DiscoverSolveButton(
            label: context.tr('ad_continue'),
            onTap: () => skip(ref),
          ),
          const SizedBox(height: AppSpacing.sm),
          CircleIconButton(
            iconPath: QIcons.icX,
            iconColor: context.appColors.error,
            backgroundColor: Theme.of(context).colorScheme.surface,
            borderColor: context.appColors.error,
            onTap: () => skip(ref),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
