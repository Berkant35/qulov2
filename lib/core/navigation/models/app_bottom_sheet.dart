import 'package:flutter/material.dart';

sealed class AppBottomSheet {
  final String name;
  final bool isDismissible;
  final bool enableDrag;
  final bool useRootNavigator;
  final double? maxHeightFactor;

  const AppBottomSheet({
    required this.name,
    this.isDismissible = true,
    this.enableDrag = true,
    this.useRootNavigator = true,
    this.maxHeightFactor,
  });
}

class SheetOption<T> {
  final IconData? icon;
  final String label;
  final T value;

  const SheetOption({this.icon, required this.label, required this.value});
}

class ListBottomSheet<T> extends AppBottomSheet {
  final String? title;
  final List<SheetOption<T>> options;

  const ListBottomSheet({
    required super.name,
    this.title,
    required this.options,
    super.isDismissible,
    super.enableDrag,
    super.useRootNavigator,
    super.maxHeightFactor,
  });
}

class CustomBottomSheet extends AppBottomSheet {
  final Widget Function(BuildContext context) builder;

  const CustomBottomSheet({
    required super.name,
    required this.builder,
    super.isDismissible,
    super.enableDrag,
    super.useRootNavigator,
    super.maxHeightFactor,
  });
}
