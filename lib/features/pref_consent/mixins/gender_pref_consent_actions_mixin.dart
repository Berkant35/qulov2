import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/pref_consent.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/network/failure_message.dart';
import 'package:qulo_v2/core/services/pref_analytics.dart';
import 'package:qulo_v2/features/pref_consent/pref_consent_dialogs.dart';
import 'package:qulo_v2/features/pref_consent/widgets/gender_pref_consent_actions.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

mixin GenderPrefConsentActionsMixin on ConsumerState<GenderPrefConsentActions> {
  bool isWithdrawing = false;

  /// Tercih kilitli (istismar riski) — değişiklik destek talebiyle, backoffice'ten.
  void requestChange() => ref.read(navigationServiceProvider).push(
        RouteNames.createTicket,
        extra: context.tr('gender_pref_ticket_subject'),
      );

  /// Tek yönlü: geri alınan rıza uygulamadan yeniden verilemez (sunucu CONSENT_RELOCK).
  Future<void> withdraw() async {
    final nav = ref.read(navigationServiceProvider);
    final confirmed = await PrefConsentDialogs.confirmWithdraw(context, nav);
    if (!confirmed || !mounted) return;
    setState(() => isWithdrawing = true);
    final result = await ref.read(userProvider.notifier).setPrefConsent(status: PrefConsent.declined);
    if (!mounted) return;
    setState(() => isWithdrawing = false);
    result.when(
      success: (_) => PrefAnalytics.consentAnswered(entryPoint: PrefEntryPoint.editProfile, granted: false),
      failure: (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(f.userMessageKey('error_general')))),
      ),
    );
  }
}
