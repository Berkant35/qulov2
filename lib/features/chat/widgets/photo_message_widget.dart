import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';

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
            builder: (_) => _FullScreenPhotoViewer(imageUrl: imageUrl),
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
            placeholder: (context, url) => Container(
              width: 200,
              height: 200,
              color: AppColors.surfaceInput,
              child: const Center(
                child: AppLoadingWidget.small(),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              width: 200,
              height: 200,
              color: AppColors.surfaceInput,
              child: const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
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

class _FullScreenPhotoViewer extends StatelessWidget {
  final String imageUrl;

  const _FullScreenPhotoViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: Hero(
          tag: imageUrl,
          child: InteractiveViewer(
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: AppLoadingWidget.small(),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
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
