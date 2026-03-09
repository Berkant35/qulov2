import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/location_provider.dart';
import 'package:qulo_v2/providers/match_provider.dart';
import 'package:qulo_v2/providers/passport_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/features/discover/widgets/discover_empty_state.dart';
import 'package:qulo_v2/features/discover/widgets/profile_card.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  int _nudgeCount = 0;
  bool _nudgeLoaded = false;

  // ─── Analytics session tracking ───
  final Stopwatch _sessionStopwatch = Stopwatch()..start();
  int _swipesRight = 0;
  int _swipesLeft = 0;
  final int _profilesViewed = 0;

  @override
  void initState() {
    super.initState();
    AnalyticsManager.instance.logEvent(AnalyticsEvents.discoverSessionStart);
    Future.microtask(() => _initLocationAndDiscover());
    _loadAndIncrementNudge();
  }

  Future<void> _initLocationAndDiscover() async {
    final locationState = ref.read(locationProvider);
    if (locationState.lat == null) {
      await ref.read(locationProvider.notifier).getCurrentLocation();
    }
    ref.read(discoverProvider.notifier).loadCards();
  }

  Future<void> _loadAndIncrementNudge() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt('question_nudge_count') ?? 0;
    final newCount = count + 1;
    await prefs.setInt('question_nudge_count', newCount);
    if (mounted) {
      setState(() {
        _nudgeCount = newCount;
        _nudgeLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _sessionStopwatch.stop();
    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.discoverSessionEnd,
      params: {
        AnalyticsEvents.paramDurationMs: _sessionStopwatch.elapsedMilliseconds,
        AnalyticsEvents.paramSwipesRight: _swipesRight,
        AnalyticsEvents.paramSwipesLeft: _swipesLeft,
        AnalyticsEvents.paramProfilesViewed: _profilesViewed,
      },
    );
    super.dispose();
  }

  void _showEasyModeSheet() {
    final theme = Theme.of(context);
    final categories = [
      'personality',
      'music',
      'film',
      'sports',
      'travel',
      'food',
      'technology',
      'general',
    ];

    ref.read(navigationServiceProvider).showAppBottomSheet(
      CustomBottomSheet(
        name: 'easy_mode_nudge',
        maxHeightFactor: 0.5,
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                context.tr('nudge_quick_create_title'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: categories.map((cat) {
                  return ActionChip(
                    label: Text(context.tr('question_category_$cat')),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      ref.read(navigationServiceProvider).push(
                        RouteNames.questionEasyMode,
                      );
                    },
                    backgroundColor: AppColors.primarySurface,
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ref.read(navigationServiceProvider).push(
                      RouteNames.questionEasyMode,
                    );
                  },
                  icon: QIcon(QIcons.icWand, size: 18, color: AppColors.primary),
                  label: Text(context.tr('nudge_profile_suggest')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoverProvider);
    final theme = Theme.of(context);

    return AppScaffold(
      title: context.tr('discover'),
      padding: EdgeInsets.zero,
      isLoading: state is AsyncLoading,
      actions: [
        if (ref.watch(passportProvider).isActive)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flight, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    ref.watch(passportProvider).city ?? '',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
      body: state.when(
        loading: () => const SizedBox.shrink(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (discover) {
          // ─── Location Permission Check ───
          final locationState = ref.watch(locationProvider);
          if (locationState.error == 'LOCATION_PERMISSION_DENIED' ||
              locationState.error == 'LOCATION_PERMISSION_DENIED_FOREVER' ||
              locationState.error == 'LOCATION_SERVICE_DISABLED') {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_off, size: 64, color: AppColors.textHint),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      context.tr('location_required'),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      context.tr('location_required_desc'),
                      style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: () async {
                          final manager = ref.read(locationManagerProvider);
                          if (locationState.error == 'LOCATION_SERVICE_DISABLED') {
                            await manager.openLocationSettings();
                          } else {
                            await manager.openAppSettings();
                          }
                        },
                        style: FilledButton.styleFrom(backgroundColor: AppColors.primaryDark),
                        child: Text(context.tr('enable_location')),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ─── Question Gate: Blur Lock ───
          final user = ref.watch(userProvider).valueOrNull;
          final hasMinQuestions = (user?.questionCount ?? 0) >= AppConstants.minQuestions;

          if (!hasMinQuestions) {
            // Auto-show easy mode sheet on 3rd+ visit
            if (_nudgeLoaded && _nudgeCount >= 3) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !hasMinQuestions) {
                  _showEasyModeSheet();
                }
              });
              // Reset so it doesn't fire on every rebuild
              _nudgeLoaded = false;
            }

            final firstCard = discover.cards.isNotEmpty ? discover.cards.first : null;
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Stack(
                children: [
                  // Blurred card or placeholder
                  if (firstCard != null)
                    Positioned.fill(
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: ProfileCard(card: firstCard),
                      ),
                    )
                  else
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                    ),
                  // Lock overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withAlpha(180),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          QIcon(QIcons.icLock, size: 64, color: AppColors.primary),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            context.tr('question_nudge_discover_locked'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // Progress bar
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 48),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                  child: LinearProgressIndicator(
                                    value: ((user?.questionCount ?? 0) / 2).clamp(0.0, 1.0),
                                    minHeight: 10,
                                    backgroundColor: theme.colorScheme.surfaceContainerHigh,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  context.tr('question_nudge_progress')
                                      .replaceAll('{count}', '${user?.questionCount ?? 0}'),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // ─── Progressive Nudge: Easy Mode hint on 2nd visit ───
                          if (_nudgeCount >= 2) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySurface,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    QIcon(QIcons.icWand, size: 20, color: AppColors.primary),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        context.tr('nudge_easy_mode_hint'),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            FilledButton.icon(
                              onPressed: () => ref.read(navigationServiceProvider).push(
                                RouteNames.questionEasyMode,
                              ),
                              icon: QIcon(QIcons.icWand, color: theme.colorScheme.onPrimary, size: 18),
                              label: Text(context.tr('nudge_easy_mode_button')),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextButton.icon(
                              onPressed: () => ref.read(navigationServiceProvider).go(RouteNames.questions),
                              icon: QIcon(QIcons.icPlus, color: theme.colorScheme.onSurfaceVariant, size: 16),
                              label: Text(
                                context.tr('question_nudge_add_button'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ] else ...[
                            FilledButton.icon(
                              onPressed: () => ref.read(navigationServiceProvider).go(RouteNames.questions),
                              icon: QIcon(QIcons.icPlus, color: theme.colorScheme.onPrimary, size: 18),
                              label: Text(context.tr('question_nudge_add_button')),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (discover.cards.isEmpty) {
            AnalyticsManager.instance.logEvent(AnalyticsEvents.discoverCardsEmpty);
            return const DiscoverEmptyState();
          }
          final card = discover.cards.first;
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: Column(
              children: [
                Expanded(child: ProfileCard(card: card)),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryButtonGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        _swipesRight++;
                        AnalyticsManager.instance.logEvent(
                          AnalyticsEvents.discoverSwipeRight,
                          params: {
                            AnalyticsEvents.paramTargetUserId: card.userId,
                            AnalyticsEvents.paramSource: 'solve_button',
                          },
                        );
                        ref.read(navigationServiceProvider).go(RouteNames.quiz, params: {'targetId': card.userId});
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: Text(
                            context.tr('solve_questions'),
                            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ActionButton(
                      iconPath: QIcons.icX,
                      iconColor: AppColors.error,
                      backgroundColor: theme.colorScheme.surface,
                      borderColor: AppColors.error,
                      onTap: () async {
                        _swipesLeft++;
                        AnalyticsManager.instance.logEvent(
                          AnalyticsEvents.discoverSwipeLeft,
                          params: {
                            AnalyticsEvents.paramTargetUserId: card.userId,
                          },
                        );
                        await ref.read(discoverProvider.notifier).swipe(
                          targetId: card.userId,
                          action: 'REJECT',
                        );
                      },
                    ),
                    _ActionButton(
                      iconPath: QIcons.icHeart,
                      iconColor: AppColors.secondary,
                      backgroundColor: theme.colorScheme.surface,
                      borderColor: AppColors.secondary,
                      size: 72,
                      onTap: () {
                        _swipesRight++;
                        AnalyticsManager.instance.logEvent(
                          AnalyticsEvents.discoverSwipeRight,
                          params: {
                            AnalyticsEvents.paramTargetUserId: card.userId,
                          },
                        );
                        ref.read(navigationServiceProvider).go(RouteNames.quiz, params: {'targetId': card.userId});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String iconPath;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final double size;
  final VoidCallback onTap;

  const _ActionButton({
    required this.iconPath,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    this.size = 56,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [BoxShadow(color: borderColor.withValues(alpha: 0.2), blurRadius: 8)],
        ),
        child: Center(child: QIcon(iconPath, color: iconColor, size: size * 0.5)),
      ),
    );
  }
}
