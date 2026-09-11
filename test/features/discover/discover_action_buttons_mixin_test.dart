import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/daily_stats_model.dart';
import 'package:qulo_v2/features/discover/mixins/discover_action_buttons_mixin.dart';

/// Discover geri alma butonu — ucretli hak (Plus gunde 3, Premium sinirsiz,
/// ucretsiz yok). Hak yoksa buton kilitli ve dokunus paywall acar; kalan hak
/// butonun altinda yazar (sinirsizda ∞).
class _Probe with DiscoverActionButtonsMixin {}

DailyStats _stats({required int used, required int limit}) => DailyStats(
      dailyDiscoversUsed: 0,
      dailyDiscoversLimit: 50,
      dailyUndosUsed: used,
      dailyUndosLimit: limit,
      questionsCreated: 0,
      questionsLimit: 4,
      monthlyPurpleBonus: 0,
      passportMode: false,
      hasAds: true,
    );

void main() {
  final probe = _Probe();

  group('undoAllowance', () {
    test('ucretsiz (limit 0) → hak yok, buton kilitli', () {
      final a = probe.undoAllowance(_stats(used: 0, limit: 0));

      expect(a.hasRight, isFalse);
      expect(a.remaining, 0);
    });

    test('Plus: 3 hakkin 1\'i kullanildi → 2 kaldi', () {
      final a = probe.undoAllowance(_stats(used: 1, limit: 3));

      expect(a.hasRight, isTrue);
      expect(a.isUnlimited, isFalse);
      expect(a.remaining, 2);
    });

    test('hak bitti → hak VAR (plan izin veriyor) ama kalan 0', () {
      // Kilit ile "bugunluk bitti" ayri: Plus kullaniciya paywall acilmaz,
      // sunucu reddeder ve mesaj gosterilir.
      final a = probe.undoAllowance(_stats(used: 3, limit: 3));

      expect(a.hasRight, isTrue);
      expect(a.remaining, 0);
    });

    test('kullanilan limiti asarsa kalan eksiye dusmez', () {
      expect(probe.undoAllowance(_stats(used: 5, limit: 3)).remaining, 0);
    });

    test('Premium (-1) → sinirsiz', () {
      final a = probe.undoAllowance(_stats(used: 12, limit: -1));

      expect(a.hasRight, isTrue);
      expect(a.isUnlimited, isTrue);
      expect(a.remaining, -1);
    });

    test('limitler henuz yuklenmedi → hak yok sayilir (mevcut davranis)', () {
      expect(probe.undoAllowance(null).hasRight, isFalse);
    });
  });
}
