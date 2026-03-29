import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation_provider.dart';
import 'package:qulo_v2/core/navigation/models/app_dialog.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/providers/api_provider.dart';

final _blockedUsersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async {
    final result = await ref.read(blockRepositoryProvider).getBlockedUsers();
    return result.when(
      success: (users) => users,
      failure: (_) => [],
    );
  },
);

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_blockedUsersProvider);

    return AppScaffold(
      title: context.tr('blocked_users'),
      padding: EdgeInsets.zero,
      isLoading: state is AsyncLoading,
      body: state.when(
        loading: () => const SizedBox.shrink(),
        error: (error, _) => Center(
          child: Text(
            error.toString(),
            style: TextStyle(color: context.appColors.error),
          ),
        ),
        data: (users) {
          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.block,
                    size: 64,
                    color: context.appColors.textMuted,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    context.tr('blocked_users_empty'),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = users[index];
              final blockedUser = user['blocked_user'] as Map<String, dynamic>?;
              final name = blockedUser?['name'] as String? ?? context.tr('unknown_user');
              final photoUrl = (blockedUser?['photos'] as List?)?.firstOrNull as String?;
              final blockedId = user['blocked_id'] as String? ?? '';

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding,
                  vertical: AppSpacing.xs,
                ),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                  backgroundImage: photoUrl != null
                      ? CachedNetworkImageProvider(photoUrl)
                      : null,
                  child: photoUrl == null
                      ? Icon(
                          Icons.person,
                          size: 24,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )
                      : null,
                ),
                title: Text(
                  name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                trailing: TextButton(
                  onPressed: () => _confirmUnblock(context, ref, blockedId, name),
                  child: Text(
                    context.tr('unblock'),
                    style: TextStyle(color: context.appColors.primary),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmUnblock(
    BuildContext context,
    WidgetRef ref,
    String blockedId,
    String name,
  ) async {
    final nav = ref.read(navigationServiceProvider);
    final confirmed = await nav.showAppDialog<bool>(
      ConfirmDialog(
        name: 'unblock_user',
        title: context.tr('unblock_user_title'),
        message: context.tr('unblock_user_message'),
        confirmText: context.tr('unblock'),
        cancelText: context.tr('cancel'),
      ),
    );
    if (confirmed != true) return;
    await ref.read(blockRepositoryProvider).unblockUser(blockedId);
    ref.invalidate(_blockedUsersProvider);
  }
}
