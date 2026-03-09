import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

class QuizTimer extends StatefulWidget {
  final int seconds;
  final VoidCallback onTimeout;

  const QuizTimer({super.key, required this.seconds, required this.onTimeout});

  @override
  State<QuizTimer> createState() => _QuizTimerState();
}

class _QuizTimerState extends State<QuizTimer> {
  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _startTimer();
  }

  @override
  void didUpdateWidget(QuizTimer old) {
    super.didUpdateWidget(old);
    if (old.seconds != widget.seconds) {
      _timer?.cancel();
      _remaining = widget.seconds;
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 1) {
        _timer?.cancel();
        widget.onTimeout();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _remaining / widget.seconds;
    final color = progress > 0.3 ? AppColors.secondary : AppColors.error;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Theme.of(context).colorScheme.outline,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text('$_remaining s', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color)),
      ],
    );
  }
}
