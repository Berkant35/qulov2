import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/network/failure_message.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/identity_analytics.dart';
import 'package:qulo_v2/features/identity/identity_dialogs.dart';
import 'package:qulo_v2/features/identity/identity_sheet_launcher.dart';
import 'package:qulo_v2/features/identity/widgets/edit_profile_identity_section.dart';
import 'package:qulo_v2/providers/identity_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

mixin EditProfileIdentitySectionMixin on ConsumerState<EditProfileIdentitySection> {
  bool isBusy = false;

  /// İkili cinsiyet çeviri anahtarı; eski OTHER kullanıcılar "other" etiketini görür.
  /// Kullanıcı henüz yüklenmediyse (null) satır çizilmez — yanlışlıkla "Diğer" gösterilmez.
  String? genderLabelKey(String? gender) => switch (gender) {
    null => null,
    'WOMAN' => 'woman',
    'MAN' => 'man',
    _ => 'other',
  };

  Future<void> edit() async {
    final opened = await IdentitySheetLauncher.open(
      ref,
      entryPoint: IdentityEntryPoint.editProfile,
    );
    if (!opened && mounted) _showGenericError();
  }

  void retryLoad() => ref.invalidate(identityProvider);

  /// Cinsiyet ikili ve düzenlenemez: değişiklik destek talebiyle (hazır konu satırı) yürür.
  void requestGenderChange() => ref
      .read(navigationServiceProvider)
      .push(RouteNames.createTicket, extra: context.tr('gender_change_ticket_subject'));

  /// Yalnız yüklenmiş kimlikte çalışır: bilinmeyen durumun üstüne kayıt yazılmaz.
  Future<void> toggleShow({bool? gender, bool? orientation}) async {
    final current = ref.read(identityProvider).valueOrNull;
    if (isBusy || current == null) return;
    final next = current.copyWith(showGenderLabels: gender, showOrientationLabels: orientation);
    setState(() => isBusy = true);
    final result = await ref.read(identityProvider.notifier).save(next, consent: true);
    if (!mounted) return;
    _finish(result);
  }

  Future<void> clearLabels() async {
    if (isBusy) return;
    // Onay diyaloğu açıkken de meşgul: hızlı iki dokunuş tek diyalog açar.
    setState(() => isBusy = true);
    final confirmed = await IdentityDialogs.confirmClear(
      context,
      ref.read(navigationServiceProvider),
    );
    if (!mounted) return;
    if (!confirmed) {
      setState(() => isBusy = false);
      return;
    }
    final result = await ref.read(identityProvider.notifier).clear();
    if (!mounted) return;
    _finish(result);
    if (result is Success) {
      IdentityAnalytics.cleared(entryPoint: IdentityEntryPoint.editProfile);
    }
  }

  void _finish(Result<void> result) {
    setState(() => isBusy = false);
    if (result case Failure(:final failure)) {
      _showError(failure.userMessageKey('error_general'));
    }
  }

  void _showGenericError() => _showError('error_general');

  void _showError(String key) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr(key))));
}
