import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/widgets/circle_icon_button.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/locked_feature_button.dart';
import 'package:qulo_v2/core/widgets/safe_tap_button.dart';
import 'package:qulo_v2/data/models/discover_model.dart';
import 'package:qulo_v2/features/diamonds/widgets/paywall_bottom_sheet.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/daily_stats_provider.dart';
import 'package:qulo_v2/providers/match_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/features/discover/widgets/profile_card.dart';

class DiscoverCardView extends ConsumerStatefulWidget {
  final ProfileCardModel card;
  final VoidCallback onSwipeRight;
  final VoidCallback onSwipeLeft;

  const DiscoverCardView({
    super.key,
    required this.card,
    required this.onSwipeRight,
    required this.onSwipeLeft,
  });

  @override
  ConsumerState<DiscoverCardView> createState() => _DiscoverCardViewState();
}

class _DiscoverCardViewState extends ConsumerState<DiscoverCardView> {
  double _dragOffset = 0;
  bool _isDragging = false;

  static const _swipeThreshold = 100.0;

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dx;
      _isDragging = true;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragOffset > _swipeThreshold) {
      ref.read(hapticManagerProvider).medium();
      _navigateToQuiz();
    } else if (_dragOffset < -_swipeThreshold) {
      ref.read(hapticManagerProvider).light();
      widget.onSwipeLeft();
      ref.read(discoverProvider.notifier).rejectCard(widget.card.userId);
    }
    setState(() {
      _dragOffset = 0;
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final discoverState = ref.watch(discoverProvider).valueOrNull;
    final canUndo = discoverState?.canUndo ?? false;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              child: AnimatedContainer(
                duration: _isDragging ? Duration.zero : const Duration(milliseconds: 200),
                transform: Matrix4.identity()
                  ..translateByDouble(_dragOffset * 0.3, 0, 0, 0)
                  ..rotateZ(_dragOffset * 0.0005),
                transformAlignment: Alignment.center,
                child: Stack(
                  children: [
                    ProfileCard(card: widget.card),
                    if (_dragOffset.abs() > 30)
                      Positioned(
                        top: AppSpacing.xl,
                        left: _dragOffset > 0 ? AppSpacing.xl : null,
                        right: _dragOffset < 0 ? AppSpacing.xl : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: _dragOffset > 0
                                ? AppColors.secondary.withValues(alpha: 0.9)
                                : AppColors.error.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            _dragOffset > 0
                                ? context.tr('solve_questions')
                                : context.tr('reject'),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SafeTapButton(
            onTap: _navigateToQuiz,
            builder: (context, isLoading, onTap) => DiscoverSolveButton(
              label: context.tr('solve_questions'),
              onTap: onTap,
              isLoading: isLoading,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DiscoverActionButtons(
            canUndo: canUndo,
            onUndo: _handleUndo,
            onReject: () {
              ref.read(hapticManagerProvider).light();
              widget.onSwipeLeft();
              ref.read(discoverProvider.notifier).rejectCard(widget.card.userId);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Future<void> _navigateToQuiz() async {
    ref.read(hapticManagerProvider).medium();
    widget.onSwipeRight();
    final result = await ref.read(discoverProvider.notifier).swipe(
      targetId: widget.card.userId,
      action: 'LIKE',
    );
    result.when(
      success: (_) {
        ref.read(navigationServiceProvider).push(
          RouteNames.quiz,
          params: {'targetId': widget.card.userId},
          extra: widget.card.photos?.isNotEmpty == true ? widget.card.photos!.first : null,
        );
      },
      failure: (f) {
        if (f is ServerFailure && f.code == 'DAILY_LIMIT_REACHED') {
          PaywallBottomSheetContent.show(ref, trigger: 'swipe_limit');
        }
      },
    );
  }

  Future<void> _handleUndo() async {
    final result = await ref.read(discoverProvider.notifier).undoSwipe();
    result.when(
      success: (_) {
        ref.invalidate(dailyStatsProvider);
      },
      failure: (f) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('undo_limit_reached'))),
          );
        }
      },
    );
  }
}

class DiscoverSolveButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const DiscoverSolveButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        gradient: AppColors.primaryButtonGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(
              child: isLoading
                  ? AppLoadingWidget.small()
                  : Text(
                      label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class DiscoverActionButtons extends ConsumerWidget {
  final VoidCallback onReject;
  final Future<void> Function() onUndo;
  final bool canUndo;

  const DiscoverActionButtons({
    super.key,
    required this.onReject,
    required this.onUndo,
    required this.canUndo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyStats = ref.watch(dailyStatsProvider).valueOrNull;
    final undosUsed = dailyStats?.dailyUndosUsed ?? 0;
    final undosLimit = dailyStats?.dailyUndosLimit ?? 0;
    final isUnlimited = dailyStats?.isUndoUnlimited ?? false;
    final hasUndoRight = isUnlimited || undosLimit > 0;
    final undosRemaining = isUnlimited ? -1 : (undosLimit - undosUsed).clamp(0, undosLimit);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LockedFeatureButton(
              isLocked: !hasUndoRight,
              trigger: 'undo_locked',
              child: SafeTapButton(
                onTap: canUndo ? onUndo : null,
                builder: (context, isLoading, safeTap) => CircleIconButton(
                  iconPath: QIcons.icArrowLeft,
                  iconColor: canUndo && !isLoading ? AppColors.warning : AppColors.textHint,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  borderColor: canUndo && !isLoading
                      ? AppColors.warning
                      : AppColors.textHint.withValues(alpha: 0.3),
                  size: 44,
                  onTap: safeTap ?? () {},
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hasUndoRight
                  ? (isUnlimited ? '∞' : '$undosRemaining')
                  : context.tr('undo'),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: hasUndoRight
                    ? (canUndo ? AppColors.warning : AppColors.textHint)
                    : AppColors.textHint,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(width: AppSpacing.xl),
        CircleIconButton(
          iconPath: QIcons.icX,
          iconColor: AppColors.error,
          backgroundColor: Theme.of(context).colorScheme.surface,
          borderColor: AppColors.error,
          onTap: onReject,
        ),
      ],
    );
  }
}
