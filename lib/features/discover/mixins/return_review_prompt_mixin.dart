import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:qulo_v2/core/services/app_review_manager.dart';
import 'package:qulo_v2/core/services/overlay_queue_service.dart';
import 'package:qulo_v2/core/services/overlay_request.dart';
import 'package:qulo_v2/features/discover/mixins/discover_screen_mixin.dart';

/// İlk eşleşmeden [AppReviewManager.returnDelay] sonra dönen kullanıcıya
/// sorulan mağaza değerlendirme isteminin kuyruk kimliği ve önceliği.
abstract final class ReturnReviewPrompt {
  static const String overlayId = 'app_review_return';

  /// Anket ve coach-mark turundan SONRA: en düşük kademe.
  static const int priority = OverlayPriority.notification;

  static OverlayRequest request(Future<void> Function() show) =>
      OverlayRequest(id: overlayId, priority: priority, show: show);
}

/// İlk eşleşme turunda paywall açıldığı için istem oraya konmuyor; kullanıcı
/// en az [AppReviewManager.returnDelay] sonra Keşfet'te ilk kartı kaydırınca
/// (açılışta değil — Apple HIG) overlay kuyruğuna girer. Süre dolmadıysa
/// kuyruğa hiç girmez; ekran başına bir kez denenir.
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
    if (!await AppReviewManager.instance.isReturnReviewDue()) return;
    if (!mounted) return;
    OverlayQueueService.instance
        .enqueue(ReturnReviewPrompt.request(_showReturnReview));
  }

  Future<void> _showReturnReview() async {
    // Kuyruk boşsa `show` senkron çağrılır; sistem istemi frame bitince açılır.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await AppReviewManager.instance.tryShowPendingReturnReview();
  }

  void disposeReturnReviewPrompt() =>
      OverlayQueueService.instance.cancel(ReturnReviewPrompt.overlayId);
}
