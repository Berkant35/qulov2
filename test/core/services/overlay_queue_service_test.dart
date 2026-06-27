import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulo_v2/core/services/overlay_queue_service.dart';
import 'package:qulo_v2/core/services/overlay_request.dart';

void main() {
  // Helper: a show() backed by a Completer the test can resolve manually.
  ({OverlayRequest req, Completer<void> done, List<String> shown}) make(
    String id,
    int priority,
    List<String> shownLog,
  ) {
    final done = Completer<void>();
    final req = OverlayRequest(
      id: id,
      priority: priority,
      show: () {
        shownLog.add(id);
        return done.future;
      },
    );
    return (req: req, done: done, shown: shownLog);
  }

  test('first enqueue shows immediately', () {
    final q = OverlayQueueService();
    final log = <String>[];
    final a = make('a', OverlayPriority.campaign, log);
    q.enqueue(a.req);
    expect(log, ['a']);
    expect(q.isShowing, true);
  });

  test('second enqueue waits until active completes', () {
    final q = OverlayQueueService();
    final log = <String>[];
    final a = make('a', OverlayPriority.campaign, log);
    final b = make('b', OverlayPriority.campaign, log);
    q.enqueue(a.req);
    q.enqueue(b.req);
    expect(log, ['a']); // b waits
    a.done.complete();
    // microtask flush
    return Future.microtask(() {
      expect(log, ['a', 'b']);
    });
  });

  test('higher priority shown before lower while waiting', () async {
    final q = OverlayQueueService();
    final log = <String>[];
    final a = make('a', OverlayPriority.notification, log);
    final low = make('low', OverlayPriority.notification, log);
    final high = make('high', OverlayPriority.onboarding, log);
    q.enqueue(a.req); // active
    q.enqueue(low.req);
    q.enqueue(high.req);
    a.done.complete();
    await Future.microtask(() {});
    expect(log, ['a', 'high']); // high before low
  });

  test('equal priority keeps FIFO', () async {
    final q = OverlayQueueService();
    final log = <String>[];
    final a = make('a', OverlayPriority.campaign, log);
    final b = make('b', OverlayPriority.campaign, log);
    final c = make('c', OverlayPriority.campaign, log);
    q.enqueue(a.req);
    q.enqueue(b.req);
    q.enqueue(c.req);
    a.done.complete();
    await Future.microtask(() {});
    b.done.complete();
    await Future.microtask(() {});
    expect(log, ['a', 'b', 'c']);
  });

  test('duplicate id is ignored', () {
    final q = OverlayQueueService();
    final log = <String>[];
    final a = make('a', OverlayPriority.campaign, log);
    final a2 = make('a', OverlayPriority.campaign, log);
    q.enqueue(a.req);
    q.enqueue(a2.req); // same id, ignored
    expect(log, ['a']);
  });

  test('notification queue caps at 3 (oldest dropped)', () async {
    final q = OverlayQueueService();
    final log = <String>[];
    final active = make('act', OverlayPriority.campaign, log);
    q.enqueue(active.req); // active, not notification
    for (final id in ['n1', 'n2', 'n3', 'n4']) {
      q.enqueue(make(id, OverlayPriority.notification, log).req);
    }
    active.done.complete();
    await Future.microtask(() {});
    // n1 dropped; n2 first to show
    expect(log.where((e) => e.startsWith('n')).first, 'n2');
  });

  test('throwing show does not wedge the queue', () async {
    final q = OverlayQueueService();
    final log = <String>[];
    final bad = OverlayRequest(
      id: 'bad',
      priority: OverlayPriority.campaign,
      show: () => throw StateError('boom'),
    );
    final good = make('good', OverlayPriority.campaign, log);
    q.enqueue(bad); // active; show() throws synchronously
    q.enqueue(good.req);
    await Future.microtask(() {});
    expect(log, ['good']); // queue advanced past the throw
  });
}
