import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/data/models/user_model.dart';

import 'edit_profile_host.dart';

/// Profil fotoğrafı async-gap'leri: yükleme/silme/sıralama sürerken kullanıcı geri
/// dönerse State dispose olur; `ref` StateError atardı. Başlamış sunucu işlemi yine
/// tamamlanmalı ve düzenleme durumu tazelenmeli.
void main() {
  final events = <String>[];

  setUp(() {
    events.clear();
    AnalyticsManager.debugEventSink = (name, _) => events.add(name);
  });
  tearDown(() => AnalyticsManager.debugEventSink = null);

  Future<EditHarness> pump(WidgetTester tester) async {
    final h = await EditHarness.create();
    await h.open(tester);
    return h;
  }

  group('silme onayı açıkken ekran kapanırsa', () {
    testWidgets('onaylanan silme yine sunucuya gider, düzenleme durumu tazelenir', (tester) async {
      final h = await pump(tester);
      h.nav
        ..sheetAnswer = 'delete'
        ..dialogGate = Completer<void>();

      h.state.onPhotoSlotTap(0);
      await tester.pump();
      expect(h.nav.dialogs, ['delete_photo_confirm']);
      await h.close(tester);
      h.nav.dialogGate!.complete();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(h.repo.deletedPhotoIndexes, [0]);
      expect(h.photos.whereType<String>(), ['b.jpg']);
      expect(events, contains(AnalyticsEvents.profilePhotoRemove));
    });
  });

  group('yükleme sürerken ekran kapanırsa', () {
    testWidgets('yüklenen foto düzenleme durumuna yansır (yeniden açılınca eski ızgara görünmez)',
        (tester) async {
      final h = await pump(tester);
      h.nav.sheetAnswer = 'gallery';
      h.repo.photoUploadGate = Completer<void>();

      h.state.onPhotoSlotTap(2);
      await tester.pump();
      expect(h.repo.uploadPhotoCount, 1);
      await h.close(tester);
      h.repo.photoUploadGate!.complete();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(h.photos.whereType<String>(), ['a.jpg', 'b.jpg', 'https://cdn.test/new-1.jpg']);
      expect(events, contains(AnalyticsEvents.profilePhotoAdd));
    });

    testWidgets('ekran kapanıp yükleme bitmeden yeniden açılırsa yeni ekranın ızgarası tazelenir',
        (tester) async {
      final h = await pump(tester);
      h.nav.sheetAnswer = 'gallery';
      h.repo.photoUploadGate = Completer<void>();

      h.state.onPhotoSlotTap(2);
      await tester.pump();
      await h.close(tester);
      await h.open(tester); // yeniden tohumlanır: yükleme henüz bitmedi, 2 foto
      expect(h.photos.whereType<String>(), ['a.jpg', 'b.jpg']);
      h.repo.photoUploadGate!.complete();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(h.photos.whereType<String>(), ['a.jpg', 'b.jpg', 'https://cdn.test/new-1.jpg']);
    });

    testWidgets('açık ekranda yükleme: foto ızgaraya eklenir', (tester) async {
      final h = await pump(tester);
      h.nav.sheetAnswer = 'camera';

      h.state.onPhotoSlotTap(2);
      await tester.pump();

      expect(h.photos[2], 'https://cdn.test/new-1.jpg');
    });
  });

  group('ana foto sıralaması sürerken ekran kapanırsa', () {
    testWidgets('ref kullanılmaz, düzenleme durumu sunucudaki sırayla tazelenir', (tester) async {
      final h = await pump(tester);
      h.nav.sheetAnswer = 'primary';
      h.repo.reorderGate = Completer<void>();

      h.state.onPhotoSlotTap(1);
      await tester.pump();
      expect(h.repo.reorderPhotosCallCount, 1);
      await h.close(tester);
      // Sunucu yeni sırayı kaydetti; sonraki getMe onu döner.
      h.repo.user = UserModel(id: 'u1', email: 'u1@qulo.test', photos: const ['b.jpg', 'a.jpg']);
      h.repo.reorderGate!.complete();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(h.photos.whereType<String>(), ['b.jpg', 'a.jpg']);
    });
  });
}
