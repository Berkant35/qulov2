import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/features/email_verification/email_verification_controller.dart';
import 'package:qulo_v2/features/email_verification/widgets/email_verification_sheet.dart';

/// Doğrulama sayfasının durumu: tekrar gönder, "Doğruladım", şimdi değil.
///
/// Alt sayfa route'u GoRouter'ın değil (bkz. `PushPermissionSheet`):
/// `Navigator` ile kapanır; sonuç `true` = doğrulandı.
mixin EmailVerificationSheetMixin on ConsumerState<EmailVerificationSheet> {
  bool isResending = false;
  bool isChecking = false;

  /// Sayfadaki bilgi satırının çeviri anahtarı (gönderildi / henüz değil / hata).
  String? noticeKey;
  bool noticeIsError = false;

  EmailVerificationController get _controller =>
      ref.read(emailVerificationControllerProvider);

  bool get isBusy => isResending || isChecking;

  Future<void> resend() async {
    if (isBusy) return;
    setState(() => isResending = true);
    final outcome = await _controller.resend();
    if (!mounted) return;
    setState(() => isResending = false);
    switch (outcome) {
      case ResendOutcome.alreadyVerified:
        _closeVerified();
      case ResendOutcome.sent:
        _showNotice('email_verify_sent', isError: false);
      case ResendOutcome.rateLimited:
        _showNotice('email_verify_rate_limited', isError: true);
      case ResendOutcome.failed:
        _showNotice('email_verify_resend_failed', isError: true);
    }
  }

  Future<void> confirm() async {
    if (isBusy) return;
    setState(() => isChecking = true);
    final verified = await _controller.confirmVerified(trigger: widget.trigger);
    if (!mounted) return;
    setState(() => isChecking = false);
    if (verified) {
      _closeVerified();
    } else {
      _showNotice('email_verify_not_yet', isError: true);
    }
  }

  void later() => Navigator.of(context).pop(false);

  void _showNotice(String key, {required bool isError}) => setState(() {
        noticeKey = key;
        noticeIsError = isError;
      });

  void _closeVerified() {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final text = context.tr('email_verify_success');
    Navigator.of(context).pop(true);
    messenger?.showSnackBar(SnackBar(content: Text(text)));
  }
}
