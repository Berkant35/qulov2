import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/services/deep_link_parser.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/features/page_messages/data/models/page_message_model.dart';
import 'package:qulo_v2/providers/locale_provider.dart';
import 'package:qulo_v2/providers/page_messages_provider.dart';

class PageMessageContent extends ConsumerWidget {
  final PageMessageModel message;
  final VoidCallback onClose;

  const PageMessageContent({
    super.key,
    required this.message,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider).languageCode;
    final c = message.localized(locale);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.imageUrl != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: CachedNetworkImage(
              imageUrl: message.imageUrl!,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Text(c.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(c.body, style: Theme.of(context).textTheme.bodyMedium),
        if (c.ctaLabel.isNotEmpty && message.actionUrl != null) ...[
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: c.ctaLabel,
            onPressed: () => _onCta(ref),
          ),
        ],
      ],
    );
  }

  void _onCta(WidgetRef ref) {
    ref.read(pageMessagesProvider.notifier).trackEvent(message.id, 'clicked');
    final url = message.actionUrl;
    if (url != null) {
      // GÜVENLİK (spec §11 T1): yalnızca parse → navigateDeepLink.
      // handleDeepLink(rawString) KULLANILMAZ — parser'ı atlar, open redirect açığı verir.
      // Internal path (/...) → tam URL'e çevir ki host doğrulaması çalışsın.
      final fullUrl =
          url.startsWith('/') ? 'https://quloapp.com$url' : url;
      final result = DeepLinkParser.parse(Uri.parse(fullUrl));
      if (result != null) {
        ref.read(navigationServiceProvider).navigateDeepLink(result);
      }
      // result == null → parse başarısız / bilinmeyen host → hiçbir şey yapma
    }
    onClose();
  }
}
