import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/features/auth/widgets/background_video.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../helpers/fake_video_player_platform.dart';

const _asset = 'assets/videos/login_bg.mp4';

Widget _stack(List<Widget> children) =>
    MaterialApp(home: Stack(fit: StackFit.expand, children: children));

void main() {
  // VisibilityDetector'un 500 ms zamanlayicisi test sonunda askida kalmasin.
  setUp(() => VisibilityDetectorController.instance.updateInterval = Duration.zero);

  // Eklenti yokken yukleme basarisiz olur; widget bunu bildirmeli ki login
  // formu videoya takili kalmasin. Sahte platform bir kez kurulunca geri
  // alinamaz — bu test o yuzden ilk sirada.
  testWidgets('video yüklenemeyince onFailed çağrılır', (tester) async {
    var failed = false;
    await tester.pumpWidget(MaterialApp(
      home: BackgroundVideo(assetPath: _asset, onFailed: () => failed = true),
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(failed, isTrue);
  });

  group('sahte platformla', () {
    final platform = FakeVideoPlayerPlatform();

    setUp(() {
      VideoPlayerPlatform.instance = platform;
      platform.reset();
    });

    /// Crashlytics 2.0.0–2.0.11 "No active player with ID 1": yeni sayfanin
    /// BackgroundVideo'su eski sayfa kapanmadan kurulur (ayni asset); eski
    /// sayfanin dispose'u controller'i oldururse yeni sayfa her rebuild'de
    /// patlar (tekrarlayan crash). Controller'in release zinciri kok zone
    /// future'lari icerdiginden FakeAsync'te ilerlemez — gercek async ile kosar.
    testWidgets('yeni widget aynı videoyu alırken eskisi kapanınca video yaşar',
        (tester) async {
      await tester.runAsync(() async {
        const oldKey = ValueKey('old');
        const newKey = ValueKey('new');
        Future<void> settle() async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
        }

        await tester.pumpWidget(_stack(const [
          BackgroundVideo(key: oldKey, assetPath: _asset),
        ]));
        await settle();
        expect(find.byType(VideoPlayer), findsOneWidget);

        await tester.pumpWidget(_stack(const [
          BackgroundVideo(key: oldKey, assetPath: _asset),
          BackgroundVideo(key: newKey, assetPath: _asset),
        ]));
        await settle();
        expect(find.byType(VideoPlayer), findsNWidgets(2));

        // Eski sayfa kapanir; yeni sayfa (klavye vb.) yeniden kurulur.
        await tester.pumpWidget(_stack(const [
          BackgroundVideo(key: newKey, assetPath: _asset, overlayOpacity: 0.6),
        ]));
        await settle();

        expect(tester.takeException(), isNull);
        expect(platform.disposed, isEmpty);
        expect(find.byType(VideoPlayer), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await settle();
        expect(platform.disposed, [0]);
      });
    });
  });
}
