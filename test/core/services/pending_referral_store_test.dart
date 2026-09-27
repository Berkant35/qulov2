import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/services/pending_referral_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Okundu bayragi ile kodun kendisi AYRI tutuluyor; bu ayrim bir hatanin
/// duzeltmesi. Once "okumaya basladim" anlaminda isaretleniyordu: Play Services
/// yoksa ya da okuma gecici olarak patlarsa bayrak yine yaziliyor ve kod bir
/// daha hic okunmuyordu — gercek bir davet kurulumunda odul kalici olarak
/// kayboluyordu. Bayrak artik yalniz basarili okumadan sonra yazilir.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('temiz kurulumda ne bayrak ne kod vardir', () async {
    expect(await PendingReferralStore.wasReferrerRead(), isFalse);
    expect(await PendingReferralStore.read(), isNull);
  });

  test('isaretlemek kodu yazmaz — ikisi bagimsiz', () async {
    await PendingReferralStore.markReferrerRead();

    expect(await PendingReferralStore.wasReferrerRead(), isTrue);
    expect(
      await PendingReferralStore.read(),
      isNull,
      reason: 'organik kurulumda referrer okunur ama kod yoktur',
    );
  });

  test('kod yazilir, okunur ve temizlenir', () async {
    await PendingReferralStore.write('ABC123');
    expect(await PendingReferralStore.read(), 'ABC123');

    await PendingReferralStore.clear();
    expect(await PendingReferralStore.read(), isNull);
  });

  /// Kod uygulandiktan sonra temizlenir ama bayrak KALIR: Play ayni referrer'i
  /// her acilista donuyor, tekrar okumak silinen kodu geri getirirdi.
  test('kod temizlenince okundu bayragi silinmez', () async {
    await PendingReferralStore.markReferrerRead();
    await PendingReferralStore.write('ABC123');

    await PendingReferralStore.clear();

    expect(await PendingReferralStore.wasReferrerRead(), isTrue);
    expect(await PendingReferralStore.read(), isNull);
  });

  test('yeniden yazmak kodu gunceller', () async {
    await PendingReferralStore.write('AAA');
    await PendingReferralStore.write('BBB');
    expect(await PendingReferralStore.read(), 'BBB');
  });
}
