import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

/// Apple standard EULA URL (required by App Store guideline 3.1.2(c))
const _appleEulaUrl =
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

/// Legal links (Terms of Use + Privacy Policy) shown on subscription screens.
/// Required by Apple for auto-renewable subscription compliance.
class SubscriptionLegalLinks extends ConsumerWidget {
  const SubscriptionLegalLinks({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final linkStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      decoration: TextDecoration.underline,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => ref.read(urlLauncherManagerProvider).launch(_appleEulaUrl),
          child: Text(
            context.tr('sub_terms_of_use'),
            style: linkStyle,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            '|',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        GestureDetector(
          onTap: () =>
              ref.read(navigationServiceProvider).push(RouteNames.privacyPolicy),
          child: Text(
            context.tr('sub_privacy_policy'),
            style: linkStyle,
          ),
        ),
      ],
    );
  }
}
