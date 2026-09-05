import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/features/page_messages/mixins/page_message_host_mixin.dart';
import 'package:qulo_v2/features/page_messages/widgets/page_message_banner.dart';
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

class _PageMessageHostState extends ConsumerState<PageMessageHost>
    with PageMessageHostMixin {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => dispatch());
  }

  @override
  Widget build(BuildContext context) {
    // fetch() ekran mount olduktan SONRA biterse (mount anında messages boştu),
    // mesajlar gelince yeniden dispatch et — yoksa banner hiç gösterilmez (timing yarışı).
    ref.listen(pageMessagesProvider, (prev, next) {
      if (!dispatched && next.messages.isNotEmpty) {
        dispatch();
      }
    });

    if (inline == null) return const SizedBox.shrink();

    // banner → kompakt yatay şerit; inline_card → zengin dikey kart.
    return inline!.displayType == 'banner'
        ? PageMessageBanner(message: inline!, onDismiss: dismissInline)
        : PageMessageInlineCard(message: inline!, onDismiss: dismissInline);
  }
}
