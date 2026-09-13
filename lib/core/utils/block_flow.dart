import 'package:qulo_v2/core/network/result.dart';

/// Geri alinamaz, sunucu onayli bir islem (engelle, eslesmeyi kaldir, engeli
/// kaldir): ekran sonucunu YALNIZCA sunucu onaylarsa uygular.
///
/// Kalip: bu cagri yerleri `Result`'i yok sayip her durumda ekrani kapatiyordu —
/// ag/sunucu hatasinda kullanici islemin yapildigini saniyordu.
Future<void> runServerAction({
  required Future<Result<void>> Function() action,
  required void Function() onDone,
  required void Function(AppFailure failure) onFailed,
}) async {
  final result = await action();
  result.when(
    success: (_) => onDone(),
    failure: onFailed,
  );
}

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
  await runServerAction(
    action: () => block(targetUserId),
    onDone: onBlocked,
    onFailed: onFailed,
  );
}
