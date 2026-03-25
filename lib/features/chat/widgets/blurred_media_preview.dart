import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/fullscreen_photo_viewer.dart';

class BlurredMediaPreview extends StatelessWidget {
  final String? mediaUrl;
  final String mediaType;
  final bool isRevealed;
  final double height;

  const BlurredMediaPreview({
    super.key,
    this.mediaUrl,
    required this.mediaType,
    this.isRevealed = false,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    if (mediaType == 'audio') {
      return _AudioPreview(isRevealed: isRevealed, height: height);
    }

    if (mediaUrl == null) return const SizedBox.shrink();

    // Revealed: tappable with original aspect ratio
    if (isRevealed) {
      final heroTag = 'reward_preview_$mediaUrl';
      return GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => FullscreenPhotoViewer(
                imageUrl: mediaUrl!,
                heroTag: heroTag,
              ),
            ),
          );
        },
        child: Hero(
          tag: heroTag,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: CachedNetworkImage(
                imageUrl: mediaUrl!,
                width: double.infinity,
                fit: BoxFit.contain,
                errorWidget: (context, __, ___) => Container(
                  height: height,
                  color: context.appColors.surfaceElevated,
                  child: Icon(Icons.image, color: context.appColors.textHint),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Locked: fixed height, blurred, not tappable
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: mediaUrl!,
              fit: BoxFit.cover,
              errorWidget: (context, __, ___) => Container(
                color: context.appColors.surfaceElevated,
                child: Icon(Icons.image, color: context.appColors.textHint),
              ),
            ),
            // Blur overlay
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: AppColors.scrimLight,
              ),
            ),
            // Lock icon
            Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.scrimDark,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: AppColors.onScrim,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioPreview extends StatelessWidget {
  final bool isRevealed;
  final double height;

  const _AudioPreview({required this.isRevealed, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: context.appColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: context.appColors.border,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.graphic_eq_rounded,
                  size: 36,
                  color: isRevealed
                      ? context.appColors.primary
                      : context.appColors.textHint,
                ),
                if (!isRevealed)
                  Icon(
                    Icons.lock_rounded,
                    size: 18,
                    color: AppColors.onScrimSubtle,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              isRevealed ? 'Ses Ödülü' : 'Kilitli Ses',
              style: TextStyle(
                color: isRevealed
                    ? context.appColors.primary
                    : context.appColors.textHint,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
