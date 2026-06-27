import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/models/app_bottom_sheet.dart';
import 'package:qulo_v2/core/navigation/models/app_dialog.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/page_messages/data/models/page_message_model.dart';
import 'package:qulo_v2/features/page_messages/widgets/page_message_banner.dart';
import 'package:qulo_v2/features/page_messages/widgets/page_message_content.dart';
import 'package:qulo_v2/features/page_messages/widgets/page_message_inline_card.dart';
import 'package:qulo_v2/core/services/overlay_queue_service.dart';
import 'package:qulo_v2/core/services/overlay_request.dart';
import 'package:qulo_v2/providers/page_messages_provider.dart';

/// Bir sayfaya gömülür; o sayfanın uygun mesajını display_type'a göre gösterir.
///
/// inline / banner  → child widget olarak döner (SizedBox.shrink eğer mesaj yoksa)
/// bottom_sheet     → NavigationService.showAppBottomSheet overlay açar
/// modal            → NavigationService.showAppDialog overlay açar
class PageMessageHost extends ConsumerStatefulWidget {
  final String page;

  const PageMessageHost({super.key, required this.page});

  @override
  ConsumerState<PageMessageHost> createState() => _PageMessageHostState();
}

class _PageMessageHostState extends ConsumerState<PageMessageHost> {
  PageMessageModel? _inline;
  bool _dispatched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _dispatch());
  }

  void _dispatch() {
    if (_dispatched) return;
    final msg =
        ref.read(pageMessagesProvider.notifier).consumeForPage(widget.page);
    if (msg == null) return;
    _dispatched = true;
    ref.read(pageMessagesProvider.notifier).markShown(msg.id);

    switch (msg.displayType) {
      case 'inline_card':
      case 'banner':
        setState(() => _inline = msg);
      case 'bottom_sheet':
        OverlayQueueService.instance.enqueue(
          OverlayRequest(
            id: 'pagemsg_${msg.id}',
            priority: OverlayPriority.campaign + msg.priority,
            show: () async {
              if (!mounted) return;
              await _showOverlay(msg);
            },
          ),
        );
      case 'modal':
        OverlayQueueService.instance.enqueue(
          OverlayRequest(
            id: 'pagemsg_${msg.id}',
            priority: OverlayPriority.campaign + msg.priority,
            show: () async {
              if (!mounted) return;
              await _showOverlay(msg, isModal: true);
            },
          ),
        );
    }
  }

  Future<void> _showOverlay(PageMessageModel msg, {bool isModal = false}) async {
    var ctaUsed = false;

    void onClose() {
      ctaUsed = true;
      ref.read(navigationServiceProvider).closeOverlay();
    }

    final colors = context.appColors;
    final inner = Stack(
      children: [
        PageMessageContent(message: msg, onClose: onClose),
        Positioned(
          right: 0,
          top: 0,
          child: GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: Icon(Icons.close, size: 20, color: colors.textSecondary),
          ),
        ),
      ],
    );

    if (isModal) {
      // Ortalı modal: Material kart + sınırlı genişlik; showDialog'un yarı saydam barrier'ı.
      final dialogChild = Dialog(
        backgroundColor: colors.surfaceElevated,
        insetPadding: const EdgeInsets.all(AppSpacing.xl),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: inner,
          ),
        ),
      );
      await ref.read(navigationServiceProvider).showAppDialog(
            CustomDialog(name: 'page_message_${msg.id}', builder: (_) => dialogChild),
          );
    } else {
      // Tam genişlik bottom sheet: drag handle + içerik.
      final sheetChild = SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                PageMessageContent(message: msg, onClose: onClose),
              ],
            ),
          ),
        ),
      );
      await ref.read(navigationServiceProvider).showAppBottomSheet(
            CustomBottomSheet(name: 'page_message_${msg.id}', builder: (_) => sheetChild),
          );
    }

    if (!mounted) return;
    if (!ctaUsed) {
      ref.read(pageMessagesProvider.notifier).trackEvent(msg.id, 'dismissed');
    }
  }

  void _dismissInline() {
    final id = _inline?.id;
    if (id != null) {
      ref.read(pageMessagesProvider.notifier).trackEvent(id, 'dismissed');
    }
    setState(() => _inline = null);
  }

  @override
  Widget build(BuildContext context) {
    // fetch() ekran mount olduktan SONRA biterse (mount anında messages boştu),
    // mesajlar gelince yeniden dispatch et — yoksa banner hiç gösterilmez (timing yarışı).
    ref.listen(pageMessagesProvider, (prev, next) {
      if (!_dispatched && next.messages.isNotEmpty) {
        _dispatch();
      }
    });
    if (_inline == null) return const SizedBox.shrink();
    // banner → kompakt yatay şerit; inline_card → zengin dikey kart.
    return _inline!.displayType == 'banner'
        ? PageMessageBanner(message: _inline!, onDismiss: _dismissInline)
        : PageMessageInlineCard(message: _inline!, onDismiss: _dismissInline);
  }
}
