import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/features/profile/widgets/section_card.dart';
import 'package:qulo_v2/features/quiz/widgets/power_purchase_sheet.dart';
import 'package:qulo_v2/providers/exchange_provider.dart';

/// Profilde gösterilen 6 güç envanteri grid'i.
/// Tıklama → PowerPurchaseSheet açar.
class PowerInventoryGrid extends ConsumerWidget {
  const PowerInventoryGrid({super.key});

  /// Aktif güç tipleri (powerBlock/powerUnblock hariç).
  static const _activePowers = [
    PowerType.oracle,
    PowerType.half,
    PowerType.skip,
    PowerType.skipAll,
    PowerType.timeExtend,
    PowerType.hint,
  ];

  // Not: showModalBottomSheet direkt kullanıyoruz — power_bar.dart ile tutarlı.
  // PowerPurchaseSheet kendi state'ini yönetiyor, NavigationService wrapper gereksiz.
  void _openPurchaseSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (_) => const PowerPurchaseSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exchange = ref.watch(exchangeProvider);

    // Henüz hiç yüklenmediyse ve loading de değilse gösterme
    if (exchange.rates == null && !exchange.isLoading) {
      return const SizedBox.shrink();
    }

    // İlk yükleme sırasında loading göster
    final isFirstLoad = exchange.isLoading && exchange.rates == null;

    return SectionCard(
      title: context.tr('my_powers'),
      onTap: () => _openPurchaseSheet(context),
      child: isFirstLoad
          ? const Center(child: AppLoadingWidget.small())
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _activePowers.map((type) {
                final count = exchange.getCount(type.apiName);
                return _PowerGridItem(
                  type: type,
                  count: count,
                  onTap: () => _openPurchaseSheet(context),
                );
              }).toList(),
            ),
    );
  }
}

class _PowerGridItem extends StatelessWidget {
  final PowerType type;
  final int count;
  final VoidCallback onTap;

  const _PowerGridItem({
    required this.type,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = count == 0;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isEmpty ? 0.35 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PowerIcon(
              type: type,
              size: 28,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '×$count',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isEmpty
                    ? theme.colorScheme.onSurfaceVariant
                    : type.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
