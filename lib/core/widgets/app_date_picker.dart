import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';

class AppDatePicker extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final String? errorText;

  const AppDatePicker({
    super.key,
    this.selectedDate,
    required this.onDateSelected,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _showPicker(context),
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: l10n.get('birthday'),
              errorText: errorText,
              prefixIcon: const Icon(Icons.cake_outlined),
              suffixIcon: const Icon(Icons.calendar_today_outlined),
            ),
            child: Text(
              selectedDate != null
                  ? '${selectedDate!.day.toString().padLeft(2, '0')}/'
                    '${selectedDate!.month.toString().padLeft(2, '0')}/'
                    '${selectedDate!.year}'
                  : l10n.get('select_date'),
              style: selectedDate != null
                  ? theme.textTheme.bodyLarge
                  : theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showPicker(BuildContext context) async {
    final now = DateTime.now();
    final maxDate = DateTime(now.year - 18, now.month, now.day);
    final minDate = DateTime(now.year - 100);

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? maxDate,
      firstDate: minDate,
      lastDate: maxDate,
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
              headerBackgroundColor: AppColors.primaryDark,
              headerForegroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateSelected(picked);
    }
  }
}
