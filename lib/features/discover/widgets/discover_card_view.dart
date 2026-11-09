import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/coach_mark/coach_mark_anchor.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/safe_tap_button.dart';
import 'package:qulo_v2/data/models/discover_model.dart';
import 'package:qulo_v2/features/discover/mixins/discover_card_view_mixin.dart';
import 'package:qulo_v2/features/discover/widgets/discover_action_buttons.dart';
import 'package:qulo_v2/features/discover/widgets/discover_solve_button.dart';
import 'package:qulo_v2/features/discover/widgets/discover_swipe_label.dart';
import 'package:qulo_v2/features/discover/widgets/profile_card.dart';
import 'package:qulo_v2/providers/match_provider.dart';

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
    with SingleTickerProviderStateMixin, DiscoverCardViewMixin {
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
    final discoverState = ref.watch(discoverProvider).valueOrNull;
    final canUndo = discoverState?.canUndo ?? false;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        children: [
          Expanded(
            child: isWaitingForApi
                ? Center(child: AppLoadingWidget.large())
                : GestureDetector(
                    onHorizontalDragUpdate: onHorizontalDragUpdate,
                    onHorizontalDragEnd: onHorizontalDragEnd,
                    child: AnimatedBuilder(
                      animation: flyAwayCtrl,
                      builder: (context, child) => Transform(
                        transform: cardTransform(),
                        alignment: Alignment.center,
                        child: child,
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ProfileCard(
                            key: ValueKey(widget.card.userId),
                            card: widget.card,
                            onInfoTap: isProcessing ? null : navigateToProfile,
                            isInteractionEnabled: !isProcessing,
                          ),
                          if (dragOffset.abs() > 30) DiscoverSwipeLabel(dragOffset: dragOffset),
                        ],
                      ),
                    ),
                  ),
          ),
          CoachMarkAnchor(
            anchorId: 'discover_solve',
            child: SafeTapButton(
              onTap: isProcessing ? null : navigateToQuiz,
              builder: (context, isLoading, onTap) => DiscoverSolveButton(
                label: context.tr('solve_questions'),
                onTap: onTap,
                isLoading: isLoading || isProcessing,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          CoachMarkAnchor(
            anchorId: 'discover_actions',
            child: DiscoverActionButtons(
              canUndo: canUndo,
              onUndo: handleUndo,
              onReject: rejectByButton,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
