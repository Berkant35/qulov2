import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/draft_badge.dart';

/// Bölüm başlığı + taslak rozeti; ikisi de yoksa hiçbir şey çizmez.
class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, required this.heading, required this.isDraft});

  final String? heading;
  final bool isDraft;

  @override
  Widget build(BuildContext context) {
    if (heading == null && !isDraft) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding, 0, AppSpacing.pagePadding, AppSpacing.sm),
      child: Row(
        children: [
          if (heading != null)
            Expanded(
              child: Text(
                heading!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            )
          else
            const Spacer(),
          if (isDraft) const DraftBadge(),
        ],
      ),
    );
  }
}
