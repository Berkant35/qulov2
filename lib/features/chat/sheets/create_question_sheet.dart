import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';

class CreateQuestionSheet extends StatefulWidget {
  final String matchId;
  final Function(Map<String, dynamic>) onSubmit;

  const CreateQuestionSheet({
    super.key,
    required this.matchId,
    required this.onSubmit,
  });

  @override
  State<CreateQuestionSheet> createState() => _CreateQuestionSheetState();
}

class _CreateQuestionSheetState extends State<CreateQuestionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _questionCtrl = TextEditingController();
  final _optionACtrl = TextEditingController();
  final _optionBCtrl = TextEditingController();

  String _correctOption = 'A';
  bool _hasUnmatchRisk = false;
  bool _isLoading = false;

  int get _diamondCost => _hasUnmatchRisk ? 15 : 5;

  bool get _isValid =>
      _questionCtrl.text.trim().length >= 3 &&
      _optionACtrl.text.trim().isNotEmpty &&
      _optionBCtrl.text.trim().isNotEmpty;

  @override
  void dispose() {
    _questionCtrl.dispose();
    _optionACtrl.dispose();
    _optionBCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_isValid || _isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      await widget.onSubmit({
        'question_text': _questionCtrl.text.trim(),
        'option_a': _optionACtrl.text.trim(),
        'option_b': _optionBCtrl.text.trim(),
        'correct_option': _correctOption,
        'has_unmatch_risk': _hasUnmatchRisk,
      });
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg),
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textHint,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Title
                  Text(
                    'Soru Olustur',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Question text
                  TextFormField(
                    controller: _questionCtrl,
                    maxLength: 200,
                    maxLines: 3,
                    minLines: 1,
                    style: TextStyle(color: AppColors.textPrimary),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      if (v == null || v.trim().length < 3) {
                        return 'En az 3 karakter giriniz';
                      }
                      return null;
                    },
                    decoration: _inputDecoration(
                      theme,
                      hint: 'Sorunuzu yazin...',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Option A
                  TextFormField(
                    controller: _optionACtrl,
                    maxLength: 100,
                    style: TextStyle(color: AppColors.textPrimary),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Secenek A bos birakilamaz';
                      }
                      return null;
                    },
                    decoration: _inputDecoration(
                      theme,
                      hint: 'Secenek A',
                      suffix: _correctOptionSuffix('A'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Option B
                  TextFormField(
                    controller: _optionBCtrl,
                    maxLength: 100,
                    style: TextStyle(color: AppColors.textPrimary),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Secenek B bos birakilamaz';
                      }
                      return null;
                    },
                    decoration: _inputDecoration(
                      theme,
                      hint: 'Secenek B',
                      suffix: _correctOptionSuffix('B'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Unmatch risk toggle
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceInput,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: SwitchListTile(
                      value: _hasUnmatchRisk,
                      onChanged: (v) => setState(() => _hasUnmatchRisk = v),
                      activeThumbColor: AppColors.error,
                      title: Text(
                        _hasUnmatchRisk
                            ? '\u26a0\ufe0f Riskli soru \u2014 15 \ud83d\udc8e'
                            : 'Normal soru \u2014 5 \ud83d\udc8e',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _hasUnmatchRisk
                              ? AppColors.error
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: _isValid && !_isLoading
                            ? AppColors.primaryButtonGradient
                            : null,
                        color: _isValid && !_isLoading
                            ? null
                            : AppColors.textHint.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: MaterialButton(
                        onPressed: _isValid && !_isLoading ? _submit : null,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: _isLoading
                            ? const AppLoadingWidget.small()
                            : Text(
                                'Gonder ($_diamondCost \ud83d\udc8e)',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _correctOptionSuffix(String option) {
    final isSelected = _correctOption == option;
    return GestureDetector(
      onTap: () => setState(() => _correctOption = option),
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.success.withValues(alpha: 0.2)
              : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.success : AppColors.textHint,
            width: 1.5,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check, size: 16, color: AppColors.success)
            : null,
      ),
    );
  }

  InputDecoration _inputDecoration(
    ThemeData theme, {
    required String hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textHint),
      filled: true,
      fillColor: AppColors.surfaceInput,
      suffixIcon: suffix != null
          ? Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: suffix,
            )
          : null,
      suffixIconConstraints: const BoxConstraints(
        minWidth: 36,
        minHeight: 28,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
    );
  }
}
