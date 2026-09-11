import 'package:qulo_v2/core/network/failure_message.dart';
import 'package:qulo_v2/core/network/result.dart';

/// Geri alma basarisiz olunca gosterilecek metnin ceviri anahtari.
///
/// Hak bitince sunucu `DAILY_LIMIT_EXCEEDED` (params `{resource: 'undo'}`,
/// qulo-server `subscription.service.ts` `incrementDailyUndos`) doner.
/// Eskiden HER hata "gunluk geri alma hakkin doldu" yaziyordu: internet yokken
/// basan kullanici — sinirsiz hakki olan Premium dahil — bu mesaji goruyordu.
String undoFailureMessageKey(AppFailure failure) =>
    failure is ServerFailure && failure.code == 'DAILY_LIMIT_EXCEEDED'
        ? 'undo_limit_reached'
        : failure.userMessageKey('error_general');
