import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/models/app_bottom_sheet.dart';
import 'package:qulo_v2/core/navigation/models/app_dialog.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/services/overlay_queue_service.dart';
import 'package:qulo_v2/core/services/overlay_request.dart';
import 'package:qulo_v2/data/models/page_message_model.dart';
import 'package:qulo_v2/features/page_messages/widgets/page_message_host.dart';
import 'package:qulo_v2/features/page_messages/widgets/page_message_modal_card.dart';
import 'package:qulo_v2/features/page_messages/widgets/page_message_sheet.dart';
import 'package:qulo_v2/providers/page_messages_provider.dart';

/// [PageMessageHost] icin sunum-disi logic: mesaji tuketip display_type'a gore
/// inline gosterir veya overlay kuyruguna alir.
mixin PageMessageHostMixin on ConsumerState<PageMessageHost> {
  PageMessageModel? inline;
  bool dispatched = false;

  void dispatch() {
    if (dispatched) return;
    final msg =
        ref.read(pageMessagesProvider.notifier).consumeForPage(widget.page);
    if (msg == null) return;
    dispatched = true;
    ref.read(pageMessagesProvider.notifier).markShown(msg.id);

    switch (msg.displayType) {
      case 'inline_card':
      case 'banner':
        setState(() => inline = msg);
      case 'bottom_sheet':
        _enqueueOverlay(msg, isModal: false);
      case 'modal':
        _enqueueOverlay(msg, isModal: true);
    }
  }

  void _enqueueOverlay(PageMessageModel msg, {required bool isModal}) {
    OverlayQueueService.instance.enqueue(
      OverlayRequest(
        id: 'pagemsg_${msg.id}',
        priority: OverlayPriority.campaign + msg.priority,
        show: () async {
          if (!mounted) return;
          await showOverlay(msg, isModal: isModal);
        },
      ),
    );
  }

  Future<void> showOverlay(PageMessageModel msg, {bool isModal = false}) async {
    var ctaUsed = false;

    void onClose() {
      ctaUsed = true;
      ref.read(navigationServiceProvider).closeOverlay();
    }

    final nav = ref.read(navigationServiceProvider);
    if (isModal) {
      await nav.showAppDialog(
        CustomDialog(
          name: 'page_message_${msg.id}',
          builder: (_) => PageMessageModalCard(message: msg, onClose: onClose),
        ),
      );
    } else {
      await nav.showAppBottomSheet(
        CustomBottomSheet(
          name: 'page_message_${msg.id}',
          builder: (_) => PageMessageSheet(message: msg, onClose: onClose),
        ),
      );
    }

    if (!mounted) return;
    if (!ctaUsed) {
      ref.read(pageMessagesProvider.notifier).trackEvent(msg.id, 'dismissed');
    }
  }

  void dismissInline() {
    final id = inline?.id;
    if (id != null) {
      ref.read(pageMessagesProvider.notifier).trackEvent(id, 'dismissed');
    }
    setState(() => inline = null);
  }
}
