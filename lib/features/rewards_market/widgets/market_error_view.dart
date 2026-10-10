import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/network/failure_message.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/widgets/error_retry_widget.dart';

/// Market yüklenemedi: erişim kapalıysa (403 RAINBOW_NOT_AVAILABLE) yeniden dene yok.
class MarketErrorView extends StatelessWidget {
  const MarketErrorView({super.key, required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final failure = error;
    if (failure is ServerFailure && failure.code == 'RAINBOW_NOT_AVAILABLE') {
      return ErrorRetryWidget(message: context.tr('rainbow_not_available'));
    }
    final key = failure is AppFailure ? failure.userMessageKey('market_load_failed') : 'market_load_failed';
    return ErrorRetryWidget(message: context.tr(key), onRetry: onRetry);
  }
}
