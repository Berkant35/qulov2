import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/widgets/feature_entry_card.dart';

/// Elmaslar ekranındaki market girişi (spec §7.6).
class RainbowMarketCard extends StatelessWidget {
  const RainbowMarketCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return FeatureEntryCard(
      icon: const DiamondIcon.rainbow(size: 22),
      title: context.tr('market_title'),
      subtitle: context.tr('market_entry_subtitle'),
      accent: colors.rainbow,
      secondaryAccent: colors.rainbowDark,
      onTap: onTap,
    );
  }
}
