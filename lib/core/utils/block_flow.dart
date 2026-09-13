import 'package:qulo_v2/core/network/result.dart';

/// Kullanici engelleme akisi — sohbet ve profil detayindaki iki cagri yerinin
/// ortak karari.
///
/// Eskiden iki yer de `blockUser` sonucunu yok sayip her durumda ekrani
/// kapatiyordu: ag/sunucu hatasinda kullanici taciz edeni engelledigini
/// saniyordu, engel sunucuya hic yazilmamisti (karsi taraf yazmaya ve profili
/// gormeye devam eder). Profil detayi ayrica cagirana 'blocked' donduruyordu.
/// Hedef kimlik bilinmiyorsa (eslesme listesi yuklenmemis) sessizce
/// donuluyordu — kullanici hicbir sey gormuyordu.
///
/// Kural: engel YALNIZCA sunucu onaylarsa `onBlocked`; aksi halde `onFailed`.
Future<void> runBlock({
  required String? targetUserId,
  required Future<Result<void>> Function(String userId) block,
  required void Function() onBlocked,
  required void Function(AppFailure failure) onFailed,
}) async {
  if (targetUserId == null || targetUserId.isEmpty) {
    onFailed(const UnknownFailure(message: 'Block target unknown'));
    return;
  }
  final result = await block(targetUserId);
  result.when(
    success: (_) => onBlocked(),
    failure: onFailed,
  );
}
