import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/page_message_model.dart';

void main() {
  test('PageMessageModel parses + localized fallback', () {
    final json = {
      'id': 'm1', 'page': 'discover', 'display_type': 'banner',
      'content': {
        'en': {'title': 'Hi', 'body': 'Welcome', 'cta_label': 'Go'},
        'tr': {'title': 'Merhaba', 'body': 'Hoşgeldin', 'cta_label': 'Git'},
      },
      'image_url': null, 'action_url': '/discover', 'frequency': 'once', 'priority': 5,
    };
    final m = PageMessageModel.fromJson(json);
    expect(m.displayType, 'banner');
    expect(m.localized('tr').title, 'Merhaba');
    expect(m.localized('de').title, 'Hi'); // fallback en
    expect(m.priority, 5);
  });

  test('PageMessageModel.localized() boş content ile crash etmez', () {
    final json = {
      'id': 'm2', 'page': 'discover', 'display_type': 'banner',
      'content': <String, dynamic>{},
      'image_url': null, 'action_url': null, 'frequency': 'once', 'priority': 1,
    };
    final m = PageMessageModel.fromJson(json);
    final result = m.localized('tr');
    expect(result.title, '');
    expect(result.body, '');
    expect(result.ctaLabel, '');
  });
}
