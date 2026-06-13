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

    test('setupComplete is true when has 1+ photo AND 2+ questions', () {
      final user = UserModel.fromJson(_baseJson()
        ..['photos'] = ['url1']
        ..['question_count'] = 2);
      expect(user.setupComplete, true);
    });

    test('setupComplete is false when missing photo', () {
      final user = UserModel.fromJson(_baseJson()
        ..['photos'] = <String>[]
        ..['question_count'] = 2);
      expect(user.setupComplete, false);
    });

    test('setupComplete is false when questions < 2', () {
      final user = UserModel.fromJson(_baseJson()
        ..['photos'] = ['url1']
        ..['question_count'] = 1);
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
