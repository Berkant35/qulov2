import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/services/overlay_queue_service.dart';
import 'package:qulo_v2/core/services/overlay_request.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/discover/mixins/acquisition_prompt_mixin.dart';

/// "Bizi nereden duydun?" anketi Discover girisine tasindi (2026-09-23):
/// profil ekraninda 7 kayittan 7'si atlanmisti, profile girmeyen hic gormuyordu.
/// Karar sunucu bayragina bagli; sira coach-mark turundan once; kuyruk id'si
/// idempotent — kuyrugun kendi testinde (`overlay_queue_service_test`); ekran
/// basina tek deneme (`_acquisitionTried`) widget testi ister, burada yok.
void main() {
  group('shouldPrompt', () {
    test('kullanici yuklenmeden sorulmaz', () {
      expect(AcquisitionPrompt.shouldPrompt(null), isFalse);
    });

    test('sunucu "cevaplandi" diyorsa sorulmaz — atlayan da cevaplamis sayilir', () {
      const user = UserModel(id: 'u1', email: 'a@b.test', acquisitionAnswered: true);
      expect(AcquisitionPrompt.shouldPrompt(user), isFalse);
    });

    test('cevaplanmamissa sorulur', () {
      const user = UserModel(id: 'u1', email: 'a@b.test');
      expect(AcquisitionPrompt.shouldPrompt(user), isTrue);
    });
  });

  group('kuyruk sirasi', () {
    test('coach-mark turu beklerken anket ONCE cikar — tek dokunusluk soru, sonra tur', () async {
      final queue = OverlayQueueService();
      final order = <String>[];
      final blocker = Completer<void>();
      queue.enqueue(OverlayRequest(
        id: 'blocker',
        priority: OverlayPriority.notification,
        show: () {
          order.add('blocker');
          return blocker.future;
        },
      ));
      queue.enqueue(OverlayRequest(
        id: 'coach',
        priority: OverlayPriority.onboarding,
        show: () async => order.add('coach'),
      ));
      queue.enqueue(AcquisitionPrompt.request(() async => order.add('acquisition')));

      blocker.complete();
      await Future<void>.delayed(Duration.zero);

      expect(order, ['blocker', 'acquisition', 'coach']);
    });
  });
}
