import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/mixins/form_mixin.dart';
import 'package:qulo_v2/core/mixins/loading_mixin.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/features/auth/screens/forgot_password_screen.dart';
import 'package:qulo_v2/providers/auth_provider.dart';

/// [ForgotPasswordScreen] logic'i: e-posta alanı ve sıfırlama bağlantısı gönderimi.
mixin ForgotPasswordScreenMixin
    on
        ConsumerState<ForgotPasswordScreen>,
        FormMixin<ForgotPasswordScreen>,
        LoadingMixin<ForgotPasswordScreen> {
  final emailCtrl = TextEditingController();

  void disposeMixin() => emailCtrl.dispose();

  Future<void> send() => withLoading(() async {
        if (!validateForm()) return;
        await ref.read(authProvider.notifier).forgotPassword(emailCtrl.text.trim());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('reset_email_sent'))),
        );
        ref.read(navigationServiceProvider).pop();
      });
}
