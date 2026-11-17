import 'package:audio_session/audio_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:qulo_v2/core/services/quiz_audio_player.dart';

/// Quiz sesi iOS'ta `ambient` (sessiz mod tuşuna uyar). Son quiz oynatıcısı bırakılınca önceki
/// oturum geri gelir — yoksa sohbet sesli mesajları oturum boyu sessiz modda susar. Durdurma /
/// bırakma hata verse de geri yükleme yapılır ve hata dışarı sızmaz (Crashlytics gürültüsü yok).
class _Session {
  _Session({this.current, this.failConfigure = false});

  AudioSessionConfiguration? current;
  bool failConfigure;
  final configured = <AudioSessionConfiguration>[];
  int reads = 0;

  QuizAudioSessionGuard guard({bool enabled = true}) => QuizAudioSessionGuard(
        enabled: enabled,
        readConfiguration: () async {
          reads++;
          return current;
        },
        configure: (config) async {
          if (failConfigure) throw Exception('configure failed');
          configured.add(config);
          current = config;
        },
      );
}

class _FakeAudioPlayer implements AudioPlayer {
  _FakeAudioPlayer({this.failStop = false, this.failDispose = false});

  final bool failStop;
  final bool failDispose;
  final calls = <String>[];

  @override
  Future<Duration?> setUrl(
    String url, {
    Map<String, String>? headers,
    Duration? initialPosition,
    bool preload = true,
    dynamic tag,
  }) async {
    calls.add('setUrl');
    return null;
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async => calls.add('seek');

  @override
  Future<void> play() async => calls.add('play');

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> stop() async {
    calls.add('stop');
    if (failStop) throw Exception('stop failed');
  }

  @override
  Future<void> dispose() async {
    calls.add('dispose');
    if (failDispose) throw Exception('dispose failed');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FakeAudioPlayer.${invocation.memberName}');
}

const _chat = AudioSessionConfiguration.speech();

void main() {
  group('QuizAudioSessionGuard', () {
    test('ilk tutucu ambient yapar; ikinci tutucu yeniden yapılandırmaz', () async {
      final s = _Session(current: _chat);
      final guard = s.guard();

      await guard.acquire();
      await guard.acquire();

      expect(s.configured, [QuizAudioSessionGuard.ambient]);
      expect(s.reads, 1);
      expect(guard.holders, 2);
    });

    test('geri yükleme yalnız SON tutucu bırakınca, önceki yapılandırmaya', () async {
      final s = _Session(current: _chat);
      final guard = s.guard();
      await guard.acquire(); // eski soru kartı
      await guard.acquire(); // yeni soru kartı (eskisi bırakılmadan kurulur)

      await guard.release();
      expect(s.current, QuizAudioSessionGuard.ambient, reason: 'yeni kart hâlâ çalıyor');

      await guard.release();
      expect(s.current, _chat);
      expect(guard.holders, 0);
    });

    test('önceden yapılandırma yoksa just_audio varsayılanına (music) döner', () async {
      final s = _Session();
      final guard = s.guard();

      await guard.acquire();
      await guard.release();

      expect(s.configured.last, QuizAudioSessionGuard.fallback);
    });

    test('fazladan release sayacı eksiye düşürmez, oturuma dokunmaz', () async {
      final s = _Session(current: _chat);
      final guard = s.guard();

      await guard.release();
      await guard.acquire();
      await guard.release();
      await guard.release();

      expect(guard.holders, 0);
      expect(s.configured, [QuizAudioSessionGuard.ambient, _chat]);
    });

    test('configure hata verirse fırlatmaz; sayaç dengede kalır', () async {
      final s = _Session(current: _chat, failConfigure: true);
      final guard = s.guard();

      await expectLater(guard.acquire(), completes);
      await expectLater(guard.release(), completes);
      expect(guard.holders, 0);
    });

    test('usePlayback: tutuluyken playback; son bırakış önceki yapılandırmaya döner', () async {
      final s = _Session(current: _chat);
      final guard = s.guard();

      await guard.acquire();
      await guard.usePlayback();
      await guard.usePlayback(); // aynısı yeniden kurulmaz
      expect(s.configured, [QuizAudioSessionGuard.ambient, QuizAudioSessionGuard.playback]);

      await guard.release();
      expect(s.current, _chat);
      expect(guard.holders, 0);
    });

    test('usePlayback tutucu yokken oturuma dokunmaz', () async {
      final s = _Session(current: _chat);
      final guard = s.guard();

      await guard.usePlayback();

      expect(s.configured, isEmpty);
    });

    test('önceki kart playback\'e geçtiyse yeni kart ambient\'e döndürür; geri yükleme yine ilk yapılandırmaya', () async {
      final s = _Session(current: _chat);
      final guard = s.guard();
      await guard.acquire(); // eski kart
      await guard.usePlayback(); // eski kartta tekrar dinle

      await guard.acquire(); // yeni kart: kendiliğinden çalma sessize uymalı
      expect(s.current, QuizAudioSessionGuard.ambient);
      expect(s.reads, 1, reason: 'geri yüklenecek yapılandırma yalnız ilk tutucuda okunur');

      await guard.release();
      await guard.release();
      expect(s.current, _chat);
    });

    test('Android (enabled false): oturuma hiç dokunulmaz', () async {
      final s = _Session(current: _chat);
      final guard = s.guard(enabled: false);

      await guard.acquire();
      await guard.release();

      expect(s.configured, isEmpty);
      expect(s.reads, 0);
    });
  });

  group('QuizAudioPlayer.dispose', () {
    test('önce durdurur, sonra bırakır, sonra oturumu geri yükler', () async {
      final s = _Session(current: _chat);
      final fake = _FakeAudioPlayer();
      final player = QuizAudioPlayer(player: fake, session: s.guard());

      await player.playFromStart('https://media.test/v.m4a');
      expect(s.current, QuizAudioSessionGuard.ambient);

      await player.dispose();

      expect(fake.calls.skipWhile((c) => c != 'stop'), ['stop', 'dispose']);
      expect(s.current, _chat);
    });

    test('stop VE dispose hata verse de oturum geri yüklenir, hata sızmaz', () async {
      final s = _Session(current: _chat);
      final guard = s.guard();
      final player = QuizAudioPlayer(
        player: _FakeAudioPlayer(failStop: true, failDispose: true),
        session: guard,
      );
      await player.playFromStart('https://media.test/v.m4a');

      await expectLater(player.dispose(), completes);

      expect(s.current, _chat);
      expect(guard.holders, 0);
    });

    test('tekrar dinle oturumu ikinci kez tutmaz: tek dispose geri yükler', () async {
      final s = _Session(current: _chat);
      final guard = s.guard();
      final player = QuizAudioPlayer(player: _FakeAudioPlayer(), session: guard);

      await player.playFromStart('https://media.test/v.m4a');
      await player.playFromStart('https://media.test/v.m4a');
      expect(guard.holders, 1);

      await player.dispose();
      expect(s.current, _chat);
    });

    test('pause konumu korur (seek/setUrl yok); resume playback oturumuyla sürdürür', () async {
      final s = _Session(current: _chat);
      final fake = _FakeAudioPlayer();
      final player = QuizAudioPlayer(player: fake, session: s.guard());
      await player.playFromStart('https://media.test/v.m4a');
      fake.calls.clear();

      await player.pause();
      expect(fake.calls, ['pause']);

      await player.resume();
      await Future<void>.delayed(Duration.zero);
      expect(fake.calls, ['pause', 'play'], reason: 'baştan çalmaz');
      expect(s.current, QuizAudioSessionGuard.playback, reason: 'dokunuş sessiz modda da çalar');
    });

    test('kendiliğinden çalma ambient; tekrar dinle playback; dispose önceki oturumu geri yükler', () async {
      final s = _Session(current: _chat);
      final fake = _FakeAudioPlayer();
      final player = QuizAudioPlayer(player: fake, session: s.guard());

      await player.playFromStart('https://media.test/v.m4a');
      expect(s.current, QuizAudioSessionGuard.ambient, reason: 'autoplay sessiz mod tuşuna uyar');

      await player.playFromStart('https://media.test/v.m4a', userInitiated: true);
      expect(s.current, QuizAudioSessionGuard.playback, reason: 'dokunuş sessiz modda da çalar');
      expect(fake.calls.last, 'play');

      await player.dispose();
      expect(s.current, _chat);
    });

    test('hiç çalmamış oynatıcı oturuma dokunmaz', () async {
      final s = _Session(current: _chat);
      final player = QuizAudioPlayer(player: _FakeAudioPlayer(), session: s.guard());

      await player.dispose();

      expect(s.configured, isEmpty);
    });
  });
}
