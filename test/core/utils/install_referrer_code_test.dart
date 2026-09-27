import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/utils/install_referrer_code.dart';

/// Web tarafinin urettigi gercek bicim
/// (`web/src/lib/constants/links.ts` → `storeLinks('referral', code)`).
String _referrer(String content, {String campaign = 'referral'}) =>
    'utm_source=quloapp.com&utm_medium=web&utm_campaign=$campaign&utm_content=$content';

void main() {
  group('referralCodeFromInstallReferrer', () {
    test('gercek davet linkinden kodu cikarir', () {
      expect(referralCodeFromInstallReferrer(_referrer('ABC123')), 'ABC123');
    });

    test('kucuk harf gelirse buyutur — sunucu da buyutuyor', () {
      expect(referralCodeFromInstallReferrer(_referrer('abc123')), 'ABC123');
    });

    test('tire kabul edilir (sunucu regex\'i izin veriyor)', () {
      expect(referralCodeFromInstallReferrer(_referrer('AB-123')), 'AB-123');
    });

    test('referrer yok ya da bos', () {
      expect(referralCodeFromInstallReferrer(null), isNull);
      expect(referralCodeFromInstallReferrer(''), isNull);
    });

    test('utm_content yoksa null — magaza linki kampanyasiz da uretiliyor', () {
      expect(
        referralCodeFromInstallReferrer(
          'utm_source=quloapp.com&utm_medium=web&utm_campaign=referral',
        ),
        isNull,
      );
    });

    /// `storeLinks()` baska kampanyalar icin de link uretiyor; yarin biri
    /// `utm_content=summer2026` koyarsa davet kodu olarak gonderilmemeli.
    test('kampanya referral degilse null', () {
      expect(
        referralCodeFromInstallReferrer(
          _referrer('SUMMER2026', campaign: 'web-questions'),
        ),
        isNull,
      );
    });

    test('organik kurulumun referrer\'i (utm_source=google-play) null', () {
      expect(
        referralCodeFromInstallReferrer('utm_source=google-play&utm_medium=organic'),
        isNull,
      );
    });

    group('sunucu kuralina uymayan deger gonderilmez', () {
      for (final bad in [
        'ABCDEFGHIJK', // 11 karakter, sunucu max 10
        'ABC 123', // bosluk
        'ABC_123', // alt tire — sunucu regex'inde yok
        'ABC.123',
        'ABC/123',
        'A"B',
      ]) {
        test('reddedilir: "$bad"', () {
          expect(referralCodeFromInstallReferrer(_referrer(bad)), isNull);
        });
      }
    });

    test('tam 10 karakter kabul edilir — sinirin kendisi', () {
      expect(referralCodeFromInstallReferrer(_referrer('ABCDEFGHIJ')), 'ABCDEFGHIJ');
    });
  });

  group('shouldDropPendingReferral', () {
    test('kalici redlerde bekleyen kod silinir', () {
      for (final code in [
        'SELF_REFERRAL',
        'ALREADY_REFERRED',
        'INVALID_REFERRAL_CODE',
        'VALIDATION_ERROR',
      ]) {
        expect(shouldDropPendingReferral(code), isTrue, reason: code);
      }
    });

    /// Ag hatasinda silinirse kullanici cevrimdisi kurdugunda odulu hic almaz.
    test('ag/sunucu hatasinda saklanir, tekrar denenir', () {
      for (final code in ['NETWORK', 'SERVER_ERROR', 'UNKNOWN', 'TIMEOUT']) {
        expect(shouldDropPendingReferral(code), isFalse, reason: code);
      }
    });
  });

  /// `app.dart`'ta dallanma olarak duruyordu ve test edilemiyordu; asil hata da
  /// tam oradaydi (gecici okuma hatasinda bayrak yaziliyor, odul kayboluyordu).
  group('captureInstallReferrer', () {
    test('daha once okunduysa hicbir sey yapilmaz', () {
      final c = captureInstallReferrer(wasRead: true, raw: _referrer('ABC123'));
      expect(c.markRead, isFalse);
      expect(c.code, isNull, reason: 'silinen kod geri getirilmemeli');
    });

    /// Bu case hatanin kendisi: okuma basarisizsa isaretlemek, gercek bir davet
    /// kurulumunda odulu kalici olarak kaybettiriyordu.
    test('okuma basarisizsa (null) bayrak YAZILMAZ — tekrar denenir', () {
      final c = captureInstallReferrer(wasRead: false, raw: null);
      expect(c.markRead, isFalse);
      expect(c.code, isNull);
    });

    test('organik kurulum: bayrak yazilir, kod yok', () {
      final c = captureInstallReferrer(
        wasRead: false,
        raw: 'utm_source=google-play&utm_medium=organic',
      );
      expect(c.markRead, isTrue, reason: 'okuma basardi, tekrar okunmasin');
      expect(c.code, isNull);
    });

    test('davet kurulumu: bayrak yazilir ve kod saklanir', () {
      final c = captureInstallReferrer(
        wasRead: false,
        raw: _referrer('ABC123'),
      );
      expect(c.markRead, isTrue);
      expect(c.code, 'ABC123');
    });

    test('okuma basardi ama icerik gecersiz: bayrak yazilir, kod yok', () {
      final c = captureInstallReferrer(
        wasRead: false,
        raw: _referrer('ABC_123'),
      );
      expect(c.markRead, isTrue);
      expect(c.code, isNull);
    });
  });
}
