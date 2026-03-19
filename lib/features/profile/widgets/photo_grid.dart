import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';

class PhotoGridFull extends StatelessWidget {
  final List<String?> photos;
  final bool editMode;
  final ValueChanged<int> onSlotTap;

  const PhotoGridFull({
    super.key,
    required this.photos,
    this.editMode = false,
    required this.onSlotTap,
  });

  String? _photoAt(int index) =>
      index < photos.length ? photos[index] : null;

  @override
  Widget build(BuildContext context) {
    const gap = 6.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final smallSlotSize = (totalWidth - gap * 2) / 3;
        final bigSlotSize = smallSlotSize * 2 + gap;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Top Row ───
            SizedBox(
              height: bigSlotSize,
              child: Row(
                children: [
                  // Big slot (index 0)
                  _PhotoSlot(
                    width: bigSlotSize,
                    height: bigSlotSize,
                    photoUrl: _photoAt(0),
                    editMode: editMode,
                    onTap: () => onSlotTap(0),
                  ),
                  const SizedBox(width: gap),
                  // Right column (index 1, 2)
                  Expanded(
                    child: Column(
                      children: [
                        _PhotoSlot(
                          width: smallSlotSize,
                          height: smallSlotSize,
                          photoUrl: _photoAt(1),
                          editMode: editMode,
                          onTap: () => onSlotTap(1),
                        ),
                        const SizedBox(height: gap),
                        _PhotoSlot(
                          width: smallSlotSize,
                          height: smallSlotSize,
                          photoUrl: _photoAt(2),
                          editMode: editMode,
                          onTap: () => onSlotTap(2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: gap),
            // ─── Bottom Row ───
            SizedBox(
              height: smallSlotSize,
              child: Row(
                children: [
                  _PhotoSlot(
                    width: smallSlotSize,
                    height: smallSlotSize,
                    photoUrl: _photoAt(3),
                    editMode: editMode,
                    onTap: () => onSlotTap(3),
                  ),
                  const SizedBox(width: gap),
                  _PhotoSlot(
                    width: smallSlotSize,
                    height: smallSlotSize,
                    photoUrl: _photoAt(4),
                    editMode: editMode,
                    onTap: () => onSlotTap(4),
                  ),
                  const SizedBox(width: gap),
                  _PhotoSlot(
                    width: smallSlotSize,
                    height: smallSlotSize,
                    photoUrl: _photoAt(5),
                    editMode: editMode,
                    onTap: () => onSlotTap(5),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  final double width;
  final double height;
  final String? photoUrl;
  final bool editMode;
  final VoidCallback onTap;

  const _PhotoSlot({
    required this.width,
    required this.height,
    required this.photoUrl,
    required this.editMode,
    required this.onTap,
  });

  bool get _isFilled => photoUrl != null && photoUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: _isFilled
              ? null
              : Border.all(
                  color: Theme.of(context).hintColor.withValues(alpha: 0.39),
                  width: 1.5,
                ),
        ),
        child: _isFilled ? _filledContent() : _emptyContent(context),
      ),
    );
  }

  Widget _emptyContent(BuildContext context) {
    return Center(
      child: QIcon(
        QIcons.icImagePlus,
        color: Theme.of(context).hintColor,
        size: 28,
      ),
    );
  }

  Widget _filledContent() {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: photoUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            child: const Center(
              child: AppLoadingWidget.small(),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            child: Center(
              child: QIcon(
                QIcons.icUser,
                color: Theme.of(context).hintColor,
                size: 32,
              ),
            ),
          ),
        ),
        if (editMode)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.59),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: QIcon(
                  QIcons.icPencil,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
