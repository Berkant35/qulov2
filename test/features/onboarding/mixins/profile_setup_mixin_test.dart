import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/image_picker_manager.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/onboarding/mixins/profile_setup_mixin.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

import '../../../helpers/fake_navigation.dart';
import '../../../helpers/fake_repositories.dart';

/// Kurulum kapısı async-gap'leri: foto değiştirmede (yükle → eskileri sil)
/// silme döngüsü sürerken kapı kapanırsa (çıkış / 401) döngüdeki `ref`
/// StateError atıp catch'e düşüyordu — başarılı yükleme `setup_photo_fail`
/// diye ölçülüyordu. Çıkış onayı açıkken kapı kapanırsa onaylanan çıkış
/// yine uygulanmalı.
class _HostGate extends ConsumerStatefulWidget {
  const _HostGate();

  @override
  ConsumerState<_HostGate> createState() => _HostState();
}

class _HostState extends ConsumerState<_HostGate> with ProfileSetupMixin<_HostGate> {
  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _FakePicker implements ImagePickerManager {
  @override
  Future<PickedImage?> pickAndCropFromGallery(BuildContext context) async =>
      PickedImage(bytes: Uint8List(4), mimeType: 'image/jpeg', fileName: 'p.jpg');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakePicker.${invocation.memberName}');
}

class _CountingAuth extends AuthNotifier {
  int logouts = 0;

  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);

  @override
  Future<void> logout() async => logouts++;
}

class _Harness {
  _Harness(this.repo, this.nav, this.auth, this.container);

  final FakeUserRepository repo;
  final FakeNavigationService nav;
  final _CountingAuth auth;
  final ProviderContainer container;
  late _HostState state;
}

Widget _app(ProviderContainer container, Widget home) => UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
        home: home,
      ),
    );

Future<_Harness> _pump(WidgetTester tester) async {
  final repo = FakeUserRepository(
    UserModel(id: 'u1', email: 'u1@qulo.test', photos: const ['old-1.jpg', 'old-2.jpg']),
  );
  final nav = FakeNavigationService();
  final auth = _CountingAuth();
  final container = ProviderContainer(overrides: [
    userRepositoryProvider.overrideWithValue(repo),
    navigationServiceProvider.overrideWithValue(nav),
    imagePickerManagerProvider.overrideWithValue(_FakePicker()),
    authProvider.overrideWith(() => auth),
  ]);
  addTearDown(container.dispose);
  await container.read(userProvider.notifier).fetchMe();
  final h = _Harness(repo, nav, auth, container);
  await tester.pumpWidget(_app(container, const _HostGate()));
  await tester.pump();
  h.state = tester.state<_HostState>(find.byType(_HostGate));
  return h;
}

Future<void> _closeGate(WidgetTester tester, _Harness h) =>
    tester.pumpWidget(_app(h.container, const SizedBox()));

void main() {
  final events = <String>[];

  setUp(() {
    events.clear();
    AnalyticsManager.debugEventSink = (name, _) => events.add(name);
  });
  tearDown(() => AnalyticsManager.debugEventSink = null);

  group('foto değiştirme: eskileri silerken kapı kapanırsa', () {
    testWidgets('döngü durur; yükleme başarısız diye ölçülmez, hata yutulmaz', (tester) async {
      final h = await _pump(tester);
      h.nav.sheetAnswer = 'gallery';
      h.repo.photoDeleteGate = Completer<void>();

      final tapping = h.state.handlePhotoTap();
      await tester.pump();
      expect(h.repo.uploadPhotoCount, 1);
      expect(h.repo.deletedPhotoIndexes, [1], reason: 'tersten silinir, ilk silme kapıda');
      await _closeGate(tester, h);
      h.repo.photoDeleteGate!.complete();
      await tapping;

      expect(tester.takeException(), isNull);
      expect(h.repo.deletedPhotoIndexes, [1]);
      expect(events, isNot(contains(AnalyticsEvents.setupPhotoFail)));
    });

    testWidgets('açık kapıda yeni foto eskilerin yerini alır', (tester) async {
      final h = await _pump(tester);
      h.nav.sheetAnswer = 'gallery';

      await h.state.handlePhotoTap();

      expect(h.repo.deletedPhotoIndexes, [1, 0]);
      expect(h.repo.user.photos, ['https://cdn.test/new-1.jpg']);
      expect(events, contains(AnalyticsEvents.setupPhotoSuccess));
    });
  });

  group('çıkış onayı açıkken kapı kapanırsa', () {
    testWidgets('onaylanan çıkış yine uygulanır; ref kullanılmaz', (tester) async {
      final h = await _pump(tester);
      h.nav.dialogGate = Completer<void>();

      final leaving = h.state.handleBackAttempt();
      await tester.pump();
      await _closeGate(tester, h);
      h.nav.dialogGate!.complete();

      expect(await leaving, isTrue);
      expect(tester.takeException(), isNull);
      expect(h.auth.logouts, 1);
    });
  });
}
