import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/features/settings/mixins/create_ticket_screen_mixin.dart';

const ticketCategories = [
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

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen>
    with CreateTicketScreenMixin {
  @override
  void dispose() {
    disposeMixin();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.tr('create_ticket'),
      body: Form(
        key: formKey,
        child: ListView(
          children: [
            // Category dropdown
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: InputDecoration(
                labelText: context.tr('ticket_category'),
                border: const OutlineInputBorder(),
              ),
              items: ticketCategories.map((cat) {
                return DropdownMenuItem<String>(
                  value: cat,
                  child: Text(context.tr('ticket_cat_${cat.toLowerCase()}')),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) onCategoryChanged(val);
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Subject
            TextFormField(
              controller: subjectCtrl,
              maxLength: 200,
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
              controller: messageCtrl,
              maxLength: 2000,
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
              onPressed: isSubmitting ? null : submit,
              child: isSubmitting
                  ? const AppLoadingWidget.small()
                  : Text(context.tr('submit')),
            ),
          ],
        ),
      ),
    );
  }
}
