import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/models/app_dialog.dart';

class InfoDialogWidget extends StatelessWidget {
  final InfoDialog dialog;
  const InfoDialogWidget({super.key, required this.dialog});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: dialog.iconWidget,
      title: Text(dialog.title),
      content: Text(dialog.message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(dialog.buttonText ?? context.tr('ok')),
        ),
      ],
    );
  }
}
