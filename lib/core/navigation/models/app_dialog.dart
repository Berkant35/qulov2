import 'package:flutter/material.dart';

sealed class AppDialog {
  final String name;
  final bool barrierDismissible;
  final bool useRootNavigator;

  const AppDialog({
    required this.name,
    this.barrierDismissible = true,
    this.useRootNavigator = true,
  });
}

class ConfirmDialog extends AppDialog {
  final String title;
  final String message;
  final String? confirmText;
  final String? cancelText;
  final bool isDestructive;

  const ConfirmDialog({
    required super.name,
    required this.title,
    required this.message,
    this.confirmText,
    this.cancelText,
    this.isDestructive = false,
    super.barrierDismissible = false,
    super.useRootNavigator,
  });
}

class InfoDialog extends AppDialog {
  final String title;
  final String message;
  final Widget? iconWidget;
  final String? buttonText;

  const InfoDialog({
    required super.name,
    required this.title,
    required this.message,
    this.iconWidget,
    this.buttonText,
    super.barrierDismissible = false,
    super.useRootNavigator,
  });
}

class CustomDialog extends AppDialog {
  final Widget Function(BuildContext context) builder;

  const CustomDialog({
    required super.name,
    required this.builder,
    super.barrierDismissible,
    super.useRootNavigator,
  });
}
