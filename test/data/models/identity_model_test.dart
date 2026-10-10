import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/discover_model.dart';
import 'package:qulo_v2/data/models/identity_model.dart';
import 'package:qulo_v2/data/models/public_profile_model.dart';

void main() {
  test('IdentityModel JSON round-trip + eksik alanlarda çökmez', () {
    final m = IdentityModel.fromJson({
      'gender_labels': ['trans_woman'], 'orientation_labels': ['bisexual', 'queer'],
      'show_gender_labels': false, 'show_orientation_labels': true,
    });
    expect(m.genderLabels, ['trans_woman']);
    expect(m.orientationLabels, ['bisexual', 'queer']);
    expect(m.showOrientationLabels, isTrue);
    expect(IdentityModel.fromJson(m.toJson()), m);
    expect(IdentityModel.fromJson(const {}), IdentityModel.empty);
    expect(IdentityModel.empty.isEmpty, isTrue);
  });

  test('ProfileCardModel ve PublicProfileModel identity alanını okur; yoksa null', () {
    final card = ProfileCardModel.fromJson({
      'user_id': 'u1', 'question_count': 2, 'identity': {'orientation_labels': ['gay']},
    });
    expect(card.identity?.orientationLabels, ['gay']);
    expect(card.identity?.genderLabels, isEmpty);
    expect(card.toPublicProfile().identity?.orientationLabels, ['gay']);
    expect(ProfileCardModel.fromJson({'user_id': 'u1', 'question_count': 2}).identity, isNull);
    final profile = PublicProfileModel.fromJson({'user_id': 'u1', 'identity': {'gender_labels': ['non_binary']}});
    expect(profile.identity?.genderLabels, ['non_binary']);
  });
}
