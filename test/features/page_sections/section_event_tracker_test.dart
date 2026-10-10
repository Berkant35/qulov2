import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';
import 'package:qulo_v2/features/page_sections/providers/section_event_tracker.dart';

class _FakeTimer implements Timer {
  _FakeTimer(this.callback);
  final void Function(Timer) callback;
  bool cancelled = false;
  void fire() => callback(this);
  @override
  void cancel() => cancelled = true;
  @override
  bool get isActive => !cancelled;
  @override
  int get tick => 0;
}

void main() {
  late List<List<SectionEvent>> batches;
  late Result<void> nextResult;
  _FakeTimer? timer;

  SectionEventTracker make() => SectionEventTracker(
        (events) async {
          batches.add(List.of(events));
          return nextResult;
        },
        periodic: (duration, callback) {
          expect(duration, SectionEventTracker.flushEvery);
          return timer = _FakeTimer(callback);
        },
      );

  setUp(() {
    batches = [];
    nextResult = const Success(null);
    timer = null;
  });

  test('gösterim ve tıklama oturumda kart başına bir kez kuyruğa girer', () async {
    final tracker = make();
    expect(tracker.impression('b1'), isTrue);
    expect(tracker.impression('b1'), isFalse);
    expect(tracker.click('b1'), isTrue);
    expect(tracker.click('b1'), isFalse);
    await tracker.flush();
    expect(batches.single, const [
      SectionEvent('b1', SectionEventType.impression),
      SectionEvent('b1', SectionEventType.click),
    ]);
    await tracker.flush();
    expect(batches, hasLength(1), reason: 'boş kuyruk istek atmaz');
    expect(tracker.impression('b1'), isFalse, reason: 'gönderildikten sonra da oturumda tekil');
  });

  test('50\'den fazla olay 50\'lik parçalara bölünür', () async {
    final tracker = make();
    for (var i = 0; i < 120; i++) {
      tracker.impression('i$i');
    }
    await tracker.flush();
    expect(batches.map((b) => b.length), [50, 50, 20]);
    expect(tracker.pendingCount, 0);
  });

  test('gönderim hatası kuyruğu boşaltır (en iyi çaba; sonsuz yeniden deneme yok)', () async {
    final tracker = make();
    nextResult = const Failure(NetworkFailure());
    tracker.impression('b1');
    await tracker.flush();
    expect(tracker.pendingCount, 0);
  });

  test('attach periyodik gönderimi başlatır; detach durdurup kalanları yollar', () async {
    final tracker = make();
    tracker.attach();
    tracker.attach();
    tracker.impression('b1');
    timer!.fire();
    await Future<void>.delayed(Duration.zero);
    expect(batches, hasLength(1));
    tracker.click('b2');
    await tracker.detach();
    expect(timer!.cancelled, isTrue);
    expect(batches.last, const [SectionEvent('b2', SectionEventType.click)]);
  });

  test('gönderim sürerken ikinci flush yeni istek açmaz; sonradan gelen olay aynı sürücüyle yollanır', () async {
    final gate = Completer<Result<void>>();
    final sent = <List<SectionEvent>>[];
    final tracker = SectionEventTracker((events) {
      sent.add(List.of(events));
      return sent.length == 1 ? gate.future : Future.value(const Success(null));
    });
    tracker.impression('a');
    final first = tracker.flush();
    tracker.impression('b');
    final second = tracker.flush();
    await Future<void>.delayed(Duration.zero);
    expect(sent, hasLength(1), reason: 'eşzamanlı ikinci istek yok');
    gate.complete(const Success(null));
    await Future.wait([first, second]);
    expect(sent, [
      const [SectionEvent('a', SectionEventType.impression)],
      const [SectionEvent('b', SectionEventType.impression)],
    ]);
  });

  test('reset (çıkış): kuyruk + tekilleştirme GÖNDERİLMEDEN temizlenir, zamanlayıcı durur', () async {
    final tracker = make();
    tracker.attach();
    tracker.impression('b1');
    tracker.click('b1');

    tracker.reset();

    expect(tracker.pendingCount, 0);
    expect(timer!.cancelled, isTrue);
    await tracker.flush();
    expect(batches, isEmpty, reason: 'önceki hesabın olayları sonraki hesabın oturumuyla gönderilmez');
    expect(tracker.impression('b1'), isTrue, reason: 'yeni oturumda kart yeniden sayılır');
  });
}
