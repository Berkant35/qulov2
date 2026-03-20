import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/services/haptic_manager.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

class QuizTimer extends StatefulWidget {
  final int seconds;
  final VoidCallback onTimeout;
  final VoidCallback? onWarning;
  final VoidCallback? onCritical;

  const QuizTimer({
    super.key,
    required this.seconds,
    required this.onTimeout,
    this.onWarning,
    this.onCritical,
  });

  @override
  State<QuizTimer> createState() => QuizTimerState();
}

class QuizTimerState extends State<QuizTimer> with TickerProviderStateMixin {
  late int _remaining;
  Timer? _timer;
  bool _isPaused = false;

  int get remainingSeconds => _remaining;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  // Shake animation for last 5 seconds (translate X)
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _shakeAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );

    _startTimer();
  }

  @override
  void didUpdateWidget(QuizTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seconds != widget.seconds) {
      _timer?.cancel();
      _pulseController.reset();
      _shakeController.reset();
      _remaining = widget.seconds;
      _isPaused = false;
      _startTimer();
    }
  }

  void _startTimer() {
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
    if (_remaining == 10 && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
      HapticManager.instance.warning();
      widget.onWarning?.call();
    }

    if (_remaining == 5) {
      HapticManager.instance.heavy();
      widget.onCritical?.call();
    }
    if (_remaining <= 5) {
      HapticManager.instance.light();
      _shakeController.forward().then((_) => _shakeController.reverse());
    }
  }

  Color get _barColor {
    if (_remaining <= 5) return AppColors.error;
    if (_remaining <= 10) return Colors.orange;
    return AppColors.secondary;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _remaining / widget.seconds;
    final color = _barColor;

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final dx = _remaining <= 5 ? _shakeAnimation.value : 0.0;
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
              minHeight: 6,
              backgroundColor: context.appColors.surfaceElevated,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = _remaining <= 10 ? _pulseAnimation.value : 1.0;
              return Transform.scale(scale: scale, child: child);
            },
            child: Text(
              '$_remaining s',
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
