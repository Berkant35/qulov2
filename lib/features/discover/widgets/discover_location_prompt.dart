import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/widgets/empty_state_view.dart';
import 'package:qulo_v2/features/discover/mixins/discover_location_prompt_mixin.dart';

/// Konum yokken Discover'ın gövdesi: neden gerektiğini anlatan kart + tek eylem
/// (izin iste / Ayarlar / konum ayarları). Sahte konumda engelleyici uyarı.
class DiscoverLocationPrompt extends ConsumerStatefulWidget {
  final String error;

  const DiscoverLocationPrompt({super.key, required this.error});

  @override
  ConsumerState<DiscoverLocationPrompt> createState() => _DiscoverLocationPromptState();
}

class _DiscoverLocationPromptState extends ConsumerState<DiscoverLocationPrompt>
    with DiscoverLocationPromptMixin {
  @override
  void initState() {
    super.initState();
    logLocationPromptShown(widget.error);
  }

  @override
  void didUpdateWidget(DiscoverLocationPrompt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.error != widget.error) logLocationPromptShown(widget.error);
  }

  @override
  Widget build(BuildContext context) {
    final content = promptFor(widget.error);
    final colors = context.appColors;

    return EmptyStateView(
      icon: Icon(
        content.isMock ? Icons.gps_off : Icons.near_me_outlined,
        size: 64,
        color: content.isMock ? colors.error : colors.primary,
      ),
      title: context.tr(content.titleKey),
      message: content.messageKey == null ? null : context.tr(content.messageKey!),
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: () => onLocationPromptTap(ref, widget.error),
            style: FilledButton.styleFrom(
              backgroundColor: content.isMock ? colors.error : colors.primaryDark,
            ),
            child: Text(context.tr(content.ctaKey)),
          ),
        ),
        if (content.offersCity)
          TextButton(
            onPressed: () => openCityPicker(ref, widget.error),
            child: Text(context.tr('city_picker_choose_city')),
          ),
      ],
    );
  }
}
