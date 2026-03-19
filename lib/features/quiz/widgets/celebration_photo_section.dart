import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';

class CelebrationPhotoSection extends StatelessWidget {
  final Animation<double> photoSlide;
  final Listenable animation;
  final String? myPhotoUrl;
  final String? targetPhotoUrl;
  final bool matched;

  const CelebrationPhotoSection({
    super.key,
    required this.photoSlide,
    required this.animation,
    required this.myPhotoUrl,
    required this.targetPhotoUrl,
    required this.matched,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.translate(
              offset: Offset(-photoSlide.value, 0),
              child: CelebrationPhotoCircle(photoUrl: myPhotoUrl),
            ),
            const SizedBox(width: AppSpacing.md),
            Opacity(
              opacity: 1.0 - (photoSlide.value / 50.0).clamp(0.0, 1.0),
              child: Icon(
                Icons.favorite,
                color: matched ? AppColors.primary : AppColors.error,
                size: 32,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Transform.translate(
              offset: Offset(photoSlide.value, 0),
              child: CelebrationPhotoCircle(photoUrl: targetPhotoUrl),
            ),
          ],
        );
      },
    );
  }
}

class CelebrationPhotoCircle extends StatelessWidget {
  final String? photoUrl;

  const CelebrationPhotoCircle({super.key, required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: ClipOval(
        child: photoUrl != null && photoUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: photoUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppColors.surfaceElevated,
                  child: AppLoadingWidget.small(),
                ),
                errorWidget: (_, __, ___) => const _PersonPlaceholder(),
              )
            : const _PersonPlaceholder(),
      ),
    );
  }
}

class _PersonPlaceholder extends StatelessWidget {
  const _PersonPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceElevated,
      child: const Icon(
        Icons.person,
        color: AppColors.textSecondary,
        size: 40,
      ),
    );
  }
}
