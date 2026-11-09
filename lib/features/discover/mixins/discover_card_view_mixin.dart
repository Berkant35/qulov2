import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/network/failure_message.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/features/diamonds/models/paywall_triggers.dart';
import 'package:qulo_v2/features/diamonds/widgets/paywall_bottom_sheet.dart';
import 'package:qulo_v2/features/discover/utils/undo_failure_message.dart';
import 'package:qulo_v2/features/discover/widgets/discover_card_view.dart';
import 'package:qulo_v2/features/profile_detail/models/profile_detail_args.dart';
import 'package:qulo_v2/features/quiz/models/quiz_target_args.dart';
import 'package:qulo_v2/features/quiz/quiz_retry_lock.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/daily_stats_provider.dart';
import 'package:qulo_v2/providers/match_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

enum _SwipeDirection { left, right }

/// [DiscoverCardView] logic'i: sürükleme, uçuş animasyonu, beğeni → quiz,
/// reddet, geri al.
///
/// Async-gap: beğeni ya da geri alma isteği sürerken kart görünümü ağaçtan
/// çıkabilir (deste yeniden yüklenip boşalır, çıkış). Kapalı görünümde
/// `ref`/`context` kullanılmaz — eskiden günlük limit paywall'u `ref`,
/// kilit mesajı `context.l10n` ile çöküyordu. Sunucuda tamamlanan geri
/// almanın günlük hak sayacı yine tazelenir.
mixin DiscoverCardViewMixin on ConsumerState<DiscoverCardView>
    implements TickerProvider {
  static const _swipeThreshold = 100.0;
  static const _flyAwayDuration = Duration(milliseconds: 300);

  double dragOffset = 0;
  bool isProcessing = false;
  _SwipeDirection? _swipeDirection;

  late final AnimationController flyAwayCtrl;
  final _curveTween = CurveTween(curve: Curves.easeIn);
  Animation<double> _flyAwayAnimation = const AlwaysStoppedAnimation(0);

  void initMixin() {
    flyAwayCtrl = AnimationController(vsync: this, duration: _flyAwayDuration);
  }

  void disposeMixin() => flyAwayCtrl.dispose();

  /// Sağa kaydırma uçuşu bitti, beğeni yanıtı bekleniyor.
  bool get isWaitingForApi =>
      isProcessing &&
      !flyAwayCtrl.isAnimating &&
      _swipeDirection == _SwipeDirection.right;

  /// Kartın anlık dönüşümü: uçuşta animasyon değeri, sürüklemede parmak ofsetinin kesri.
  Matrix4 cardTransform() {
    final flying = flyAwayCtrl.isAnimating;
    final offset = flying ? _flyAwayAnimation.value : dragOffset * 0.3;
    final rotation =
        flying ? _flyAwayAnimation.value * 0.001 : dragOffset * 0.0005;
    return Matrix4.identity()
      ..setTranslationRaw(offset, 0.0, 0.0)
      ..rotateZ(rotation);
  }

  void onHorizontalDragUpdate(DragUpdateDetails details) {
    if (isProcessing) return;
    setState(() => dragOffset += details.delta.dx);
  }

  void onHorizontalDragEnd(DragEndDetails details) {
    if (isProcessing) return;
    final haptic = ref.read(hapticManagerProvider);
    if (dragOffset > _swipeThreshold) {
      haptic.medium();
      _animateAndNavigateQuiz();
    } else if (dragOffset < -_swipeThreshold) {
      haptic.light();
      _animateAndReject();
    } else {
      setState(() => dragOffset = 0);
    }
  }

  /// Uçuş animasyonunun `then`'i görünüm kapanınca hiç çalışmaz (dispose edilen
  /// ticker'ın future'ı tamamlanmaz) — ayrıca guard gerekmez.
  void _animateAndReject() {
    _startFlyAway(_SwipeDirection.left);
    flyAwayCtrl.forward(from: 0).then((_) {
      widget.onSwipeLeft();
      ref.read(discoverProvider.notifier).rejectCard(widget.card.userId);
      _resetState();
    });
  }

  void _animateAndNavigateQuiz() {
    _startFlyAway(_SwipeDirection.right);
    flyAwayCtrl.forward(from: 0).then((_) => navigateToQuiz());
  }

  void _startFlyAway(_SwipeDirection direction) {
    setState(() {
      isProcessing = true;
      _swipeDirection = direction;
    });
    final screenWidth = MediaQuery.of(context).size.width;
    final end = direction == _SwipeDirection.right ? screenWidth : -screenWidth;
    _flyAwayAnimation =
        Tween<double>(begin: dragOffset, end: end).chain(_curveTween).animate(flyAwayCtrl);
  }

  void _resetState() {
    if (!mounted) return;
    flyAwayCtrl.reset();
    setState(() {
      dragOffset = 0;
      isProcessing = false;
      _swipeDirection = null;
    });
  }

  void navigateToProfile() {
    ref.read(navigationServiceProvider).push(
      RouteNames.profileDetail,
      params: {'userId': widget.card.userId},
      extra: ProfileDetailArgs(
        context: ProfileDetailContext.discover,
        userId: widget.card.userId,
        preloadedCard: widget.card,
      ),
    );
  }

  void rejectByButton() {
    ref.read(hapticManagerProvider).light();
    widget.onSwipeLeft();
    ref.read(discoverProvider.notifier).rejectCard(widget.card.userId);
  }

  /// Beğeni (LIKE) kaydedilir, başarıda quiz açılır. Kart await ÖNCESİ alınır:
  /// istek sürerken deste değişirse `widget.card` başka bir profili gösterir.
  ///
  /// Quiz zaten açıksa (geçiş animasyonu sürerken alttaki yeni karta ikinci
  /// dokunuş) yok sayılır: LIKE kaydedilmez, ikinci quiz açılmaz. 2.0.17'de bu
  /// yol global quiz durumunu sıfırlayıp `sessionId!` fatal'ine yol açtı.
  Future<void> navigateToQuiz() async {
    final nav = ref.read(navigationServiceProvider);
    if (nav.isInStack(RouteNames.quiz)) {
      _resetState();
      return;
    }
    if (!isProcessing) {
      // Button tap — no fly-away needed, just set processing
      setState(() => isProcessing = true);
    }
    widget.onSwipeRight();
    final card = widget.card;
    final result = await ref.read(discoverProvider.notifier).swipe(
      targetId: card.userId,
      action: 'LIKE',
    );
    if (!mounted) return;
    result.when(
      success: (_) {
        nav.push(
          RouteNames.quiz,
          params: {'targetId': card.userId},
          extra: QuizTargetArgs(
            name: card.name,
            photoUrl: card.photos?.firstOrNull,
            distanceKm: card.distanceKm,
          ),
        );
        _resetState();
      },
      failure: (f) {
        _resetState();
        if (f is ServerFailure && f.code == 'DAILY_LIMIT_EXCEEDED') {
          PaywallBottomSheetContent.show(ref, trigger: PaywallTriggers.swipeLimit);
          return;
        }
        // Uyumsuz kart: sağlayıcı desteden düşürdü, kullanıcıya nedeni söylenir.
        if (isNotCompatibleFailure(f)) {
          _showSnack(context.tr(f.userMessageKey('error_general')));
          return;
        }
        // Başarısız quiz'in hedefi kilitli (409 QUIZ_RETRY_LOCKED): ne zaman tekrar denenebileceği.
        final lockMessage = quizRetryLockMessage(f, context.l10n);
        if (lockMessage != null) _showSnack(lockMessage);
      },
    );
  }

  Future<void> handleUndo() async {
    final container = ProviderScope.containerOf(context, listen: false);
    final result = await ref.read(discoverProvider.notifier).undoSwipe();
    result.when(
      success: (_) => container.invalidate(dailyStatsProvider),
      failure: (f) {
        if (!mounted) return;
        _showSnack(quizRetryLockMessage(f, context.l10n) ?? context.tr(undoFailureMessageKey(f)));
      },
    );
  }

  void _showSnack(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
