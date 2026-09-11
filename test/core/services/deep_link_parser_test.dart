import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/services/deep_link_parser.dart';

/// Disaridan gelen her link (App Links, page message CTA'si) bu parser'dan
/// gecer; `null` = hicbir sey yapma. Guvenlik kapisi: yalnizca quloapp.com,
/// yalnizca guvenli segmentler (bkz. page_message_content.dart — spec §11 T1).
DeepLinkResult? _parse(String url) => DeepLinkParser.parse(Uri.parse(url));

void main() {
  group('host dogrulamasi — open redirect kapisi', () {
    test('quloapp.com ve www kabul edilir', () {
      expect(_parse('https://quloapp.com/chat/abc')?.goRouterPath, '/chat/abc');
      expect(_parse('https://www.quloapp.com/chat/abc')?.goRouterPath, '/chat/abc');
    });

    for (final url in [
      'https://evil.com/chat/abc',
      'https://quloapp.com.evil.com/chat/abc',
      'https://evilquloapp.com/chat/abc',
      'qulo:///chat/abc',
    ]) {
      test('baska host reddedilir: $url', () {
        expect(_parse(url), isNull);
      });
    }
  });

  group('segment guvenligi', () {
    for (final path in [
      '/chat/..',
      '/chat/%2E%2E',
      '/chat/abc%2Fdef',
      '/chat/a%20b',
      '/profile/%3Cscript%3E',
    ]) {
      test('guvensiz segment reddedilir: $path', () {
        expect(_parse('https://quloapp.com$path'), isNull);
      });
    }
  });

  group('rota eslemesi', () {
    test('davet linki oturumsuz acilir — davetli henuz kayitli degil', () {
      final r = _parse('https://quloapp.com/invite/AB12CD')!;

      expect(r.goRouterPath, '/invite/AB12CD');
      expect(r.requiresAuth, isFalse);
      expect(r.navType, DeepLinkNavType.go);
    });

    test('sohbet push ile acilir (geri tusu listeye doner), oturum ister', () {
      final r = _parse('https://quloapp.com/chat/m-1')!;

      expect(r.goRouterPath, '/chat/m-1');
      expect(r.requiresAuth, isTrue);
      expect(r.navType, DeepLinkNavType.push);
    });

    for (final tab in ['matches', 'discover']) {
      test('/$tab alt sekmeye go ile gider', () {
        final r = _parse('https://quloapp.com/$tab')!;

        expect(r.goRouterPath, '/$tab');
        expect(r.requiresAuth, isTrue);
        expect(r.navType, DeepLinkNavType.go);
      });
    }

    test('query parametreleri eslemeyi bozmaz (kampanya utm)', () {
      expect(_parse('https://quloapp.com/discover?utm_source=push')?.goRouterPath, '/discover');
    });

    test('/profile/<kimlik> profil detayina push ile gider', () {
      final r = _parse('https://quloapp.com/profile/3f2c9a1e-7b4d-4e8a-9c11-2a6f0d5e8b77')!;

      expect(r.goRouterPath, '/profile-detail/3f2c9a1e-7b4d-4e8a-9c11-2a6f0d5e8b77');
      expect(r.requiresAuth, isTrue);
      expect(r.navType, DeepLinkNavType.push);
    });
  });

  group('/profile/<sekme> profil detayina DUSMEZ', () {
    // Eskiden yalnizca subscription ve passport ayriliyordu; backoffice'ten
    // page message CTA'si olarak `/profile/diamonds` girilse kullanici
    // kimligi "diamonds" olan bir profil detayi acilirdi.
    for (final tab in [
      'edit',
      'questions',
      'diamonds',
      'passport',
      'exchange',
      'subscription',
      'performance',
      'settings',
      'notifications',
    ]) {
      test('/profile/$tab kendi sekmesine gider', () {
        final r = _parse('https://quloapp.com/profile/$tab')!;

        expect(r.goRouterPath, '/profile/$tab');
        expect(r.requiresAuth, isTrue);
        expect(r.navType, DeepLinkNavType.go);
      });
    }
  });

  group('desteklenmeyen yol → null (sessiz no-op)', () {
    for (final path in [
      '/',
      '/invite',
      '/invite/a/b',
      '/chat',
      '/profile/questions/analytics',
      '/unknown',
    ]) {
      test(path, () {
        expect(_parse('https://quloapp.com$path'), isNull);
      });
    }
  });

  group('resolveNavType — bildirim action_url', () {
    // Sunucunun gonderdigi yollar: notification-engine/rules.ts,
    // chat*.service.ts, notification.service.ts, weekly-report.service.ts.
    for (final (url, expected) in [
      ('/chat/m-1', DeepLinkNavType.push),
      ('/profile-detail/u-1', DeepLinkNavType.push),
      ('/matches', DeepLinkNavType.go),
      ('/discover', DeepLinkNavType.go),
      ('/profile/questions/analytics', DeepLinkNavType.go),
      ('', DeepLinkNavType.go),
    ]) {
      test('"$url" → ${expected.name}', () {
        expect(DeepLinkParser.resolveNavType(url), expected);
      });
    }
  });
}
