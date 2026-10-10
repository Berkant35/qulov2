import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/identity_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';

/// Kendi kimlik & yönelim etiketleri. İnce Notifier: çağır → eşle → state.
class IdentityNotifier extends AsyncNotifier<IdentityModel> {
  @override
  Future<IdentityModel> build() async {
    final result = await ref.read(userRepositoryProvider).getIdentity();
    return result.when(success: (data) => data, failure: (f) => throw f);
  }

  /// Sunucu boş olmayan HER kayıtta `consent: true` ister (yalnız ilk kayıtta değil);
  /// bu yüzden `consent` false iken dolu etiket ağa hiç gönderilmez — arayüz rızayı
  /// (ilk kayıtta onay, sonrakilerde mevcut rıza) açıkça iletmek zorunda.
  Future<Result<IdentityModel>> save(IdentityModel next, {required bool consent}) async {
    if (!next.isEmpty && !consent) {
      return const Failure(ServerFailure(code: 'IDENTITY_CONSENT_REQUIRED', statusCode: 400));
    }
    final result = await ref.read(userRepositoryProvider).saveIdentity(next, consent: consent);
    if (result case Success(:final data)) state = AsyncData(data);
    return result;
  }

  /// Etiketleri siler = etiket rızasını geri alır (sunucu satırı kaldırır).
  Future<Result<IdentityModel>> clear() => save(IdentityModel.empty, consent: false);
}

final identityProvider = AsyncNotifierProvider<IdentityNotifier, IdentityModel>(IdentityNotifier.new);
