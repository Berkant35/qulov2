import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/data/models/support_ticket_model.dart';
import 'package:qulo_v2/features/settings/screens/create_ticket_screen.dart';
import 'package:qulo_v2/providers/api_provider.dart';

final _myTicketsProvider = FutureProvider.autoDispose<List<SupportTicketModel>>(
  (ref) async {
    final result = await ref.read(supportTicketRepositoryProvider).getMyTickets();
    return result.when(
      success: (tickets) => tickets,
      failure: (_) => [],
    );
  },
);

class MyTicketsScreen extends ConsumerWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_myTicketsProvider);

    return AppScaffold(
      title: context.tr('my_tickets'),
      padding: EdgeInsets.zero,
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: context.tr('create_ticket'),
          onPressed: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const CreateTicketScreen()),
            );
            if (result == true) {
              ref.invalidate(_myTicketsProvider);
            }
          },
        ),
      ],
      isLoading: state is AsyncLoading,
      body: state.when(
        loading: () => const SizedBox.shrink(),
        error: (error, _) => Center(
          child: Text(
            error.toString(),
            style: TextStyle(color: context.appColors.error),
          ),
        ),
        data: (tickets) {
          if (tickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.support_agent,
                    size: 64,
                    color: context.appColors.textHint,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    context.tr('no_tickets'),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CreateTicketScreen()),
                      );
                      if (result == true) {
                        ref.invalidate(_myTicketsProvider);
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: Text(context.tr('create_ticket')),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: tickets.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return _TicketListItem(ticket: ticket);
            },
          );
        },
      ),
    );
  }
}

class _TicketListItem extends StatelessWidget {
  final SupportTicketModel ticket;

  const _TicketListItem({required this.ticket});

  Color _statusColor(BuildContext context, String status) {
    return switch (status) {
      'OPEN' => context.appColors.warning,
      'IN_PROGRESS' => context.appColors.info,
      'RESOLVED' => context.appColors.success,
      'CLOSED' => context.appColors.textHint,
      _ => context.appColors.textHint,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasReply = ticket.adminReply != null;
    final statusColor = _statusColor(context, ticket.status);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.xs,
      ),
      title: Text(
        ticket.subject,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Text(
            ticket.category,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          if (hasReply) ...[
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.reply, size: 14, color: context.appColors.success),
            const SizedBox(width: 2),
            Text(
              context.tr('ticket_replied'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.appColors.success,
              ),
            ),
          ],
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs / 2,
        ),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Text(
          ticket.status,
          style: theme.textTheme.labelSmall?.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
