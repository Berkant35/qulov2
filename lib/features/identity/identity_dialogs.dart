import 'package:flutter/widgets.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';

/// Etiketleri silme onayı — metin tek yerde.
abstract final class IdentityDialogs {
  static Future<bool> confirmClear(BuildContext context, NavigationService nav) async =>
      await nav.showAppDialog<bool>(
        ConfirmDialog(
          name: 'identity_clear',
          title: context.tr('identity_clear_title'),
          message: context.tr('identity_clear_message'),
          confirmText: context.tr('identity_clear_confirm'),
          isDestructive: true,
        ),
      ) ==
      true;
}
