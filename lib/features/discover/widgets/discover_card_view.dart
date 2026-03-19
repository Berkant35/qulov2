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
import 'package:qulo_v2/features/profile_detail/models/profile_detail_args.dart';

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

class _DiscoverCardViewState extends ConsumerState<DiscoverCardView>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  bool _isProcessing = false;
  _SwipeDirection? _swipeDirection;

  late final AnimationController _flyAwayCtrl;
  late final CurveTween _curveTween;
  Animation<double> _flyAwayAnimation = const AlwaysStoppedAnimation(0);

  static const _swipeThreshold = 100.0;

  @override
  void initState() {
    super.initState();
    _flyAwayCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _curveTween = CurveTween(curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _flyAwayCtrl.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isProcessing) return;
    setState(() => _dragOffset += details.delta.dx);
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_isProcessing) return;
    final haptic = ref.read(hapticManagerProvider);
    if (_dragOffset > _swipeThreshold) {
      haptic.medium();
      _animateAndNavigateQuiz();
    } else if (_dragOffset < -_swipeThreshold) {
      haptic.light();
      _animateAndReject();
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  void _animateAndReject() {
    setState(() {
      _isProcessing = true;
      _swipeDirection = _SwipeDirection.left;
    });
    final screenWidth = MediaQuery.of(context).size.width;
    _flyAwayAnimation = Tween<double>(begin: _dragOffset, end: -screenWidth)
        .chain(_curveTween)
        .animate(_flyAwayCtrl);
    _flyAwayCtrl.forward(from: 0).then((_) {
      widget.onSwipeLeft();
      ref.read(discoverProvider.notifier).rejectCard(widget.card.userId);
      _resetState();
    });
  }

  void _animateAndNavigateQuiz() {
    setState(() {
      _isProcessing = true;
      _swipeDirection = _SwipeDirection.right;
    });
    final screenWidth = MediaQuery.of(context).size.width;
    _flyAwayAnimation = Tween<double>(begin: _dragOffset, end: screenWidth)
        .chain(_curveTween)
        .animate(_flyAwayCtrl);
    _flyAwayCtrl.forward(from: 0).then((_) {
      _navigateToQuiz();
    });
  }

  bool get _isWaitingForApi =>
      _isProcessing && !_flyAwayCtrl.isAnimating && _swipeDirection == _SwipeDirection.right;

  void _resetState() {
    if (!mounted) return;
    _flyAwayCtrl.reset();
    setState(() {
      _dragOffset = 0;
      _isProcessing = false;
      _swipeDirection = null;
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
            child: _isWaitingForApi
                ? Center(child: AppLoadingWidget.large())
                : GestureDetector(
                    onHorizontalDragUpdate: _onHorizontalDragUpdate,
                    onHorizontalDragEnd: _onHorizontalDragEnd,
                    child: AnimatedBuilder(
                      animation: _flyAwayCtrl,
                      builder: (context, child) {
                        final offset = _flyAwayCtrl.isAnimating
                            ? _flyAwayAnimation.value
                            : _dragOffset * 0.3;
                        final rotation = _flyAwayCtrl.isAnimating
                            ? _flyAwayAnimation.value * 0.001
                            : _dragOffset * 0.0005;
                        return Transform(
                          transform: Matrix4.identity()
                            ..translate(offset, 0.0, 0.0)
                            ..rotateZ(rotation),
                          alignment: Alignment.center,
                          child: child,
                        );
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ProfileCard(
                            key: ValueKey(widget.card.userId),
                            card: widget.card,
                            onInfoTap: _isProcessing ? null : _navigateToProfile,
                            isInteractionEnabled: !_isProcessing,
                          ),
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
            onTap: _isProcessing ? null : _navigateToQuiz,
            builder: (context, isLoading, onTap) => DiscoverSolveButton(
              label: context.tr('solve_questions'),
              onTap: onTap,
              isLoading: isLoading || _isProcessing,
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

  void _navigateToProfile() {
    ref.read(navigationServiceProvider).push(
      RouteNames.profileDetail,
      params: {'userId': widget.card.userId},
      extra: ProfileDetailArgs(
        context: ProfileDetailContext.discover,
        userId: widget.card.userId,
        preloadedCard: widget.card,
      ),
    );
  }

  Future<void> _navigateToQuiz() async {
    if (!_isProcessing) {
      // Button tap — no fly-away needed, just set processing
      setState(() => _isProcessing = true);
    }
    widget.onSwipeRight();
    final result = await ref.read(discoverProvider.notifier).swipe(
      targetId: widget.card.userId,
      action: 'LIKE',
    );
    result.when(
      success: (_) {
        if (!mounted) return;
        ref.read(navigationServiceProvider).push(
          RouteNames.quiz,
          params: {'targetId': widget.card.userId},
          extra: widget.card.photos?.isNotEmpty == true ? widget.card.photos!.first : null,
        );
        _resetState();
      },
      failure: (f) {
        _resetState();
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

enum _SwipeDirection { left, right }
