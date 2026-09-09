import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/widgets/empty_state_view.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/routing/route_names.dart';

/// Aday havuzunda kisi var ama hicbiri kullanicinin dilinde soru yazmamis.
///
/// Radius slider gostermek anlamsiz olurdu: mesafe zaten kademeli olarak
/// sinirsiza kadar geniyor, eleyen dil kapisi. Dil kapisi bilincli olarak
/// gevsetilmiyor — okunamayan soru cozulemez, cozulemeyen quiz elmas yakar.
class DiscoverEmptyLanguage extends ConsumerWidget {
  const DiscoverEmptyLanguage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EmptyStateView(
      icon: QIcon(QIcons.icCompassOff, size: 64, color: context.appColors.textHint),
      title: context.tr('discover_empty_language_title'),
      message: context.tr('discover_empty_language_hint'),
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            // Dil tercihi UI'si profil duzenleme ekraninda
            // (features/profile/widgets/edit_profile_preferences_section.dart).
            onPressed: () => ref.read(navigationServiceProvider).push(RouteNames.editProfile),
            style: FilledButton.styleFrom(
              backgroundColor: context.appColors.primaryDark,
            ),
            child: Text(context.tr('discover_empty_language_cta')),
          ),
        ),
      ],
    );
  }
}
