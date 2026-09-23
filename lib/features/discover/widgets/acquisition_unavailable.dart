import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';

/// Kanal listesi gelmediğinde (ağ/sunucu) kullanıcıyı kilitlememek için tek çıkış;
/// cevapsız kapanır, sonraki Discover girişinde yeniden sorulur.
class AcquisitionUnavailable extends StatelessWidget {
  const AcquisitionUnavailable({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.tr('acq_error'),
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        TextButton(onPressed: onDismiss, child: Text(context.tr('ok'))),
      ],
    );
  }
}
