import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

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
            if (!isRevealed) ...[
              // Blur overlay
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.2),
                ),
              ),
              // Lock icon
              Center(
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
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
                    color: Colors.white.withValues(alpha: 0.8),
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
