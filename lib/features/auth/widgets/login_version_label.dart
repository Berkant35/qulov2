import 'package:flutter/material.dart';

/// "Powered by Socrepho • vX.Y.Z" alt etiketi
class LoginVersionLabel extends StatelessWidget {
  final String appVersion;

  const LoginVersionLabel({super.key, required this.appVersion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'Powered by Socrepho${appVersion.isNotEmpty ? ' • v$appVersion' : ''}',
      textAlign: TextAlign.center,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
      ),
    );
  }
}
