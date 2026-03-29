import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/providers/api_provider.dart';

const _categories = [
  'ACCOUNT',
  'TECHNICAL',
  'BILLING',
  'MATCH',
  'OTHER',
];

class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _selectedCategory = _categories.first;
  bool _isLoading = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    final result = await ref.read(supportTicketRepositoryProvider).createTicket(
          subject: _subjectCtrl.text.trim(),
          message: _messageCtrl.text.trim(),
          category: _selectedCategory,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('ticket_created_success'))),
        );
        Navigator.pop(context, true);
      },
      failure: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('ticket_create_error')),
            backgroundColor: context.appColors.error,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: context.tr('create_ticket'),
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            // Category dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: context.tr('ticket_category'),
                border: const OutlineInputBorder(),
              ),
              items: _categories.map((cat) {
                return DropdownMenuItem<String>(
                  value: cat,
                  child: Text(context.tr('ticket_cat_${cat.toLowerCase()}')),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Subject
            TextFormField(
              controller: _subjectCtrl,
              decoration: InputDecoration(
                labelText: context.tr('ticket_subject'),
                border: const OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().length < 5) {
                  return context.tr('ticket_subject_min_chars');
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Message
            TextFormField(
              controller: _messageCtrl,
              decoration: InputDecoration(
                labelText: context.tr('ticket_message'),
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 6,
              validator: (val) {
                if (val == null || val.trim().length < 10) {
                  return context.tr('ticket_message_min_chars');
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xl),

            // Submit button
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const AppLoadingWidget.small()
                  : Text(context.tr('submit')),
            ),
          ],
        ),
      ),
    );
  }
}
