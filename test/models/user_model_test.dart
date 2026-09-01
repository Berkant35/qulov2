import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/user_model.dart';

void main() {
  group('UserModel.interests', () {
    test('parses interests from JSON', () {
      final json = _baseJson()..['interests'] = ['music', 'travel'];
      final user = UserModel.fromJson(json);
      expect(user.interests, ['music', 'travel']);
    });

    test('defaults interests to empty list when missing', () {
      final user = UserModel.fromJson(_baseJson());
      expect(user.interests, isEmpty);
    });
  });

  // Profile Setup Gate'in üç kartı: foto, 2 soru, gender pref.
  // Üçü de tamamlanmadan setupComplete true olmamalı (a6b78d3).
  group('UserModel.setupComplete', () {
    test('is true when photo AND 2+ questions AND gender pref are all set', () {
      final user = UserModel.fromJson(_setupJson());
      expect(user.setupComplete, true);
    });

    test('is false when photos is empty', () {
      final user = UserModel.fromJson(_setupJson()..['photos'] = <String>[]);
      expect(user.setupComplete, false);
    });

    test('is false when photos is missing entirely', () {
      final user = UserModel.fromJson(_setupJson()..remove('photos'));
      expect(user.setupComplete, false);
    });

    test('is false when questions < 2', () {
      final user = UserModel.fromJson(_setupJson()..['question_count'] = 1);
      expect(user.setupComplete, false);
    });

    test('is false when gender pref was never set', () {
      final user = UserModel.fromJson(_setupJson()..remove('gender_pref_set_at'));
      expect(user.setupComplete, false);
    });
  });
}

Map<String, dynamic> _baseJson() => {
      'id': 'u1',
      'email': 'a@b.com',
      'profile_completion': 50,
      'question_count': 0,
    };

/// Üç setup kapısı da açık bir kullanıcı — testler tek tek bozarak doğrular.
Map<String, dynamic> _setupJson() => _baseJson()
  ..['photos'] = ['url1']
  ..['question_count'] = 2
  ..['gender_pref_set_at'] = '2026-06-13T10:00:00.000Z';
