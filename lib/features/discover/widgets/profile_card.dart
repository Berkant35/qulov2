import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/data/models/discover_model.dart';
import 'package:qulo_v2/features/questions/widgets/difficulty_badge.dart';

class ProfileCard extends StatefulWidget {
  final ProfileCardModel card;
  final VoidCallback? onInfoTap;
  final bool isInteractionEnabled;

  const ProfileCard({
    super.key,
    required this.card,
    this.onInfoTap,
    this.isInteractionEnabled = true,
  });

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  final PageController _controller = PageController();
  int _current = 0;
  Offset? _pointerDownPosition;

  List<String> get _photos => widget.card.photos ?? [];
  bool get _hasMultiplePhotos => _photos.length > 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    if (page < 0 || page >= _photos.length) return;
    if (!_controller.hasClients) return;
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _photoPlaceholder(ThemeData theme) => Container(
        color: theme.colorScheme.surface,
        child: Center(child: QIcon(QIcons.icUser, color: theme.hintColor, size: 80)),
      );

  String _relationshipGoalLabel(BuildContext context, String? goal) {
    return switch (goal) {
      'SERIOUS' => context.tr('serious_relationship'),
      'FRIENDSHIP' => context.tr('friendship'),
      _ => context.tr('not_sure'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Photo area
          if (_photos.isEmpty)
            _photoPlaceholder(theme)
          else
            PageView.builder(
              controller: _controller,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _photos.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (context, index) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final half = constraints.maxWidth / 2;
                    return Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: _hasMultiplePhotos && widget.isInteractionEnabled
                          ? (event) => _pointerDownPosition = event.localPosition
                          : null,
                      onPointerUp: _hasMultiplePhotos && widget.isInteractionEnabled
                          ? (event) {
                              final down = _pointerDownPosition;
                              _pointerDownPosition = null;
                              if (down == null) return;
                              final distance = (event.localPosition - down).distance;
                              if (distance > 20) return;
                              if (event.localPosition.dx > half) {
                                _goTo(_current + 1);
                              } else {
                                _goTo(_current - 1);
                              }
                            }
                          : null,
                      child: CachedNetworkImage(
                        imageUrl: _photos[index],
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _photoPlaceholder(theme),
                        errorWidget: (_, __, ___) => _photoPlaceholder(theme),
                      ),
                    );
                  },
                );
              },
            ),

          // Gradient overlay — IgnorePointer so it doesn't block photo taps
          IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                  stops: [0.5, 1.0],
                ),
              ),
            ),
          ),

          // Progress bar
          if (_hasMultiplePhotos)
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              child: Row(
                children: List.generate(_photos.length, (i) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: EdgeInsets.symmetric(
                        horizontal: _photos.length > 6 ? 1 : 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: i == _current
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  );
                }),
              ),
            ),

          // Info section
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: GestureDetector(
              onTap: widget.onInfoTap,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        '${widget.card.name ?? context.tr('unknown')}, ${widget.card.age ?? ''}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.card.isBoosted) ...[
                        const SizedBox(width: AppSpacing.sm),
                        QIcon(QIcons.icZap, color: context.appColors.warning, size: 20),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (widget.card.city != null)
                    Row(
                      children: [
                        QIcon(QIcons.icMapPin, color: Colors.white70, size: 16),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '${widget.card.city} • ${widget.card.distanceKm < 1.0 ? context.tr('nearby') : '${widget.card.distanceKm.toStringAsFixed(1)} km'}',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  if (widget.card.relationshipGoal != null && widget.card.relationshipGoal != 'NOT_SURE')
                    Container(
                      margin: const EdgeInsets.only(top: AppSpacing.xs),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.appColors.primarySurface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        _relationshipGoalLabel(context, widget.card.relationshipGoal),
                        style: theme.textTheme.labelSmall?.copyWith(color: context.appColors.primary),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  _QuestionInfoSection(card: widget.card),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionInfoSection extends StatelessWidget {
  final ProfileCardModel card;

  const _QuestionInfoSection({required this.card});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = card.questionInfo;

    // Fallback: just show question count chip if no question_info
    if (info == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: context.appColors.primarySurface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Text(
          context.tr('questions_count').replaceAll('{count}', '${card.questionCount}'),
          style: theme.textTheme.labelSmall?.copyWith(color: Colors.white),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Question count + difficulty badge row
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: context.appColors.primarySurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                context.tr('discover_questions_count').replaceAll('{count}', '${info.count}'),
                style: theme.textTheme.labelSmall?.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            DifficultyBadge(difficulty: info.avgDifficulty),
          ],
        ),
        // Category chips
        if (info.categories.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 26,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: info.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
              itemBuilder: (context, index) {
                final category = info.categories[index];
                return Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      context.tr('question_category_$category'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        // Language chips
        if (info.languages.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            children: info.languages.map((lang) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Text(
                '${AppConstants.localeFlagEmojis[lang] ?? ''} ${lang.toUpperCase()}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            )).toList(),
          ),
        ],
      ],
    );
  }
}
