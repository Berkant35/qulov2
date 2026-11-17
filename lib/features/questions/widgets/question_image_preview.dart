import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

/// Soru fotoğrafı önizlemesi: yeni seçilen bayt ya da kayıtlı sorunun imzalı
/// URL'si. Moderasyon sürüyorsa "İnceleniyor" etiketi.
class QuestionImagePreview extends StatelessWidget {
  static const double _height = 160;

  final Uint8List? bytes;
  final String? url;
  final bool inReview;
  final VoidCallback onRemove;

  const QuestionImagePreview({
    super.key,
    required this.bytes,
    required this.url,
    required this.inReview,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: context.appColors.surfaceElevated,
      child: Icon(Icons.broken_image_outlined, color: context.appColors.textHint),
    );

    return SizedBox(
      height: _height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: bytes != null
                ? Image.memory(bytes!, fit: BoxFit.cover)
                : CachedNetworkImage(
                    imageUrl: url ?? '',
                    fit: BoxFit.cover,
                    placeholder: (_, _) => placeholder,
                    errorWidget: (_, _, _) => placeholder,
                  ),
          ),
          if (inReview)
            Positioned(
              left: AppSpacing.sm,
              bottom: AppSpacing.sm,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.scrimDark,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  child: Text(
                    context.tr('question_image_in_review'),
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: AppColors.onScrim),
                  ),
                ),
              ),
            ),
          Positioned(
            top: AppSpacing.xs,
            right: AppSpacing.xs,
            child: IconButton(
              onPressed: onRemove,
              tooltip: context.tr('question_media_remove'),
              style: IconButton.styleFrom(backgroundColor: AppColors.scrimDark),
              icon: const Icon(Icons.close, color: AppColors.onScrim),
            ),
          ),
        ],
      ),
    );
  }
}
