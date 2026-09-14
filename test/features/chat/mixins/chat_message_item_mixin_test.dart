import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/data/models/message_model.dart';
import 'package:qulo_v2/features/chat/mixins/chat_message_item_mixin.dart';

/// Sohbet gun ayiricisi — liste ters sirali (en yeni altta), ayirici
/// mesajin ustunde, onceki (daha eski) mesaj baska gundeyse gorunur.
class _Item with ChatMessageItemMixin {}

MessageModel _msg(String? createdAt) => MessageModel(
      id: 'm',
      matchId: 'x',
      senderId: 's',
      content: 'c',
      createdAt: createdAt,
    );

void main() {
  final item = _Item();
  // Z'siz ISO → yerel saat; testin saat dilimine gore gun kaymaz.
  final day14Noon = DateTime(2026, 9, 14, 12);

  test('onceki mesaj ayni gunse ayirici yok', () {
    expect(
      item.separatorDay(
          msgTime: day14Noon, next: _msg('2026-09-14T08:00:00'), isLast: false),
      isNull,
    );
  });

  test('onceki mesaj baska gundeyse mesajin gunu (saatsiz) doner', () {
    expect(
      item.separatorDay(
          msgTime: day14Noon, next: _msg('2026-09-13T23:59:00'), isLast: false),
      DateTime(2026, 9, 14),
    );
  });

  test('gun karsilastirmasi YEREL saatle yapilir (UTC zaman gelse bile)', () {
    // Yerel 14 Eylul 00:30 → UTC'de 13 Eylul olabilir; yerele cevrilmezse
    // ayni gunun mesajlari arasina yanlis ayirici girerdi ya da hic girmezdi.
    expect(
      item.separatorDay(
        msgTime: DateTime(2026, 9, 14, 0, 30).toUtc(),
        next: _msg('2026-09-13T23:00:00'),
        isLast: false,
      ),
      DateTime(2026, 9, 14),
    );
  });

  test('en eski mesajin ustunde her zaman ayirici var', () {
    expect(item.separatorDay(msgTime: day14Noon, next: null, isLast: true),
        DateTime(2026, 9, 14));
  });

  test('sonraki mesaj yok ama son oge degilse ayirici yok', () {
    expect(item.separatorDay(msgTime: day14Noon, next: null, isLast: false), isNull);
  });

  test('zaman okunamazsa ayirici konmaz', () {
    expect(item.separatorDay(msgTime: null, next: null, isLast: true), isNull);
    expect(
      item.separatorDay(msgTime: day14Noon, next: _msg('bozuk'), isLast: false),
      isNull,
    );
  });
}
