import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';

mixin FormMixin<T extends StatefulWidget> on State<T> {
  final formKey = GlobalKey<FormState>();

  static final _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
  );

  bool validateForm() => formKey.currentState?.validate() ?? false;

  String? requiredValidator(String? value, [String? field]) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context).get('field_required');
    }
    return null;
  }

  String? emailValidator(String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.trim().isEmpty) return l10n.get('email_required');
    if (!_emailRegex.hasMatch(value.trim())) {
      return l10n.get('email_invalid');
    }
    return null;
  }

  String? passwordValidator(String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) return l10n.get('password_required');
    if (value.length < 8) return l10n.get('password_min');
    return null;
  }
}
