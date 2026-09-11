import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/providers/ai_suggestion_provider.dart';
import 'package:qulo_v2/providers/api_provider.dart';

import '../helpers/fake_repositories.dart';

/// Kolay mod (hazir soru onerileri). Sunucu sozlesmesi qulo-server
/// `ai-suggest.validator.ts`: `category` ∈ QUESTION_CATEGORIES (opsiyonel),
/// `profile_based` bool, `locale` ∈ SUPPORTED_LOCALES, `count` 1..10.
/// Oneriler soru bankasindan gelir; `correct_answer` 1-tabanli
/// (`ai-suggest.service.ts` karistirma sonrasi `indexOf + 1`).
///
/// Sunucu listeleri 2026-09-11 anlik goruntusu (`validators/question.validator.ts`,
/// `constants/locales.ts`): mobil bir kategori ya da dil eklerse ve sunucu
/// tanimiyorsa o cip 400 alir, ekran genel "Hata" gosterir.
const _serverCategories = {
  'personality', 'music', 'film', 'sports', 'travel', 'food', 'technology', 'general',
  'other', 'fun', 'entertainment', 'lifestyle', 'humor', 'hobby', 'science', 'history',
  'art', 'nature',
};
const _serverLocales = {
  'tr', 'en', 'de', 'fr', 'es', 'ar', 'ru', 'pt', 'it', 'ja', 'ko', 'zh', 'nl', 'pl', 'sv', 'hi',
};

(ProviderContainer, FakeQuestionRepository) _setup({
  Map<String, dynamic> response = const {},
  AppFailure? failure,
}) {
  final repo = FakeQuestionRepository(aiResponse: response, aiFailure: failure);
  final container = ProviderContainer(overrides: [questionRepositoryProvider.overrideWithValue(repo)]);
  addTearDown(container.dispose);
  return (container, repo);
}

Map<String, dynamic> _suggestion(String text) => {
      'question_text': text,
      'answers': ['A', 'B', 'C', 'D'],
      'correct_answer': 3,
      'hint': null,
      'category': 'music',
    };

void main() {
  group('istek sozlesmesi', () {
    test('kategori secilince kategori + dil + 5 oneri istenir', () async {
      final (c, repo) = _setup();

      await c.read(aiSuggestionProvider.notifier).fetchSuggestions(category: 'music', locale: 'de');

      expect(repo.lastAiBody, {
        'category': 'music',
        'profile_based': false,
        'locale': 'de',
        'count': 5,
      });
    });

    test('profile gore oneride kategori anahtari HIC gonderilmez', () async {
      final (c, repo) = _setup();

      await c.read(aiSuggestionProvider.notifier).fetchSuggestions(profileBased: true, locale: 'tr');

      expect(repo.lastAiBody!.containsKey('category'), isFalse);
      expect(repo.lastAiBody!['profile_based'], isTrue);
    });

    test('mobil kategoriler sunucunun kabul ettigi kumenin icinde', () {
      expect(_serverCategories, containsAll(AppConstants.questionCategories));
    });

    test('mobil soru dilleri sunucuyla birebir ayni', () {
      expect(AppConstants.supportedQuestionLocales.toSet(), _serverLocales);
    });
  });

  group('yanit', () {
    test('oneriler modele parse edilir, dogru cevap 1-tabanli tasinir', () async {
      final (c, _) = _setup(response: {
        'suggestions': [_suggestion('Hangi sarkiyi'), _suggestion('Kim soyledi')],
      });

      await c.read(aiSuggestionProvider.notifier).fetchSuggestions(category: 'music', locale: 'tr');

      final list = c.read(aiSuggestionProvider).value!;
      expect(list.map((s) => s.questionText), ['Hangi sarkiyi', 'Kim soyledi']);
      expect(list.first.correctAnswer, 3);
      expect(list.first.answers, hasLength(4));
    });

    test('suggestions alani yoksa bos liste — ekran bos durumu gosterir', () async {
      final (c, _) = _setup(response: const {});

      await c.read(aiSuggestionProvider.notifier).fetchSuggestions(category: 'music', locale: 'tr');

      expect(c.read(aiSuggestionProvider).value, isEmpty);
    });

    test('hata AsyncError olur — ekran hata durumunu gosterir, sonsuz yuklenmez', () async {
      final (c, _) = _setup(failure: const NetworkFailure());

      await c.read(aiSuggestionProvider.notifier).fetchSuggestions(category: 'music', locale: 'tr');

      final state = c.read(aiSuggestionProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<NetworkFailure>());
    });

    test('clear listeyi bosaltir', () async {
      final (c, _) = _setup(response: {'suggestions': [_suggestion('x')]});
      final n = c.read(aiSuggestionProvider.notifier);
      await n.fetchSuggestions(category: 'music', locale: 'tr');

      n.clear();

      expect(c.read(aiSuggestionProvider).value, isEmpty);
    });
  });
}
