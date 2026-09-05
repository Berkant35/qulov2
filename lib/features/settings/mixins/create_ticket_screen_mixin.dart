import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/features/settings/screens/create_ticket_screen.dart';
import 'package:qulo_v2/providers/api_provider.dart';

/// [CreateTicketScreen] icin sunum-disi logic: form gonderimi ve sonuc geri bildirimi.
mixin CreateTicketScreenMixin on ConsumerState<CreateTicketScreen> {
  final formKey = GlobalKey<FormState>();
  final subjectCtrl = TextEditingController();
  final messageCtrl = TextEditingController();

  String selectedCategory = ticketCategories.first;
  bool isSubmitting = false;

  void disposeMixin() {
    subjectCtrl.dispose();
    messageCtrl.dispose();
  }

  void onCategoryChanged(String category) =>
      setState(() => selectedCategory = category);

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => isSubmitting = true);

    final result = await ref.read(supportTicketRepositoryProvider).createTicket(
          subject: subjectCtrl.text.trim(),
          message: messageCtrl.text.trim(),
          category: selectedCategory,
        );

    if (!mounted) return;
    setState(() => isSubmitting = false);

    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('ticket_created_success'))),
        );
        ref.read(navigationServiceProvider).pop(true);
      },
      failure: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('ticket_create_error')),
            backgroundColor: context.appColors.error,
          ),
        );
      },
    );
  }
}
