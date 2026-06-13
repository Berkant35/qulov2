import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

class ProfilePhotoGallery extends StatefulWidget {
  final List<String> photos;
  final VoidCallback onClose;
  final void Function(int index, int total)? onPhotoChanged;

  const ProfilePhotoGallery({
    super.key,
    required this.photos,
    required this.onClose,
    this.onPhotoChanged,
  });

  @override
  State<ProfilePhotoGallery> createState() => _ProfilePhotoGalleryState();
}

class _ProfilePhotoGalleryState extends State<ProfilePhotoGallery> {
  final PageController _controller = PageController();
  int _current = 0;

  List<String> get _photos => widget.photos.isEmpty ? [''] : widget.photos;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    if (page < 0 || page >= _photos.length) return;
    if (!_controller.hasClients) return;
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final theme = Theme.of(context);
    final height = mq.size.height * 0.55;
    final halfWidth = mq.size.width / 2;
    final topPadding = mq.padding.top;

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          // Photos
          PageView.builder(
            controller: _controller,
            itemCount: _photos.length,
            onPageChanged: (i) {
              setState(() => _current = i);
              widget.onPhotoChanged?.call(i, _photos.length);
            },
            itemBuilder: (context, index) {
              final url = _photos[index];
              if (url.isEmpty) {
                return Container(
                  color: theme.colorScheme.surface,
                  child: Center(
                    child: Icon(
                      Icons.person,
                      size: 80,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                );
              }
              return GestureDetector(
                onTapUp: (details) {
                  if (details.globalPosition.dx > halfWidth) {
                    _goTo(_current + 1);
                  } else {
                    _goTo(_current - 1);
                  }
                },
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  memCacheWidth: 1080,
                  placeholder: (ctx, __) => Container(color: Theme.of(ctx).colorScheme.surface),
                  errorWidget: (_, __, ___) => Container(
                    color: theme.colorScheme.surface,
                    child: Center(
                      child: Icon(
                        Icons.broken_image,
                        color: context.appColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Gradient overlay at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 80,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),

          // Bar indicators (top)
          if (_photos.length > 1)
            Positioned(
              top: topPadding + AppSpacing.sm,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              child: Row(
                children: List.generate(_photos.length, (i) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: EdgeInsets.symmetric(
                        horizontal: _photos.length > 6 ? 1 : 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: i == _current
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  );
                }),
              ),
            ),

          // Close button
          Positioned(
            top: topPadding + AppSpacing.sm,
            left: AppSpacing.md,
            child: GestureDetector(
              onTap: widget.onClose,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),

          // Photo counter (top right)
          if (_photos.length > 1)
            Positioned(
              top: topPadding + AppSpacing.sm + AppSpacing.md,
              right: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  '${_current + 1}/${_photos.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
