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

  group('hasIcon — satirda logo/emoji alani ayrilir mi', () {
    AcquisitionChannel channel({String? emoji, String? iconUrl}) => AcquisitionChannel(
          id: 'id',
          key: 'k',
          label: 'L',
          emoji: emoji,
          iconUrl: iconUrl,
        );

    test('yalniz logo', () => expect(channel(iconUrl: 'https://x/a.svg').hasIcon, isTrue));
    test('yalniz emoji', () => expect(channel(emoji: '🎵').hasIcon, isTrue));
    test('bos icon_url ve emoji yok', () => expect(channel(iconUrl: '').hasIcon, isFalse));
    test('hicbiri yok', () => expect(channel().hasIcon, isFalse));

    test('hasLogo: dolu icon_url', () => expect(channel(iconUrl: 'https://x/a.svg').hasLogo, isTrue));
    test('hasLogo: bos icon_url', () => expect(channel(iconUrl: '', emoji: '🎵').hasLogo, isFalse));
    test('hasLogo: icon_url yok', () => expect(channel(emoji: '🎵').hasLogo, isFalse));

    test('hasEmoji: dolu', () => expect(channel(emoji: '🎵').hasEmoji, isTrue));
    test('hasEmoji: bos string', () => expect(channel(emoji: '').hasEmoji, isFalse));
    test('hasIcon: yalniz bos emoji → alan ayrilmaz', () => expect(channel(emoji: '').hasIcon, isFalse));
  });
}
