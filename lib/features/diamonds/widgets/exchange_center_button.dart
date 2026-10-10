import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/widgets/app_icon.dart';
import 'package:qulo_v2/core/widgets/feature_entry_card.dart';

/// Elmas ekranindan takas merkezine goturen kart butonu.
class ExchangeCenterButton extends StatelessWidget {
  const ExchangeCenterButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return FeatureEntryCard(
      icon: AppIcon(QIcons.bolt, color: colors.secondary, size: 22),
      title: context.tr('exchange_title'),
      subtitle: context.tr('exchange_subtitle'),
      accent: colors.secondary,
      secondaryAccent: colors.primary,
      onTap: onTap,
    );
  }
}
