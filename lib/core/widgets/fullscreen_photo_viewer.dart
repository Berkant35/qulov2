import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';

class FullscreenPhotoViewer extends StatelessWidget {
  final String imageUrl;
  final String? heroTag;

  const FullscreenPhotoViewer({
    super.key,
    required this.imageUrl,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final tag = heroTag ?? imageUrl;

    return Scaffold(
      backgroundColor: AppColors.scrimBase,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onScrim),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: Hero(
          tag: tag,
          child: InteractiveViewer(
            // memCacheWidth BILEREK yok: InteractiveViewer yakinlastirma yapiyor,
            // alt orneklenmis bitmap zoom'da bulanik gorunur. Uygulamadaki tek
            // tam cozunurluk istisnasi burasi.
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: AppLoadingWidget.small(),
              ),
              errorWidget: (context, url, error) => Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.onScrim.withValues(alpha: 0.54),
                  size: 48,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
