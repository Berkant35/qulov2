import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/identity_labels.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/network/failure_message.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/services/identity_analytics.dart';
import 'package:qulo_v2/data/models/identity_model.dart';
import 'package:qulo_v2/features/identity/identity_dialogs.dart';
import 'package:qulo_v2/features/identity/widgets/identity_editor_sheet.dart';
import 'package:qulo_v2/providers/identity_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

mixin IdentityEditorSheetMixin on ConsumerState<IdentityEditorSheet> {
  late final Set<String> selectedGender;
  late final Set<String> selectedOrientation;
  late final bool hadLabels;
  bool consentGiven = false;
  bool isSaving = false;
  bool genderLimitHit = false;
  bool orientationLimitHit = false;

  /// Sayfa kök navigator modalı: snackbar alttaki Scaffold'da kalırdı, hata sayfa içinde gösterilir.
  String? errorKey;

  /// Sayfa yüklenmiş kimlikle açılır (`IdentitySheetLauncher` bekler); boş varsayım yalnız güvenlik ağı.
  IdentityModel get _current => ref.read(identityProvider).valueOrNull ?? IdentityModel.empty;

  void initEditor() {
    selectedGender = {..._current.genderLabels};
    selectedOrientation = {..._current.orientationLabels};
    // Aynı amaç için daha önce rıza verilmiş (etiket var) — tekrar sorulmaz.
    hadLabels = !_current.isEmpty;
  }

  bool get hasSelection => selectedGender.isNotEmpty || selectedOrientation.isNotEmpty;
  bool get needsConsentBox => !hadLabels && hasSelection;

  /// Etiketi yok + seçim yok = kaydedilecek bir şey yok (boş kayıt silme olurdu).
  bool get canSave => !isSaving && (hasSelection ? (hadLabels || consentGiven) : hadLabels);

  void toggle(Set<String> group, String label, {required bool isGender}) {
    if (isSaving) return;
    setState(() {
      genderLimitHit = false;
      orientationLimitHit = false;
      if (group.remove(label)) {
        // Rıza kutusu kalkınca işaret de düşer: yeniden çıktığında hep işaretsiz başlar.
        if (!hasSelection) consentGiven = false;
        return;
      }
      if (group.length >= IdentityLabels.maxPerGroup) {
        if (isGender) {
          genderLimitHit = true;
        } else {
          orientationLimitHit = true;
        }
        return;
      }
      group.add(label);
    });
  }

  void toggleGender(String label) => toggle(selectedGender, label, isGender: true);
  void toggleOrientation(String label) => toggle(selectedOrientation, label, isGender: false);

  void setConsent(bool value) => setState(() => consentGiven = value);

  void openPolicy() => ref.read(navigationServiceProvider).push(RouteNames.privacyPolicy);

  Future<void> save() async {
    if (!canSave) return;
    // Tüm etiketleri boşaltmak = silme + rıza geri alma: önce onay.
    if (!hasSelection) {
      final confirmed = await IdentityDialogs.confirmClear(
        context,
        ref.read(navigationServiceProvider),
      );
      if (!confirmed || !mounted) return;
    }
    // Kayıt sırası katalog sırasıdır.
    final next = _current.copyWith(
      genderLabels: IdentityLabels.gender.where(selectedGender.contains).toList(),
      orientationLabels: IdentityLabels.orientation.where(selectedOrientation.contains).toList(),
    );
    setState(() {
      isSaving = true;
      errorKey = null;
    });
    final notifier = ref.read(identityProvider.notifier);
    // Boş seçim = silme (rıza geri alma); dolu seçim = mevcut/yeni rıza ile kayıt.
    final result = hasSelection ? await notifier.save(next, consent: true) : await notifier.clear();
    if (!mounted) return;
    setState(() => isSaving = false);
    switch (result) {
      case Success():
        if (hasSelection) {
          IdentityAnalytics.saved(entryPoint: widget.entryPoint);
        } else {
          IdentityAnalytics.cleared(entryPoint: widget.entryPoint);
        }
        ref.read(navigationServiceProvider).pop();
      case Failure(:final failure):
        setState(() => errorKey = failure.userMessageKey('error_general'));
    }
  }
}
