import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/features/pref_consent/mixins/gender_pref_consent_actions_mixin.dart';
import 'package:qulo_v2/providers/user_provider.dart';

/// Düzenleme ekranında kilitli tercihin altındaki iki aksiyon: değişiklik talebi + rızayı geri al.
class GenderPrefConsentActions extends ConsumerStatefulWidget {
  const GenderPrefConsentActions({super.key});

  @override
  ConsumerState<GenderPrefConsentActions> createState() => _GenderPrefConsentActionsState();
}

class _GenderPrefConsentActionsState extends ConsumerState<GenderPrefConsentActions>
    with GenderPrefConsentActionsMixin {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider).valueOrNull;
    final canWithdraw = user != null && !user.prefConsentDeclined && user.genderPrefSetAt != null;
    return Wrap(
      spacing: 8,
      children: [
        TextButton(onPressed: requestChange, child: Text(context.tr('gender_pref_request_change'))),
        if (canWithdraw)
          TextButton(
            onPressed: isWithdrawing ? null : withdraw,
            child: Text(context.tr('pref_consent_withdraw')),
          ),
      ],
    );
  }
}
