import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';

/// "Hesabin yok mu? Kayit Ol" satiri
class LoginRegisterPrompt extends StatelessWidget {
  final VoidCallback onRegisterTap;

  const LoginRegisterPrompt({super.key, required this.onRegisterTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(context.tr('no_account'), style: theme.textTheme.bodyMedium),
        TextButton(
          onPressed: onRegisterTap,
          child: Text(context.tr('register')),
        ),
      ],
    );
  }
}
