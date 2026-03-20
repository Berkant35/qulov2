import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

class ChatQuestionStep1 extends StatefulWidget {
  final int optionCount;
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctOption;
  final void Function({
    int? optionCount,
    String? questionText,
    String? optionA,
    String? optionB,
    String? optionC,
    String? optionD,
    String? correctOption,
  }) onChanged;

  const ChatQuestionStep1({
    super.key,
    required this.optionCount,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctOption,
    required this.onChanged,
  });

  @override
  State<ChatQuestionStep1> createState() => _ChatQuestionStep1State();
}

class _ChatQuestionStep1State extends State<ChatQuestionStep1> {
  late final TextEditingController _questionCtrl;
  late final TextEditingController _optionACtrl;
  late final TextEditingController _optionBCtrl;
  late final TextEditingController _optionCCtrl;
  late final TextEditingController _optionDCtrl;

  @override
  void initState() {
    super.initState();
    _questionCtrl = TextEditingController(text: widget.questionText);
    _optionACtrl = TextEditingController(text: widget.optionA);
    _optionBCtrl = TextEditingController(text: widget.optionB);
    _optionCCtrl = TextEditingController(text: widget.optionC);
    _optionDCtrl = TextEditingController(text: widget.optionD);
  }

  @override
  void didUpdateWidget(covariant ChatQuestionStep1 oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync controllers when parent fills from draft
    if (widget.questionText != _questionCtrl.text) {
      _questionCtrl.text = widget.questionText;
    }
    if (widget.optionA != _optionACtrl.text) {
      _optionACtrl.text = widget.optionA;
    }
    if (widget.optionB != _optionBCtrl.text) {
      _optionBCtrl.text = widget.optionB;
    }
    if (widget.optionC != _optionCCtrl.text) {
      _optionCCtrl.text = widget.optionC;
    }
    if (widget.optionD != _optionDCtrl.text) {
      _optionDCtrl.text = widget.optionD;
    }
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _optionACtrl.dispose();
    _optionBCtrl.dispose();
    _optionCCtrl.dispose();
    _optionDCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            'Soru Icerigi',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Option count toggle
          _OptionCountToggle(
            optionCount: widget.optionCount,
            onChanged: (count) {
              widget.onChanged(optionCount: count);
              // Reset correct option if switching from 4 to 2
              if (count == 2 &&
                  (widget.correctOption == 'C' ||
                      widget.correctOption == 'D')) {
                widget.onChanged(correctOption: 'A');
              }
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // Question text
          _buildLabel(Theme.of(context), 'Soru'),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: _questionCtrl,
            maxLength: 200,
            maxLines: 3,
            minLines: 1,
            style: TextStyle(color: context.appColors.textPrimary),
            onChanged: (v) => widget.onChanged(questionText: v),
            decoration: _inputDecoration(context, 'Sorunuzu yazin...'),
          ),
          const SizedBox(height: AppSpacing.md),

          // Options
          _buildLabel(Theme.of(context), 'Secenekler'),
          const SizedBox(height: AppSpacing.xs),
          _OptionField(
            label: 'A',
            controller: _optionACtrl,
            isCorrect: widget.correctOption == 'A',
            onChanged: (v) => widget.onChanged(optionA: v),
            onSelectCorrect: () => widget.onChanged(correctOption: 'A'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _OptionField(
            label: 'B',
            controller: _optionBCtrl,
            isCorrect: widget.correctOption == 'B',
            onChanged: (v) => widget.onChanged(optionB: v),
            onSelectCorrect: () => widget.onChanged(correctOption: 'B'),
          ),
          if (widget.optionCount == 4) ...[
            const SizedBox(height: AppSpacing.sm),
            _OptionField(
              label: 'C',
              controller: _optionCCtrl,
              isCorrect: widget.correctOption == 'C',
              onChanged: (v) => widget.onChanged(optionC: v),
              onSelectCorrect: () => widget.onChanged(correctOption: 'C'),
            ),
            const SizedBox(height: AppSpacing.sm),
            _OptionField(
              label: 'D',
              controller: _optionDCtrl,
              isCorrect: widget.correctOption == 'D',
              onChanged: (v) => widget.onChanged(optionD: v),
              onSelectCorrect: () => widget.onChanged(correctOption: 'D'),
            ),
          ],
          const SizedBox(height: AppSpacing.md),

          // Hint for correct answer selection
          Row(
            children: [
              Icon(Icons.info_outline,
                  size: 14, color: context.appColors.textHint),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Dogru cevabi secmek icin secenek yanindaki daireye dokunun',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.appColors.textHint,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildLabel(ThemeData theme, String text) {
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: context.appColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.appColors.textHint),
      filled: true,
      fillColor: context.appColors.surfaceElevated,
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
    );
  }
}

class _OptionCountToggle extends StatelessWidget {
  final int optionCount;
  final ValueChanged<int> onChanged;

  const _OptionCountToggle({
    required this.optionCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildChip(context, Theme.of(context), '2 Sik', 2),
        const SizedBox(width: AppSpacing.sm),
        _buildChip(context, Theme.of(context), '4 Sik', 4),
      ],
    );
  }

  Widget _buildChip(BuildContext context, ThemeData theme, String label, int value) {
    final isSelected = optionCount == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primarySurface
              : context.appColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.primary : context.appColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isSelected ? AppColors.primary : context.appColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _OptionField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isCorrect;
  final ValueChanged<String> onChanged;
  final VoidCallback onSelectCorrect;

  const _OptionField({
    required this.label,
    required this.controller,
    required this.isCorrect,
    required this.onChanged,
    required this.onSelectCorrect,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLength: 100,
      style: TextStyle(color: context.appColors.textPrimary),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Secenek $label',
        hintStyle: TextStyle(color: context.appColors.textHint),
        filled: true,
        fillColor: context.appColors.surfaceElevated,
        counterText: '',
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: GestureDetector(
            onTap: onSelectCorrect,
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isCorrect
                    ? AppColors.success.withValues(alpha: 0.2)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCorrect ? AppColors.success : context.appColors.textHint,
                  width: 1.5,
                ),
              ),
              child: isCorrect
                  ? const Icon(Icons.check, size: 16, color: AppColors.success)
                  : null,
            ),
          ),
        ),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }
}
