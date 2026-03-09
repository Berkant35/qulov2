import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/core/widgets/app_date_picker.dart';

class RegisterStepBirthday extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final String? errorText;
  final VoidCallback onContinue;

  const RegisterStepBirthday({
    super.key,
    this.selectedDate,
    required this.onDateSelected,
    this.errorText,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.get('step_birthday'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppDatePicker(
            selectedDate: selectedDate,
            onDateSelected: onDateSelected,
            errorText: errorText,
          ),
          const Spacer(),
          AppButton(
            label: l10n.get('continue_btn'),
            onPressed: onContinue,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
