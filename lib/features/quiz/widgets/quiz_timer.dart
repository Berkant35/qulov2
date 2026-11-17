import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/app_durations.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/services/haptic_manager.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

class QuizTimer extends StatefulWidget {
  /// Uyarı eşiği (sn): sayı nabız atar, [onWarning].
  static const warningSeconds = 10;

  /// Kritik eşik (sn): çubuk kırmızı, sayı titrer, [onCritical].
  static const criticalSeconds = 5;

  /// Sayacın başladığı saniye (yeniden açılışta sunucunun kalan süresi).
  final int seconds;

  /// İlerleme çubuğunun paydası (sorunun tam süresi); verilmezse [seconds].
  final int? totalSeconds;
  final String questionId;
  final VoidCallback onTimeout;
  final VoidCallback? onWarning;
  final VoidCallback? onCritical;

  /// Medya (ses/görsel) için sayacın en fazla bu kadar saniye [seconds]'ta beklemesi;
  /// [QuizTimerState.release] daha erken bitirir. 0 → eski davranış birebir.
  ///
  /// Zamanlama değişmezi (sunucu son anı): çağıran `seconds = min(L, R)` ve
  /// `holdSeconds ≤ R − L` verir (`QuizQuestionModel.mediaHoldSeconds`). Tutma `h` sn sonra
  /// bitince sayım `min(L, R − h)` = `seconds`'tan başlar (h ≤ R − L ⇒ R − h ≥ L); sayaç
  /// h + L ≤ R anında 0'a iner — `remaining_seconds` içindeki ek süre iki kez sayılmaz.
  final int holdSeconds;

  const QuizTimer({
    super.key,
    required this.seconds,
    this.totalSeconds,
    required this.questionId,
    required this.onTimeout,
    this.onWarning,
    this.onCritical,
    this.holdSeconds = 0,
  });

  @override
  State<QuizTimer> createState() => QuizTimerState();
}

class QuizTimerState extends State<QuizTimer> with TickerProviderStateMixin {
  late int _remaining;
  Timer? _timer;
  Timer? _holdTimer;
  bool _isPaused = false;

  int get remainingSeconds => _remaining;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  // Shake animation for the critical seconds (translate X)
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  static const double _pulseScale = 1.15;
  static const double _shakeOffset = 2.0;
  static const double _barHeight = 6;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;

    _pulseController = AnimationController(
      vsync: this,
      duration: AppDurations.quizTimerPulse,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: _pulseScale).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: AppDurations.quizTimerShake,
    );
    _shakeAnimation = Tween<double>(begin: -_shakeOffset, end: _shakeOffset).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );

    _startTimer();
  }

  @override
  void didUpdateWidget(QuizTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.questionId != widget.questionId) {
      _cancelTimers();
      _pulseController.reset();
      _shakeController.reset();
      _remaining = widget.seconds;
      _isPaused = false;
      _startTimer();
    }
  }

  /// Tutma varsa önce bekler (sayı [QuizTimer.seconds]'ta durur), yoksa hemen sayar.
  void _startTimer() {
    final hold = widget.holdSeconds;
    if (hold <= 0) {
      _startTicking();
      return;
    }
    _holdTimer = Timer(Duration(seconds: hold), release);
  }

  /// Tutma ve sayım zamanlayıcılarını iptal edip bırakır: bayat tutma tutamacı, sonraki
  /// sorunun geç `release()`'ında ikinci bir periyodik sayaç kurdurmasın.
  void _cancelTimers() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _timer?.cancel();
    _timer = null;
  }

  /// Her zaman TEK periyodik sayaç: varsa öncekini iptal eder.
  void _startTicking() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPaused) return;
      if (_remaining <= 1) {
        _timer?.cancel();
        _pulseController.stop();
        _shakeController.stop();
        widget.onTimeout();
      } else {
        setState(() => _remaining--);
        _updateAnimations();
      }
    });
  }

  // ── Public API ──────────────────────────────────────────────
  /// Medya hazır: tutmayı bitirir, sayım bir sonraki saniyede başlar. Tutma yoksa ya da
  /// bittiyse etkisiz. [pause]'dan bağımsızdır: duraklıyken çağrılırsa [resume]'a dek sayılmaz.
  void release() {
    final hold = _holdTimer;
    if (hold == null) return;
    hold.cancel();
    _holdTimer = null;
    _startTicking();
  }

  void pause() {
    _isPaused = true;
  }

  void resume() {
    _isPaused = false;
  }

  void addSeconds(int extra) {
    setState(() {
      _remaining += extra;
    });
  }

  void _updateAnimations() {
    if (_remaining == QuizTimer.warningSeconds && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
      HapticManager.instance.warning();
      widget.onWarning?.call();
    }

    if (_remaining == QuizTimer.criticalSeconds) {
      HapticManager.instance.heavy();
      widget.onCritical?.call();
    }
    if (_remaining <= QuizTimer.criticalSeconds) {
      HapticManager.instance.light();
      _shakeController.forward().then((_) => _shakeController.reverse());
    }
  }

  Color get _barColor {
    if (_remaining <= QuizTimer.criticalSeconds) return context.appColors.error;
    if (_remaining <= QuizTimer.warningSeconds) return context.appColors.warning;
    return context.appColors.secondary;
  }

  @override
  void dispose() {
    _cancelTimers();
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.totalSeconds ?? widget.seconds;
    final progress = total <= 0 ? 0.0 : (_remaining / total).clamp(0.0, 1.0);
    final color = _barColor;

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final dx = _remaining <= QuizTimer.criticalSeconds ? _shakeAnimation.value : 0.0;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: child,
        );
      },
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm / 2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: _barHeight,
              backgroundColor: context.appColors.surfaceElevated,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = _remaining <= QuizTimer.warningSeconds ? _pulseAnimation.value : 1.0;
              return Transform.scale(scale: scale, child: child);
            },
            child: Text(
              context.fmt.seconds(_remaining),
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
