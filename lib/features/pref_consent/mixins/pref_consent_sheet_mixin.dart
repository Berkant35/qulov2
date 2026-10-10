import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/pref_consent.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/network/failure_message.dart';
import 'package:qulo_v2/core/services/pref_analytics.dart';
import 'package:qulo_v2/features/pref_consent/pref_consent_dialogs.dart';
import 'package:qulo_v2/features/pref_consent/widgets/pref_consent_sheet.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

mixin PrefConsentSheetMixin on ConsumerState<PrefConsentSheet> {
  bool isSubmitting = false;

  /// Başarısız cevabın çeviri anahtarı. Sayfa kök navigator modalı olduğu için
  /// snackbar alttaki Scaffold'da, sayfanın ARKASINDA kalırdı; hata sayfa içinde gösterilir.
  String? errorKey;

  Future<void> accept() => _submit(PrefConsent.granted);

  Future<void> reject() async {
    final confirmed = await PrefConsentDialogs.confirmDecline(context, ref.read(navigationServiceProvider));
    if (confirmed && mounted) await _submit(PrefConsent.declined);
  }

  void openPolicy() => ref.read(navigationServiceProvider).push(RouteNames.privacyPolicy);

  /// Eski kullanıcının tercihi sunucuda zaten var: `genderPref` gönderilmez, sunucu mevcut olanı korur.
  Future<void> _submit(String status) async {
    if (isSubmitting) return;
    setState(() {
      isSubmitting = true;
      errorKey = null;
    });
    final result = await ref.read(userProvider.notifier).setPrefConsent(status: status);
    if (!mounted) return;
    setState(() => isSubmitting = false);
    result.when(
      success: (_) {
        PrefAnalytics.consentAnswered(entryPoint: PrefEntryPoint.legacySheet, granted: status == PrefConsent.granted);
        ref.read(navigationServiceProvider).pop();
      },
      failure: (f) => setState(() => errorKey = f.userMessageKey('error_general')),
    );
  }
}
