import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/services/version_manager.dart';
import 'package:qulo_v2/providers/app_config_provider.dart';

/// Surum kontrolu resume'da. Acilista kapi `AppConfigNotifier.checkVersion`
/// (ayri test); burada yalnizca ON PLANA DONUSTE ne iletildigi: bakim ve
/// zorunlu guncelleme iletilir (kullanici engellenir), opsiyonel guncelleme
/// resume'da GOSTERILMEZ (her donuste dialog cikmasin).
void main() {
  final manager = VersionManager.instance;
  late List<UpdateStatus> delivered;
  late int checks;
  late UpdateStatus next;

  void initManager() {
    manager.init(
      onCheckVersion: () async {
        checks++;
        return next;
      },
      onResumeResult: delivered.add,
    );
  }

  setUp(() {
    manager.dispose();
    delivered = [];
    checks = 0;
    next = UpdateStatus.none;
  });

  tearDown(manager.dispose);

  Future<void> resume(WidgetTester tester) async {
    manager.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump();
  }

  for (final status in [UpdateStatus.maintenance, UpdateStatus.forceUpdate]) {
    testWidgets('resume: ${status.name} iletilir — kullanici engellenmeli', (tester) async {
      initManager();
      next = status;

      await resume(tester);

      expect(delivered, [status]);
    });
  }

  for (final status in [UpdateStatus.optionalUpdate, UpdateStatus.none]) {
    testWidgets('resume: ${status.name} ILETILMEZ — her donuste dialog cikmasin', (tester) async {
      initManager();
      next = status;

      await resume(tester);

      expect(checks, 1);
      expect(delivered, isEmpty);
    });
  }

  for (final state in [AppLifecycleState.paused, AppLifecycleState.inactive, AppLifecycleState.detached]) {
    testWidgets('${state.name} durumunda surum kontrol edilmez', (tester) async {
      initManager();
      next = UpdateStatus.forceUpdate;

      manager.didChangeAppLifecycleState(state);
      await tester.pump();

      expect(checks, 0);
      expect(delivered, isEmpty);
    });
  }

  testWidgets('ikinci init yok sayilir — ilk callback\'ler kalir', (tester) async {
    initManager();
    final ignored = <UpdateStatus>[];
    manager.init(onCheckVersion: () async => UpdateStatus.maintenance, onResumeResult: ignored.add);
    next = UpdateStatus.forceUpdate;

    await resume(tester);

    expect(delivered, [UpdateStatus.forceUpdate]);
    expect(ignored, isEmpty);
  });

  testWidgets('dispose sonrasi resume hicbir sey yapmaz', (tester) async {
    initManager();
    manager.dispose();
    next = UpdateStatus.forceUpdate;

    await resume(tester);

    expect(checks, 0);
    expect(delivered, isEmpty);
  });

  test('dialog gosteriliyor bayragi okunup yazilir (cift dialog onlemi)', () {
    manager.setDialogShown(true);
    expect(manager.isDialogShown, isTrue);

    manager.setDialogShown(false);
    expect(manager.isDialogShown, isFalse);
  });
}
