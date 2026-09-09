import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/discover_model.dart';
import 'package:qulo_v2/providers/match_provider.dart';

void main() {
  group('DiscoverResponse.fromJson', () {
    test('empty_reason okunur', () {
      final res = DiscoverResponse.fromJson({
        'cards': <dynamic>[],
        'page': 1,
        'has_more': false,
        'empty_reason': 'language',
      });

      expect(res.emptyReason, DiscoverEmptyReason.language);
    });

    test('empty_reason yoksa null', () {
      final res = DiscoverResponse.fromJson({
        'cards': <dynamic>[],
        'page': 1,
        'has_more': false,
      });

      expect(res.emptyReason, isNull);
    });
  });

  group('DiscoverState.copyWith emptyReason', () {
    test('acikca verilen deger yazilir', () {
      const state = DiscoverState(emptyReason: DiscoverEmptyReason.language);
      expect(
        state.copyWith(emptyReason: DiscoverEmptyReason.noCandidates).emptyReason,
        DiscoverEmptyReason.noCandidates,
      );
    });

    test('sebep, son yanitin sebebidir — kart gelince temizlenir', () {
      // "emptyReason ?? this.emptyReason" YAZILMAZ: eski sebep yapisip
      // kartlar geldikten sonra da bos durum metnini surdururdu.
      const state = DiscoverState(emptyReason: DiscoverEmptyReason.language);
      expect(state.copyWith(emptyReason: null).emptyReason, isNull);
    });
  });
}
