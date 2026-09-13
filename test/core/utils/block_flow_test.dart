import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/utils/block_flow.dart';

/// Engelleme — guvenlik yolu. Ekran yalnizca sunucu engeli onaylarsa kapanir;
/// hata ya da bilinmeyen hedefte kullanici bunu gorur.
class _Recorder {
  final blockedIds = <String>[];
  int blockedCallbacks = 0;
  final failures = <AppFailure>[];

  Future<Result<void>> Function(String) blocker(Result<void> result) => (id) async {
        blockedIds.add(id);
        return result;
      };
}

void main() {
  test('sunucu onaylarsa ekran kapanir, hata yolu calismaz', () async {
    final r = _Recorder();

    await runBlock(
      targetUserId: 'u2',
      block: r.blocker(const Success(null)),
      onBlocked: () => r.blockedCallbacks++,
      onFailed: r.failures.add,
    );

    expect(r.blockedIds, ['u2']);
    expect(r.blockedCallbacks, 1);
    expect(r.failures, isEmpty);
  });

  test('ag hatasinda ekran KAPANMAZ — kullanici engellendigini sanmasin', () async {
    final r = _Recorder();

    await runBlock(
      targetUserId: 'u2',
      block: r.blocker(const Failure(NetworkFailure())),
      onBlocked: () => r.blockedCallbacks++,
      onFailed: r.failures.add,
    );

    expect(r.blockedCallbacks, 0);
    expect(r.failures.single, isA<NetworkFailure>());
    expect(r.blockedIds, ['u2'], reason: 'istek tam bir kez gider');
  });

  test('sunucu reddederse ekran kapanmaz, hata tasinir', () async {
    final r = _Recorder();

    await runBlock(
      targetUserId: 'u2',
      block: r.blocker(const Failure(ServerFailure(code: 'SERVER_ERROR', statusCode: 500))),
      onBlocked: () => r.blockedCallbacks++,
      onFailed: r.failures.add,
    );

    expect(r.blockedCallbacks, 0);
    expect((r.failures.single as ServerFailure).code, 'SERVER_ERROR');
  });

  group('runServerAction — eslesmeyi kaldir / engeli kaldir', () {
    test('basarida yalniz onDone', () async {
      var done = 0;
      final failures = <AppFailure>[];

      await runServerAction(
        action: () async => const Success(null),
        onDone: () => done++,
        onFailed: failures.add,
      );

      expect(done, 1);
      expect(failures, isEmpty);
    });

    test('hatada yalniz onFailed — ekran islemi yapilmis gibi davranmaz', () async {
      var done = 0;
      final failures = <AppFailure>[];

      await runServerAction(
        action: () async => const Failure(TimeoutFailure()),
        onDone: () => done++,
        onFailed: failures.add,
      );

      expect(done, 0);
      expect(failures.single, isA<TimeoutFailure>());
    });
  });

  test('hedef bilinmiyorsa istek gitmez ama kullaniciya hata gosterilir — sessiz donus yok', () async {
    final r = _Recorder();

    await runBlock(
      targetUserId: null,
      block: r.blocker(const Success(null)),
      onBlocked: () => r.blockedCallbacks++,
      onFailed: r.failures.add,
    );

    expect(r.blockedIds, isEmpty);
    expect(r.blockedCallbacks, 0);
    expect(r.failures, hasLength(1));
  });
}
