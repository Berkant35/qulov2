import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/models/app_bottom_sheet.dart';
import 'package:qulo_v2/core/navigation/models/app_dialog.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/page_messages/data/models/page_message_model.dart';
import 'package:qulo_v2/features/page_messages/widgets/page_message_content.dart';
import 'package:qulo_v2/features/page_messages/widgets/page_message_inline_card.dart';
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
        _showOverlay(msg);
      case 'modal':
        _showOverlay(msg, isModal: true);
    }
  }

  Future<void> _showOverlay(PageMessageModel msg, {bool isModal = false}) async {
    var ctaUsed = false;

    void onClose() {
      ctaUsed = true;
      ref.read(navigationServiceProvider).closeOverlay();
    }

    final content = Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: PageMessageContent(message: msg, onClose: onClose),
    );

    if (isModal) {
      await ref.read(navigationServiceProvider).showAppDialog(
            CustomDialog(name: 'page_message_${msg.id}', builder: (_) => content),
          );
    } else {
      await ref.read(navigationServiceProvider).showAppBottomSheet(
            CustomBottomSheet(name: 'page_message_${msg.id}', builder: (_) => content),
          );
    }

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
    if (_inline == null) return const SizedBox.shrink();
    return PageMessageInlineCard(message: _inline!, onDismiss: _dismissInline);
  }
}
