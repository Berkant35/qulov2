import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/navigation/models/app_bottom_sheet.dart';

class ListBottomSheetWidget<T> extends StatelessWidget {
  final ListBottomSheet<T> sheet;
  const ListBottomSheetWidget({super.key, required this.sheet});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.hintColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (sheet.title != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                sheet.title!,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ...sheet.options.map((option) => ListTile(
                leading: option.icon != null
                    ? Icon(option.icon, color: theme.colorScheme.onSurfaceVariant)
                    : null,
                title: Text(option.label),
                onTap: () => Navigator.of(context).pop(option.value),
              )),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
