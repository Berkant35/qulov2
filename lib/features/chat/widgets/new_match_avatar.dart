import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/match_model.dart';

class NewMatchAvatar extends StatelessWidget {
  final MatchModel match;
  final VoidCallback onTap;
  const NewMatchAvatar({super.key, required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final u = match.user;
    final photo = u?.photos?.isNotEmpty == true ? u!.photos!.first : null;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.surface,
              backgroundImage: photo != null ? CachedNetworkImageProvider(photo) : null,
              child: photo == null ? Icon(Icons.person, color: theme.hintColor) : null,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            width: 64,
            child: Text(
              u?.name ?? '?',
              style: theme.textTheme.labelSmall,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
