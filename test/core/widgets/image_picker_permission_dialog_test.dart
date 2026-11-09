import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/models/app_dialog.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/navigation/navigation_service.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/image_picker_manager.dart';
import 'package:qulo_v2/core/theme/app_theme.dart';
import 'package:qulo_v2/core/widgets/image_picker_permission_dialog.dart';
import 'package:qulo_v2/providers/api_provider.dart';

/// Fotograf izni reddedilince kullanici ayarlara yonlendirilmeli — iOS reddden
/// sonra bir daha sormaz. Tek giris kapisi `pickWithPermissionPrompt`; tum
/// secici cagrilari ondan geciyor (kaynak tarama testi: image_picker_call_sites_test).
void main() {
  testWidgets('galeri izni reddi: fotograf dialog\'u, null doner, iptalde ayar acilmaz', (tester) async {
    final h = await _Harness.pump(tester, confirm: false);

    final result = await h.pick(() async => throw const ImagePickerPermissionException(ImageSource.gallery));

    expect(result, isNull);
    final dialog = h.nav.dialogs.single as ConfirmDialog;
    expect(dialog.name, 'image_picker_permission_denied');
    expect(dialog.title, h.tr('photo_permission_denied_title'));
    expect(h.picker.settingsOpened, 0);
  });

  testWidgets('kamera izni reddi + "Ayarlari ac" → kamera metni, ayarlar acilir', (tester) async {
    final h = await _Harness.pump(tester, confirm: true);

    await h.pick(() async => throw const ImagePickerPermissionException(ImageSource.camera));

    expect((h.nav.dialogs.single as ConfirmDialog).title, h.tr('camera_permission_denied_title'));
    expect(h.picker.settingsOpened, 1);
  });

  testWidgets('normal secim: gorsel aynen doner, dialog yok', (tester) async {
    final h = await _Harness.pump(tester, confirm: false);
    final image = PickedImage(bytes: Uint8List(3), mimeType: 'image/jpeg', fileName: 'a.jpg');

    final result = await h.pick(() async => image);

    expect(result, same(image));
    expect(h.nav.dialogs, isEmpty);
  });

  testWidgets('kullanici vazgecerse null, dialog yok', (tester) async {
    final h = await _Harness.pump(tester, confirm: false);

    expect(await h.pick(() async => null), isNull);
    expect(h.nav.dialogs, isEmpty);
  });

  testWidgets('dialog acikken ekran kapanirsa "Ayarlari ac" onayi yine uygulanir, ref kullanilmaz',
      (tester) async {
    final h = await _Harness.pump(tester, confirm: true);
    h.nav.dialogGate = Completer<void>();

    final picking = h.pick(() async => throw const ImagePickerPermissionException(ImageSource.camera));
    await tester.pump();
    await h.closeHost(tester);
    h.nav.dialogGate!.complete();

    expect(await picking, isNull);
    expect(tester.takeException(), isNull);
    expect(h.picker.settingsOpened, 1);
  });

  /// Crashlytics iOS 2.0.17: 0 baytlik secim kirpma ekraninda fatal uretti.
  group('acilamayan gorsel', () {
    final events = <Map<String, Object?>>[];
    setUp(() {
      events.clear();
      AnalyticsManager.debugEventSink = (name, params) => events.add({'event': name, ...?params});
    });
    tearDown(() => AnalyticsManager.debugEventSink = null);

    for (final reason in [
      ImagePickerInvalidImageException.reasonEmpty,
      ImagePickerInvalidImageException.reasonUndecodable,
    ]) {
      testWidgets('$reason: null doner, "baska fotograf sec" mesaji, izin dialog\'u yok', (tester) async {
        final h = await _Harness.pump(tester, confirm: false);

        final result = await h.pick(
          () async => throw ImagePickerInvalidImageException(ImageSource.gallery, reason: reason),
        );
        await tester.pump();

        expect(result, isNull);
        expect(h.nav.dialogs, isEmpty);
        expect(find.text(h.tr('photo_invalid_pick_again')), findsOneWidget);
        expect(events.single, {
          'event': AnalyticsEvents.photoPickInvalid,
          AnalyticsEvents.paramSource: 'gallery',
          AnalyticsEvents.paramReason: reason,
        });
      });
    }
  });

  testWidgets('baska hatalar yutulmaz — izin disi sorun gizlenmesin', (tester) async {
    final h = await _Harness.pump(tester, confirm: false);

    await expectLater(
      h.pick(() async => throw PlatformException(code: 'invalid_image')),
      throwsA(isA<PlatformException>()),
    );
    expect(h.nav.dialogs, isEmpty);
  });
}

class _Harness {
  _Harness._(this.nav, this.picker);

  final _FakeNavigationService nav;
  final _FakeImagePickerManager picker;
  late WidgetRef ref;
  late BuildContext context;

  List<Override> get _overrides => [
        navigationServiceProvider.overrideWithValue(nav),
        imagePickerManagerProvider.overrideWithValue(picker),
      ];

  /// Cagiran ekran agactan cikar (kapsam yasar): `ref`/`context` artik gecersiz.
  Future<void> closeHost(WidgetTester tester) => tester.pumpWidget(
        ProviderScope(overrides: _overrides, child: const MaterialApp(home: SizedBox())),
      );

  static Future<_Harness> pump(WidgetTester tester, {required bool confirm}) async {
    final h = _Harness._(_FakeNavigationService(confirm), _FakeImagePickerManager());
    await tester.pumpWidget(ProviderScope(
      overrides: h._overrides,
      child: MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: const [AppLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
        locale: const Locale('en'),
        home: Scaffold(
          body: Consumer(builder: (context, ref, _) {
            h
              ..ref = ref
              ..context = context;
            return const SizedBox();
          }),
        ),
      ),
    ));
    await tester.pump();
    return h;
  }

  Future<PickedImage?> pick(Future<PickedImage?> Function() picker) =>
      pickWithPermissionPrompt(ref, context, picker);

  String tr(String key) => context.tr(key);
}

class _FakeNavigationService implements NavigationService {
  _FakeNavigationService(this._confirm);

  final bool _confirm;
  final dialogs = <AppDialog>[];

  /// Doluysa dialog bu tamamlanana kadar acik kalir.
  Completer<void>? dialogGate;

  @override
  Future<T?> showAppDialog<T>(AppDialog dialog) async {
    dialogs.add(dialog);
    await dialogGate?.future;
    return _confirm as T?;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeNavigationService.${invocation.memberName}');
}

class _FakeImagePickerManager implements ImagePickerManager {
  int settingsOpened = 0;

  @override
  Future<void> openAppSettings() async => settingsOpened++;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeImagePickerManager.${invocation.memberName}');
}
