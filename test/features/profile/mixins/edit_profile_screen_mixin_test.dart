import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/providers/edit_profile_provider.dart';
import 'package:qulo_v2/providers/location_provider.dart';
import 'package:qulo_v2/providers/user_languages_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

import 'edit_profile_host.dart';

/// Profil düzenleme ekranı: açılışta taze durum, kaydet ve konum güncelleme async-gap'leri.
class _GatedLocation extends LocationNotifier {
  Completer<void>? gate;

  @override
  Future<void> getCurrentLocation({bool askPermission = true}) async {
    await gate?.future;
    state = state.copyWith(lat: 41.0, lng: 29.0);
  }
}

void main() {
  final events = <String>[];

  setUp(() {
    events.clear();
    AnalyticsManager.debugEventSink = (name, _) => events.add(name);
  });
  tearDown(() => AnalyticsManager.debugEventSink = null);

  group('açılışta taze durum (düzenleme durumu her açılışta yeniden tohumlanır)', () {
    testWidgets('başka yoldan değişen yarıçap ve foto görünür, kaydedilmemiş seçim taşınmaz',
        (tester) async {
      final h = await EditHarness.create(
        user: UserModel(id: 'u1', email: 'u1@qulo.test', photos: const ['a.jpg', 'b.jpg']),
      );
      expect(h.edit.distanceKm, 50);
      h.container.read(editProfileProvider.notifier)
        ..setZodiac('leo')
        ..setDistanceKm(200);
      // Boş Keşfet'te yarıçap genişletildi, başka bir akış foto ekledi.
      h.repo.user = UserModel(
        id: 'u1',
        email: 'u1@qulo.test',
        matchRadiusKm: 120,
        photos: const ['a.jpg', 'b.jpg', 'c.jpg'],
      );
      await h.container.read(userProvider.notifier).fetchMe();

      await h.open(tester);

      expect(h.edit.distanceKm, 120);
      expect(h.photos.whereType<String>(), ['a.jpg', 'b.jpg', 'c.jpg']);
      expect(h.edit.selectedZodiac, isNull);
    });

    testWidgets('kullanıcı değişince önceki hesabın fotoğrafları görünmez', (tester) async {
      final h = await EditHarness.create();
      expect(h.photos.whereType<String>(), ['a.jpg', 'b.jpg']);
      h.repo.user = UserModel(id: 'u2', email: 'u2@qulo.test', photos: const ['z.jpg']);
      await h.container.read(userProvider.notifier).fetchMe();

      await h.open(tester);

      expect(h.photos.whereType<String>(), ['z.jpg']);
    });
  });

  group('kaydet sürerken ekran kapanırsa', () {
    testWidgets('kayıt tamamlanır ve dil listesi eşitlenir; ref kullanılmaz, sayfa açılmaz',
        (tester) async {
      final h = await EditHarness.create();
      await h.open(tester);
      h.container.read(editProfileProvider.notifier).setLanguages(['en', 'de']);
      h.repo.profileSaveGate = Completer<void>();

      final saving = h.state.save();
      await tester.pump();
      await h.close(tester);
      h.repo.profileSaveGate!.complete();
      await saving;

      expect(tester.takeException(), isNull);
      expect(h.container.read(userLanguagesProvider).valueOrNull, ['en', 'de']);
      expect(events, contains(AnalyticsEvents.profileEditSave));
      expect(h.nav.sheets, isEmpty);
    });

    testWidgets('açık ekranda başarılı kayıt sonuç sayfasını açar', (tester) async {
      final h = await EditHarness.create();
      await h.open(tester);

      await h.state.save();

      expect(h.nav.sheets, ['profile_save_success']);
    });
  });

  group('konum güncellemesi', () {
    late _GatedLocation location;

    Future<EditHarness> pump(WidgetTester tester) async {
      location = _GatedLocation();
      final h = await EditHarness.create(
        overrides: [locationProvider.overrideWith(() => location)],
      );
      h.repo.locationCity = 'İzmir';
      await h.open(tester);
      return h;
    }

    testWidgets('konum alınırken ekran kapanırsa sunucu konumu ve kullanıcı yine güncellenir',
        (tester) async {
      final h = await pump(tester);
      location.gate = Completer<void>();

      final updating = h.state.updateLocation();
      await tester.pump();
      await h.close(tester);
      location.gate!.complete();
      await updating;

      expect(tester.takeException(), isNull);
      expect(h.repo.locationUpdates, [(41.0, 29.0)]);
      expect(h.container.read(userProvider).valueOrNull?.city, 'İzmir');
    });

    testWidgets('açık ekranda şehir alanı güncellenir', (tester) async {
      final h = await pump(tester);

      await h.state.updateLocation();
      await tester.pump();

      expect(h.state.cityController.text, 'İzmir');
    });
  });
}
