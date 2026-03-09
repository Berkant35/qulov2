import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/models/app_dialog.dart';

class ConfirmDialogWidget extends StatelessWidget {
  final ConfirmDialog dialog;
  const ConfirmDialogWidget({super.key, required this.dialog});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(dialog.title),
      content: Text(dialog.message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            dialog.cancelText ?? context.tr('cancel'),
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            dialog.confirmText ?? context.tr('confirm'),
            style: TextStyle(
              color: dialog.isDestructive ? AppColors.error : AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
