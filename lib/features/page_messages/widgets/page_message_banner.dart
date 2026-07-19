import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/services/deep_link_parser.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/features/page_messages/data/models/page_message_model.dart';
import 'package:qulo_v2/providers/locale_provider.dart';
import 'package:qulo_v2/providers/page_messages_provider.dart';

/// Kompakt yatay banner — düşük yükseklik, küçük görsel (varsa).
/// inline_card'a göre daha hafif: başlık 1 satır, metin en fazla 2 satır,
/// CTA butonu yerine tüm banner tıklanabilir (action_url varsa).
class PageMessageBanner extends ConsumerWidget {
  final PageMessageModel message;
  final VoidCallback onDismiss;

  const PageMessageBanner({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider).languageCode;
    final c = message.localized(locale);
    final colors = context.appColors;
    final tappable = message.actionUrl != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0,
      ),
      child: Material(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: tappable ? () => _onTap(ref) : null,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: colors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                if (message.imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: CachedNetworkImage(
                      imageUrl: message.imageUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (c.body.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          c.body,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                GestureDetector(
                  onTap: onDismiss,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: Icon(Icons.close, size: 18, color: colors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(WidgetRef ref) {
    ref.read(pageMessagesProvider.notifier).trackEvent(message.id, 'clicked');
    final url = message.actionUrl;
    // Navigasyondan önce banner'ı kaldır — sheet ile simetrik (bkz. page_message_content).
    onDismiss();
    if (url != null) {
      final fullUrl = url.startsWith('/') ? 'https://quloapp.com$url' : url;
      final result = DeepLinkParser.parse(Uri.parse(fullUrl));
      if (result != null) {
        ref.read(navigationServiceProvider).navigateDeepLink(result);
      }
    }
  }
}
