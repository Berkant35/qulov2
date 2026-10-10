import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/features/identity/widgets/identity_editor_sheet.dart';
import 'package:qulo_v2/providers/identity_provider.dart';

/// Etiket editörünü açar — banner ve düzenleme ekranı ortak.
abstract final class IdentitySheetLauncher {
  /// Kayıtlı etiketler yüklenmeden sayfa açılmaz: boş görünen sayfada "Kaydet" gerçek
  /// etiketleri silerdi. Yükleme hatasında sayfa açılmaz ve `false` döner — çağıran kullanıcıya
  /// hatayı gösterir (launcher'ın bağlamı yok); provider sıfırlanır, sonraki açılış yeniden dener.
  static Future<bool> open(WidgetRef ref, {required String entryPoint}) async {
    try {
      await ref.read(identityProvider.future);
    } catch (_) {
      ref.invalidate(identityProvider);
      return false;
    }
    await ref
        .read(navigationServiceProvider)
        .showAppBottomSheet<void>(
          CustomBottomSheet(
            name: 'identity_editor',
            maxHeightFactor: AppBottomSheet.tallHeightFactor,
            builder: (_) => IdentityEditorSheet(entryPoint: entryPoint),
          ),
        );
    return true;
  }
}
