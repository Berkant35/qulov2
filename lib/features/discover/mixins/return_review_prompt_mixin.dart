import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:qulo_v2/core/services/app_review_manager.dart';
import 'package:qulo_v2/core/services/overlay_queue_service.dart';
import 'package:qulo_v2/core/services/overlay_request.dart';
import 'package:qulo_v2/features/discover/mixins/discover_screen_mixin.dart';

/// Dönen kullanıcıya sorulan mağaza değerlendirme isteminin (ilk eşleşmeden
/// [AppReviewManager.returnDelay] sonra ya da ertesi gün + quiz tamamlamış)
/// kuyruk kimliği ve önceliği; iki tetikleyici aynı kimliği paylaşır.
abstract final class ReturnReviewPrompt {
  static const String overlayId = 'app_review_return';

  /// Anket ve coach-mark turundan SONRA: en düşük kademe.
  static const int priority = OverlayPriority.notification;

  static OverlayRequest request(Future<void> Function() show) =>
      OverlayRequest(id: overlayId, priority: priority, show: show);
}

/// Keşfet'te ilk kartı kaydırınca (açılışta değil — Apple HIG) overlay
/// kuyruğuna girer. Önce ilk-eşleşme dönüş istemi (en az
/// [AppReviewManager.returnDelay] geçtiyse), o due değilse ertesi-gün istemi
/// (ilk aktif günden sonra + en az bir quiz tamamlandıysa). İkisi de due
/// değilse kuyruğa hiç girmez; ekran başına bir kez denenir. İlk aktif gün
/// ilk denemede kaydedilir.
///
/// Not: iOS'ta `requestReview` diyaloğu beklemeden döner, kuyruk hemen
/// ilerler; aynı kademedeki bir bildirim banner'ı ile üst üste gelebilir
/// (düşük olasılık, kabul edildi).
mixin ReturnReviewPromptMixin on DiscoverScreenMixin {
  bool _returnReviewTried = false;

  @override
  void onSwipeRight(String targetUserId) {
    super.onSwipeRight(targetUserId);
    unawaited(_enqueueReturnReviewIfDue());
  }

  @override
  void onSwipeLeft(String targetUserId) {
    super.onSwipeLeft(targetUserId);
    unawaited(_enqueueReturnReviewIfDue());
  }

  Future<void> _enqueueReturnReviewIfDue() async {
    if (_returnReviewTried) return;
    _returnReviewTried = true;
    final review = AppReviewManager.instance;
    await review.noteActiveDay();
    final Future<void> Function() show;
    if (await review.isReturnReviewDue()) {
      show = review.tryShowPendingReturnReview;
    } else if (await review.isSecondDayReviewDue()) {
      show = review.tryShowSecondDayReview;
    } else {
      return;
    }
    if (!mounted) return;
    OverlayQueueService.instance
        .enqueue(ReturnReviewPrompt.request(() => _showReview(show)));
  }

  Future<void> _showReview(Future<void> Function() tryShow) async {
    // Kuyruk boşsa `show` senkron çağrılır; sistem istemi frame bitince açılır.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await tryShow();
  }

  void disposeReturnReviewPrompt() =>
      OverlayQueueService.instance.cancel(ReturnReviewPrompt.overlayId);
}
