import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/match_model.dart';
import 'package:qulo_v2/features/chat/widgets/new_match_avatar.dart';

/// Eşleşmeler ekranının üstündeki yeni eşleşmeler (henüz mesaj yok) şeridi.
class NewMatchesStrip extends StatelessWidget {
  const NewMatchesStrip({super.key, required this.matches, required this.onTap});

  final List<MatchModel> matches;
  final void Function(MatchModel match) onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding, AppSpacing.sm, AppSpacing.pagePadding, AppSpacing.md,
          ),
          child: Text(context.tr('new_matches'), style: theme.textTheme.titleMedium),
        ),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
            itemCount: matches.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.lg),
            itemBuilder: (context, index) {
              final m = matches[index];
              return NewMatchAvatar(match: m, onTap: () => onTap(m));
            },
          ),
        ),
        Divider(color: theme.colorScheme.outline, height: 1),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
