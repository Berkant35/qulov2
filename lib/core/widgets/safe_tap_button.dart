import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/app_durations.dart';

typedef SafeTapWidgetBuilder = Widget Function(
  BuildContext context,
  bool isLoading,
  VoidCallback? onTap,
);

class SafeTapButton extends StatefulWidget {
  final Future<void> Function()? onTap;
  final Duration debounceDuration;
  final SafeTapWidgetBuilder builder;

  const SafeTapButton({
    super.key,
    required this.onTap,
    required this.builder,
    this.debounceDuration = AppDurations.debounce,
  });

  @override
  State<SafeTapButton> createState() => _SafeTapButtonState();
}

class _SafeTapButtonState extends State<SafeTapButton> {
  bool _isRunning = false;
  Timer? _cooldownTimer;

  Future<void> _handleTap() async {
    if (_isRunning || widget.onTap == null) return;

    setState(() => _isRunning = true);

    try {
      await widget.onTap!();
    } finally {
      if (mounted) {
        _cooldownTimer = Timer(widget.debounceDuration, () {
          if (mounted) setState(() => _isRunning = false);
        });
      }
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onTap == null;
    return widget.builder(
      context,
      _isRunning,
      isDisabled ? null : (_isRunning ? null : _handleTap),
    );
  }
}
