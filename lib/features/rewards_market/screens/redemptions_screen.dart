import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_icon.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/empty_state_view.dart';
import 'package:qulo_v2/core/widgets/error_retry_widget.dart';
import 'package:qulo_v2/features/rewards_market/mixins/redemptions_screen_mixin.dart';
import 'package:qulo_v2/features/rewards_market/providers/redemptions_provider.dart';
import 'package:qulo_v2/features/rewards_market/widgets/redemption_tile.dart';
import 'package:qulo_v2/features/rewards_market/widgets/redemptions_list_footer.dart';

/// "Hediye kartlarım" (spec §7.5) — Rainbow kapalıyken de erişilir.
class RedemptionsScreen extends ConsumerStatefulWidget {
  const RedemptionsScreen({super.key});

  @override
  ConsumerState<RedemptionsScreen> createState() => _RedemptionsScreenState();
}

class _RedemptionsScreenState extends ConsumerState<RedemptionsScreen> with RedemptionsScreenMixin {
  @override
  void initState() {
    super.initState();
    initMixin();
  }

  @override
  void dispose() {
    disposeMixin();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(redemptionsProvider);
    final state = async.valueOrNull;
    // Refresh/loadMore sırasında `state` önceki değerini korur (bkz. RedemptionsNotifier.refresh
    // → copyWithPrevious) — tam sayfa yükleyici/hata görünümü yalnız HİÇ değer yokken gösterilir,
    // aksi halde liste (pull-to-refresh'in kendi göstergesiyle) ekranda kalır.
    final showFullPageLoader = async.isLoading && !async.hasValue;
    final showErrorView = async.hasError && !async.hasValue;
    return AppScaffold(
      title: context.tr('market_my_gift_cards'),
      isLoading: showFullPageLoader,
      padding: EdgeInsets.zero,
      body: showErrorView
          ? ErrorRetryWidget(message: context.tr('redemptions_load_failed'), onRetry: refresh)
          : RefreshIndicator(
              onRefresh: refresh,
              child: (state == null || state.items.isEmpty)
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        EmptyStateView(icon: const AppIcon(QIcons.gift, size: 48), title: context.tr('redemptions_empty')),
                      ],
                    )
                  : ListView.separated(
                      controller: scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.pagePadding),
                      itemCount: state.items.length + (state.isLoadingMore || state.loadMoreFailed ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (_, i) => i == state.items.length
                          ? RedemptionsListFooter(failed: state.loadMoreFailed, onRetry: retryLoadMore)
                          : RedemptionTile(redemption: state.items[i], onCopy: copyCode, onOpen: openLink),
                    ),
            ),
    );
  }
}
