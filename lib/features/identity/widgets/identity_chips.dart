import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/identity_labels.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/identity_model.dart';

/// Kimlik & yönelim etiketlerinin salt okunur küçük çipleri (profil detayı, düzenleme özeti).
/// Önce yönelim, sonra kimlik; boş modelde hiçbir şey çizmez.
class IdentityChips extends StatelessWidget {
  final VisibleIdentityModel identity;

  const IdentityChips({super.key, required this.identity});

  @override
  Widget build(BuildContext context) {
    if (identity.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        for (final label in identity.orientationLabels)
          _IdentityChip(textKey: IdentityLabels.orientationKey(label)),
        for (final label in identity.genderLabels)
          _IdentityChip(textKey: IdentityLabels.genderKey(label)),
      ],
    );
  }
}

class _IdentityChip extends StatelessWidget {
  final String textKey;

  const _IdentityChip({required this.textKey});

  @override
  Widget build(BuildContext context) {
    final color = context.appColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        context.tr(textKey),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
