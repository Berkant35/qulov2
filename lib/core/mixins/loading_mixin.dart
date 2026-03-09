import 'package:flutter/material.dart';

mixin LoadingMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> withLoading(Future<void> Function() action) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
