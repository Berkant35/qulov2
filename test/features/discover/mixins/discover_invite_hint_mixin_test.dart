import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/referral_model.dart';
import 'package:qulo_v2/features/discover/mixins/discover_invite_hint_mixin.dart';

class _Sut with DiscoverInviteHintMixin {}

ReferralStats _stats({required int remaining, int completed = 0}) => ReferralStats(
      total: completed,
      pending: 0,
      completed: completed,
      remaining: remaining,
    );

void main() {
  final sut = _Sut();

  group('shareableInviteCode', () {
    test('kod ve kalan hak varsa kodu dondurur', () {
      expect(
        sut.shareableInviteCode(code: 'ABC123', stats: _stats(remaining: 10)),
        'ABC123',
      );
    });

    /// Gizle/goster esigi tam olarak 1 ile 0 arasinda; esigin hemen ustu
    /// kapsanmazsa kosul `<= 1`'e kayarsa hicbir test kirmiziya donmez.
    test('kalan tam 1 ise hala gosterilir — esigin hemen ustu', () {
      expect(
        sut.shareableInviteCode(code: 'ABC123', stats: _stats(remaining: 1)),
        'ABC123',
      );
    });

    test('kod yoksa null — paylasilacak bir sey yok', () {
      expect(
        sut.shareableInviteCode(code: null, stats: _stats(remaining: 10)),
        isNull,
      );
    });

    test('kod bos string ise null', () {
      expect(
        sut.shareableInviteCode(code: '', stats: _stats(remaining: 10)),
        isNull,
      );
    });

    /// Sunucu 11. daveti odullendirmiyor (maxCompletedReferrals=10); kota
    /// dolmusken "ikinize de 25 mor elmas" demek yalan olur.
    test('kota dolduysa null', () {
      expect(
        sut.shareableInviteCode(
          code: 'ABC123',
          stats: _stats(remaining: 0, completed: 10),
        ),
        isNull,
      );
    });

    test('kalan negatif gelirse de null', () {
      expect(
        sut.shareableInviteCode(code: 'ABC123', stats: _stats(remaining: -1)),
        isNull,
      );
    });

    /// Kod geldiyse hak neredeyse kesin vardir ve kotayi sunucu da uyguluyor;
    /// istatistik yuklenirken girisi gizlemek ekrani sebepsiz bosaltir.
    test('istatistik henuz yoksa kodu dondurur', () {
      expect(sut.shareableInviteCode(code: 'ABC123', stats: null), 'ABC123');
    });
  });

  group('inviteLabel', () {
    test('@reward doldurulur, ham yer tutucu kalmaz', () {
      final label = sut.inviteLabel(
        template: 'Arkadasini cagir, ikinize de @reward mor elmas',
        reward: 25,
      );
      expect(label, 'Arkadasini cagir, ikinize de 25 mor elmas');
      expect(label, isNot(contains('@reward')));
    });

    test('yer tutucu yoksa metin aynen kalir', () {
      expect(sut.inviteLabel(template: 'duz metin', reward: 25), 'duz metin');
    });
  });
}
