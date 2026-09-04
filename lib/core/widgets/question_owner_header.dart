import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

/// Soru cozerken karsi kisinin kimligi: avatar + "Isim • 3.2 km".
/// Chat sorusu ve quiz ekrani ayni satiri kullanir; isim yoksa hic cizilmez.
class QuestionOwnerHeader extends StatelessWidget {
  final String? name;
  final String? photoUrl;
  final double? distanceKm;

  const QuestionOwnerHeader({
    super.key,
    required this.name,
    this.photoUrl,
    this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    final name = this.name;
    if (name == null) return const SizedBox.shrink();

    final distance = distanceKm;
    final label = distance == null ? name : '$name • ${context.fmt.distance(distance)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: context.appColors.surfaceElevated,
            backgroundImage:
                photoUrl != null ? CachedNetworkImageProvider(photoUrl!) : null,
            child: photoUrl == null
                ? Icon(Icons.person, size: 20, color: context.appColors.textSecondary)
                : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: context.appColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
