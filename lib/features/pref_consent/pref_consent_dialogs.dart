import 'package:flutter/widgets.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';

/// "Rıza vermeden devam" ve "Rızamı geri al" onayları — tek metin seti, her yerde aynı.
abstract final class PrefConsentDialogs {
  static Future<bool> confirmDecline(BuildContext context, NavigationService nav) async =>
      await nav.showAppDialog<bool>(
        ConfirmDialog(
          name: 'pref_consent_decline',
          title: context.tr('pref_consent_decline_title'),
          message: context.tr('pref_consent_decline_message'),
          confirmText: context.tr('pref_consent_decline_confirm'),
        ),
      ) ==
      true;

  static Future<bool> confirmWithdraw(BuildContext context, NavigationService nav) async =>
      await nav.showAppDialog<bool>(
        ConfirmDialog(
          name: 'pref_consent_withdraw',
          title: context.tr('pref_consent_withdraw_title'),
          message: context.tr('pref_consent_withdraw_message'),
          confirmText: context.tr('pref_consent_withdraw_confirm'),
          isDestructive: true,
        ),
      ) ==
      true;
}
