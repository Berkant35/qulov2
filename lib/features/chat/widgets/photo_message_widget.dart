import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/fullscreen_photo_viewer.dart';

class PhotoMessageWidget extends StatelessWidget {
  final String imageUrl;
  final bool isMine;

  const PhotoMessageWidget({
    super.key,
    required this.imageUrl,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => FullscreenPhotoViewer(imageUrl: imageUrl),
          ),
        );
      },
      child: Hero(
        tag: imageUrl,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 200),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            memCacheWidth: 600,
            placeholder: (context, url) => Container(
              width: 200,
              height: 200,
              color: context.appColors.surfaceElevated,
              child: const Center(
                child: AppLoadingWidget.small(),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              width: 200,
              height: 200,
              color: context.appColors.surfaceElevated,
              child: const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.onScrimSubtle,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
