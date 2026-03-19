import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';

class EditProfileSaveButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback? onSave;

  const EditProfileSaveButton({
    super.key,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
              color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: AppButton(
          label: context.tr('save'),
          isLoading: isSaving,
          fullWidth: true,
          onPressed: isSaving ? null : onSave,
        ),
      ),
    );
  }
}
