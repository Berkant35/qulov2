import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:qulo_v2/core/constants/profile_field_limits.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final FocusNode? focusNode;
  final int maxLines;
  final int? maxLength;
  final TextCapitalization textCapitalization;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onFieldSubmitted,
    this.inputFormatters,
    this.enabled = true,
    this.focusNode,
    this.maxLines = 1,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      inputFormatters: inputFormatters,
      enabled: enabled,
      maxLines: maxLines,
      maxLength: maxLength,
      // Toplam sayac (12/300) hicbir yerde gosterilmez; sadece limite yaklasinca
      // (kalan <= esik) "Son X karakter kaldi" uyarisi cikar.
      buildCounter: (context,
              {required currentLength, required maxLength, required isFocused}) =>
          _RemainingCharsCounter(
        currentLength: currentLength,
        maxLength: maxLength,
      ),
      textCapitalization: textCapitalization,
    );
  }
}

/// Input altinda toplam sayac yerine yalnizca "Son X karakter kaldi" uyarisini
/// gosterir; kalan karakter [ProfileFieldLimits.remainingWarningThreshold]
/// esiginin uzerindeyse hicbir sey gostermez.
class _RemainingCharsCounter extends StatelessWidget {
  final int currentLength;
  final int? maxLength;

  const _RemainingCharsCounter({
    required this.currentLength,
    required this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    final max = maxLength;
    if (max == null) return const SizedBox.shrink();

    final remaining = max - currentLength;
    if (remaining < 0 ||
        remaining > ProfileFieldLimits.remainingWarningThreshold) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Text(
      context.tr('chars_remaining').replaceAll('{count}', '$remaining'),
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
