import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/empty_state_view.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/features/discover/mixins/discover_empty_state_mixin.dart';
import 'package:qulo_v2/features/discover/widgets/discover_passport_hint.dart';

class DiscoverEmptyState extends ConsumerStatefulWidget {
  const DiscoverEmptyState({super.key});

  @override
  ConsumerState<DiscoverEmptyState> createState() => _DiscoverEmptyStateState();
}

class _DiscoverEmptyStateState extends ConsumerState<DiscoverEmptyState>
    with DiscoverEmptyStateMixin<DiscoverEmptyState> {
  late double _radius;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _radius = initialRadiusKm();
  }

  Future<void> _updateRadiusAndSearch() async {
    setState(() => _isSearching = true);
    await applyRadiusAndSearch(_radius);
    if (mounted) setState(() => _isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = context.fmt.radiusScale;

    return EmptyStateView(
      icon: QIcon(QIcons.icCompassOff, size: 64, color: context.appColors.textHint),
      title: context.tr('no_more_profiles'),
      message: context.tr('no_more_profiles_hint'),
      children: [
            // Inline radius slider
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: context.appColors.surfaceElevated,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: context.appColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('match_radius'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        scale.label(scale.fromKm(_radius)),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: context.appColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: scale.fromKm(_radius),
                    min: scale.min,
                    max: scale.max,
                    divisions: scale.divisions,
                    activeColor: context.appColors.primary,
                    onChanged: (val) => setState(() => _radius = scale.toKm(val)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        scale.label(scale.min),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: context.appColors.textHint,
                        ),
                      ),
                      Text(
                        scale.label(scale.max),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: context.appColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _isSearching ? null : _updateRadiusAndSearch,
                      style: FilledButton.styleFrom(
                        backgroundColor: context.appColors.primaryDark,
                      ),
                      child: _isSearching
                          ? const AppLoadingWidget.small()
                          : Text(context.tr('search_again')),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            const DiscoverPassportHint(),
      ],
    );
  }
}
