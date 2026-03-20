import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/power_icon.dart';
import 'package:qulo_v2/features/profile/widgets/section_card.dart';
import 'package:qulo_v2/features/quiz/widgets/power_purchase_sheet.dart';
import 'package:qulo_v2/providers/exchange_provider.dart';

/// Profilde gösterilen 6 güç envanteri grid'i.
/// Tıklama → PowerPurchaseSheet açar.
/// Expand → her gücün açıklamasını gösterir.
class PowerInventoryGrid extends ConsumerStatefulWidget {
  const PowerInventoryGrid({super.key});

  @override
  ConsumerState<PowerInventoryGrid> createState() => _PowerInventoryGridState();
}

class _PowerInventoryGridState extends ConsumerState<PowerInventoryGrid> {
  bool _expanded = false;

  /// Aktif güç tipleri (powerBlock/powerUnblock hariç).
  static const _activePowers = [
    PowerType.oracle,
    PowerType.half,
    PowerType.skip,
    PowerType.skipAll,
    PowerType.timeExtend,
    PowerType.hint,
  ];

  static const _powerNameKeys = {
    PowerType.oracle: 'power_oracle',
    PowerType.half: 'power_half',
    PowerType.skip: 'power_skip',
    PowerType.skipAll: 'power_skip_all',
    PowerType.timeExtend: 'power_time',
    PowerType.hint: 'power_hint',
  };

  static const _powerDescKeys = {
    PowerType.oracle: 'power_oracle_desc',
    PowerType.half: 'power_half_desc',
    PowerType.skip: 'power_skip_desc',
    PowerType.skipAll: 'power_skip_all_desc',
    PowerType.timeExtend: 'power_time_extend_desc',
    PowerType.hint: 'power_hint_desc',
  };

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
  Widget build(BuildContext context) {
    final exchange = ref.watch(exchangeProvider);
    final theme = Theme.of(context);

    if (exchange.rates == null && !exchange.isLoading) {
      return const SizedBox.shrink();
    }

    final isFirstLoad = exchange.isLoading && exchange.rates == null;

    return SectionCard(
      title: context.tr('my_powers'),
      onTap: () => _openPurchaseSheet(context),
      child: isFirstLoad
          ? const Center(child: AppLoadingWidget.small())
          : Column(
              children: [
                // ─── Power Grid ───
                Row(
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

                // ─── Expand/Collapse Toggle ───
                const SizedBox(height: AppSpacing.sm),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _expanded
                            ? context.tr('hide_info')
                            : context.tr('what_are_powers'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── Expanded Info ───
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Column(
                      children: _activePowers.map((type) {
                        final count = exchange.getCount(type.apiName);
                        return _PowerInfoRow(
                          type: type,
                          name: context.tr(_powerNameKeys[type]!),
                          description: context.tr(_powerDescKeys[type]!),
                          count: count,
                        );
                      }).toList(),
                    ),
                  ),
                  crossFadeState: _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                ),
              ],
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

class _PowerInfoRow extends StatelessWidget {
  final PowerType type;
  final String name;
  final String description;
  final int count;

  const _PowerInfoRow({
    required this.type,
    required this.name,
    required this.description,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = count == 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Opacity(
            opacity: isEmpty ? 0.35 : 1.0,
            child: PowerIcon(type: type, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isEmpty
                        ? theme.colorScheme.onSurfaceVariant
                        : type.color,
                  ),
                ),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
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
    );
  }
}
