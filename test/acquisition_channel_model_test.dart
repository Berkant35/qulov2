import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/acquisition_channel_model.dart';

void main() {
  test('AcquisitionChannel.fromJson maps server fields', () {
    final json = {
      'id': 'abc',
      'key': 'tiktok',
      'label': 'TikTok',
      'emoji': '🎵',
      'is_freeform': false,
    };
    final c = AcquisitionChannel.fromJson(json);
    expect(c.id, 'abc');
    expect(c.key, 'tiktok');
    expect(c.label, 'TikTok');
    expect(c.emoji, '🎵');
    expect(c.isFreeform, false);
  });
}
