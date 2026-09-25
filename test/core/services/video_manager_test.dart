import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/services/video_manager.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import '../../helpers/fake_video_player_platform.dart';

/// Crashlytics 2.0.0–2.0.11: "No active player with ID 1" (24 olay, tekrarlayan).
/// Ayni asset'i alan ikinci widget (yeni sayfa, eskisi kapanmadan kurulur)
/// eskisinin `release`'iyle controller'ini kaybediyordu — manager referans
/// saymiyordu. Controller yalnizca son alici birakinca dispose edilmeli.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const asset = 'assets/videos/login_bg.mp4';
  final platform = FakeVideoPlayerPlatform();
  VideoPlayerPlatform.instance = platform;

  setUp(platform.reset);
  tearDown(() => VideoManager.instance.releaseAll());

  test('iki alici, bir birakma: controller yasar; ikinci birakmada dispose', () async {
    final manager = VideoManager.instance;
    final first = await manager.acquire(asset);
    final second = await manager.acquire(asset);
    expect(identical(first, second), isTrue);

    await manager.release(asset);
    expect(platform.disposed, isEmpty);
    expect(manager.isActive(asset), isTrue);

    await manager.release(asset);
    expect(platform.disposed, [0]);
    expect(manager.isActive(asset), isFalse);
  });

  test('alinmamis asset icin release yan etkisiz (sayac eksiye dusmez)', () async {
    final manager = VideoManager.instance;
    await manager.release(asset);
    await manager.acquire(asset);
    await manager.release('assets/videos/other.mp4');
    expect(manager.isActive(asset), isTrue);
    expect(platform.disposed, isEmpty);
  });

  test('init beklenirken gelen ikinci alici hazir controller alir', () async {
    platform.autoInitialize = false;
    final manager = VideoManager.instance;
    final pendingFirst = manager.acquire(asset);
    final pendingSecond = manager.acquire(asset);
    platform.emitInitialized(0);

    final first = await pendingFirst;
    final second = await pendingSecond;
    expect(identical(first, second), isTrue);
    expect(second.value.isInitialized, isTrue);
  });

  test('releaseAll (max 1 video kurali) tum alicilari dusurur', () async {
    final manager = VideoManager.instance;
    await manager.acquire(asset);
    await manager.acquire(asset);
    await manager.releaseAll();
    expect(platform.disposed, [0]);
    expect(manager.isActive(asset), isFalse);
  });
}
