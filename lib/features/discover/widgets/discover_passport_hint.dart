import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/features/discover/mixins/discover_passport_hint_mixin.dart';
import 'package:qulo_v2/providers/passport_provider.dart';
import 'package:qulo_v2/providers/subscription_provider.dart';

/// Bos discover'da pasaport satisini/kullanimini gorunur kilan ipucu.
///
/// Her iki bos durumda da (havuz bos + dil kapisi) ayni ipucu gorunur:
/// dil kaynakli bos ekranda eksikti, pasaport satisi orada hic gorunmuyordu.
class DiscoverPassportHint extends ConsumerWidget with DiscoverPassportHintMixin {
  const DiscoverPassportHint({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hint = passportHint(
      passportActive: ref.watch(passportProvider).isActive,
      isPremium: ref.watch(subscriptionProvider).valueOrNull?.isPremium ?? false,
    );

    return TextButton.icon(
      onPressed: () => ref.read(navigationServiceProvider).push(hint.route),
      icon: const Icon(Icons.flight, size: 16),
      label: Text(context.tr(hint.labelKey)),
      style: TextButton.styleFrom(foregroundColor: context.appColors.primary),
    );
  }
}
