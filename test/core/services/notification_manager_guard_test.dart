import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/services/notification_manager.dart';

/// Ön plan FCM mesajında yerel bildirim beklenmeden gösteriliyordu; iOS'ta
/// bildirim izni yokken `PlatformException(Error 2003 ... not authorized)`
/// yakalanmayıp crash olarak kaydediliyordu (Crashlytics, 2.0.9+).
void main() {
  test('izin yok (Error 2003) sessizce geçer, non-fatal da yazılmaz', () async {
    final unexpected = <Object>[];

    await showLocalNotificationGuarded(
      () async => throw PlatformException(
        code: iosNotificationNotAuthorizedCode,
        message: 'Repository could not save notification. Source is not authorized.',
        details: 'UNErrorDomain',
      ),
      onUnexpected: (e, _) => unexpected.add(e),
    );

    expect(unexpected, isEmpty);
  });

  test('başka platform hatası dışarı sızmaz, non-fatal olarak bildirilir', () async {
    final unexpected = <Object>[];
    final error = PlatformException(code: 'other');

    await showLocalNotificationGuarded(
      () async => throw error,
      onUnexpected: (e, _) => unexpected.add(e),
    );

    expect(unexpected, [error]);
  });

  test('izin varsa bildirim gösterilir', () async {
    var shown = 0;

    await showLocalNotificationGuarded(
      () async => shown++,
      onUnexpected: (_, _) => fail('beklenmeyen hata'),
    );

    expect(shown, 1);
  });
}
