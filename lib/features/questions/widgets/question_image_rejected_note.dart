import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';

/// Sunucu görseli reddetti (dosya silindi, yalnız durum kaldı). Kapatma
/// düğmesi ret notunu kaldırır — kayıtta `removeMedia(image)` durumu temizler.
class QuestionImageRejectedNote extends StatelessWidget {
  final VoidCallback onDismiss;

  const QuestionImageRejectedNote({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final color = context.appColors.error;
    return Row(
      children: [
        Expanded(
          child: Text(
            context.tr('question_image_rejected'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
        IconButton(
          onPressed: onDismiss,
          tooltip: context.tr('question_media_remove'),
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.close, color: color),
        ),
      ],
    );
  }
}
