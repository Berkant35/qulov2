import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/rewards_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';

typedef SendEvents = Future<Result<void>> Function(List<SectionEvent> events);
typedef PeriodicTimerFactory = Timer Function(Duration period, void Function(Timer) callback);

/// Bölüm kartı olaylarını toplar ve toplu yollar (spec §5.4, §7.7): kart başına oturumda bir gösterim +
/// bir tıklama; ekran açıkken ≤ 60 sn'de bir, ekran çıkışı / arka planda hemen; istek başına ≤ 50.
/// Sunucu gün başı tekilleştirir; gönderim en iyi çabadır (hata = olaylar düşer, yeniden deneme yok —
/// 30 istek/dk sınırını zorlamamak için).
class SectionEventTracker {
  SectionEventTracker(this._send, {PeriodicTimerFactory? periodic}) : _periodic = periodic ?? Timer.periodic;

  static const maxBatch = 50;
  static const flushEvery = Duration(seconds: 60);

  final SendEvents _send;
  final PeriodicTimerFactory _periodic;
  final _seen = <SectionEvent>{};
  final _queue = <SectionEvent>[];
  Timer? _timer;
  Future<void>? _flushing;

  int get pendingCount => _queue.length;

  bool impression(String itemId) => _add(SectionEvent(itemId, SectionEventType.impression));

  bool click(String itemId) => _add(SectionEvent(itemId, SectionEventType.click));

  void attach() => _timer ??= _periodic(flushEvery, (_) => flush());

  Future<void> detach() {
    _timer?.cancel();
    _timer = null;
    return flush();
  }

  /// Çıkış: önceki hesabın kuyruğu ve "oturumda ilk kez" kümesi GÖNDERİLMEDEN atılır (sonraki
  /// hesabın token'ıyla yollanmasın). Provider invalidate edilmez — `onDispose` flush ederdi.
  void reset() {
    _timer?.cancel();
    _timer = null;
    _queue.clear();
    _seen.clear();
  }

  /// Gönderim sürüyorsa aynı işi döndürür; o iş kuyrukta kalan her şeyi (sonradan gelenler dahil) yollar.
  Future<void> flush() => _flushing ??= _drain().whenComplete(() => _flushing = null);

  bool _add(SectionEvent event) {
    if (!_seen.add(event)) return false;
    _queue.add(event);
    return true;
  }

  Future<void> _drain() async {
    while (_queue.isNotEmpty) {
      final batch = _queue.take(maxBatch).toList();
      _queue.removeRange(0, batch.length);
      await _send(batch);
    }
  }
}

/// Uygulama ömürlü: "oturumda ilk kez" kümesi ekran girip çıkınca sıfırlanmaz.
final sectionEventTrackerProvider = Provider<SectionEventTracker>((ref) {
  final tracker = SectionEventTracker(ref.read(rewardsRepositoryProvider).sendEvents);
  ref.onDispose(tracker.detach);
  return tracker;
});
