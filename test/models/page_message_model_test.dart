import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/features/page_messages/data/models/page_message_model.dart';

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
}
