import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/widgets/error_retry_widget.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/core/widgets/question_gate_banner.dart';
import 'package:qulo_v2/providers/notification_provider.dart';
import 'package:qulo_v2/providers/subscription_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/features/profile/widgets/photo_grid.dart';
import 'package:qulo_v2/features/profile/widgets/badge_bar.dart';
import 'package:qulo_v2/features/profile/widgets/detail_chips.dart';
import 'package:qulo_v2/features/profile/widgets/question_vitrin_card.dart';
import 'package:qulo_v2/features/profile/widgets/section_card.dart';
import 'package:qulo_v2/features/profile/widgets/pref_chip.dart';
import 'package:qulo_v2/features/profile/widgets/profile_completion_bar.dart';
import 'package:qulo_v2/features/profile/widgets/profile_menu_item.dart';
import 'package:qulo_v2/core/widgets/referral_invite_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(userProvider.notifier).fetchMe();
    });
    AnalyticsManager.instance.logEvent(AnalyticsEvents.profileViewOwn);
  }

  String _genderPrefLabel(BuildContext context, String? pref) {
    switch (pref) {
      case 'MAN':
        return context.tr('men');
      case 'WOMAN':
        return context.tr('women');
      case 'BOTH':
        return context.tr('both');
      default:
        return '';
    }
  }

  String _relationshipGoalLabel(BuildContext context, String? goal) {
    return switch (goal) {
      'SERIOUS' => context.tr('serious_relationship'),
      'FRIENDSHIP' => context.tr('friendship'),
      _ => context.tr('not_sure'),
    };
  }

  String _languageFlag(String code) {
    return switch (code) {
      'tr' => 'TR',
      'en' => 'EN',
      'de' => 'DE',
      'fr' => 'FR',
      'ar' => 'AR',
      'ru' => 'RU',
      'es' => 'ES',
      _ => code.toUpperCase(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final unreadCount = ref.watch(notificationProvider.select((s) => s.unreadCount));
    final theme = Theme.of(context);

    return AppScaffold(
      title: context.tr('profile'),
      isLoading: userAsync is AsyncLoading,
      actions: [
        Stack(
          children: [
            IconButton(
              icon: QIcon(QIcons.icBell, color: theme.colorScheme.onSurfaceVariant, size: 24),
              onPressed: () => ref.read(navigationServiceProvider).go(RouteNames.notifications),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        IconButton(
          icon: QIcon(QIcons.icSettings, color: theme.colorScheme.onSurfaceVariant, size: 24),
          onPressed: () {
            AnalyticsManager.instance.logEvent(AnalyticsEvents.profileSettingsOpen);
            ref.read(navigationServiceProvider).go(RouteNames.settings);
          },
        ),
      ],
      padding: EdgeInsets.zero,
      body: userAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (e, _) => ErrorRetryWidget(
          onRetry: () => ref.invalidate(userProvider),
        ),
        data: (user) {
          if (user == null) return const Center(child: Text('No user data'));
          final photos = user.photos ?? [];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: Column(
              children: [
                // ─── Photo Grid ───
                PhotoGridFull(
                  photos: photos.map<String?>((e) => e).toList(),
                  onSlotTap: (_) => ref.read(navigationServiceProvider).go(RouteNames.editProfile),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ─── Question Gate Banner / Vitrin ───
                if (user.questionCount < AppConstants.minQuestions) ...[
                  QuestionGateBanner(
                    questionCount: user.questionCount,
                    profileCompletion: user.profileCompletion,
                    onAddQuestions: () => ref.read(navigationServiceProvider).go(RouteNames.questions),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ] else ...[
                  const QuestionVitrinCard(),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // ─── Name, Age ───
                Text(
                  '${user.name ?? ''}, ${user.age ?? ''}',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                // ─── Subscription Badge ───
                Builder(builder: (context) {
                  final subAsync = ref.watch(subscriptionProvider);
                  final sub = subAsync.valueOrNull;
                  if (sub == null || sub.isFree) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.purpleGradient,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        sub.isPremium ? 'Premium' : 'Plus',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.md),

                // ─── Referral Invite (Compact) ───
                ReferralInviteCard(
                  compact: true,
                  onTap: () => ref.read(navigationServiceProvider).go(RouteNames.diamonds),
                ),

                if (user.city != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      QIcon(QIcons.icMapPin, color: theme.colorScheme.onSurfaceVariant, size: 16),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        user.city!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.md),

                // ─── Profile Completion ───
                ProfileCompletionBar(
                  completionPercent: user.profileCompletion,
                  onTap: () => ref.read(navigationServiceProvider).go(RouteNames.editProfile),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ─── Badge Bar ───
                BadgeBar(
                  user: user,
                  onClaimReward: (level) async {
                    final result = await ref.read(userProvider.notifier).claimBadgeReward(level);
                    result.when(
                      success: (data) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.tr('badge_reward_claimed'))),
                        );
                      },
                      failure: (_) {},
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // ─── About Me Card ───
                SectionCard(
                  title: context.tr('about_me'),
                  onTap: () => ref.read(navigationServiceProvider).go(RouteNames.editProfile),
                  child: Text(
                    user.bio != null && user.bio!.isNotEmpty
                        ? user.bio!
                        : context.tr('hint_add_bio'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: user.bio != null && user.bio!.isNotEmpty
                          ? null
                          : theme.hintColor,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // ─── Details Card ───
                SectionCard(
                  title: context.tr('details'),
                  onTap: () => ref.read(navigationServiceProvider).go(RouteNames.editProfile),
                  child: DetailChips(
                    user: user,
                    onTap: () => ref.read(navigationServiceProvider).go(RouteNames.editProfile),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // ─── Preferences Card ───
                SectionCard(
                  title: context.tr('preferences'),
                  onTap: () => ref.read(navigationServiceProvider).go(RouteNames.editProfile),
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      if (user.genderPref != null)
                        PrefChip(
                          iconPath: QIcons.icGenderPref,
                          label: _genderPrefLabel(context, user.genderPref),
                        ),
                      if (user.agePrefMin != null && user.agePrefMax != null)
                        PrefChip(
                          iconPath: QIcons.icAgeRange,
                          label: '${user.agePrefMin} - ${user.agePrefMax}',
                        ),
                      PrefChip(
                          iconPath: QIcons.icMapPin,
                          label: '${user.matchRadiusKm} km',
                        ),
                      if (user.relationshipGoal != null && user.relationshipGoal != 'NOT_SURE')
                        PrefChip(
                          iconPath: QIcons.icHeart,
                          label: _relationshipGoalLabel(context, user.relationshipGoal),
                        ),
                      if (user.preferredLanguages.isNotEmpty)
                        PrefChip(
                          iconPath: QIcons.icGlobe,
                          label: user.preferredLanguages.map(_languageFlag).join(', '),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ─── Menu Items ───
                ProfileMenuItem(
                  iconPath: QIcons.icPencil,
                  title: context.tr('edit_profile'),
                  onTap: () => ref.read(navigationServiceProvider).go(RouteNames.editProfile),
                ),
                ProfileMenuItem(
                  iconPath: QIcons.icHelpCircle,
                  title: context.tr('my_questions'),
                  subtitle: user.questionCount < AppConstants.minQuestions
                      ? context.tr('question_nudge_menu_required')
                      : null,
                  showBadge: user.questionCount < AppConstants.minQuestions,
                  onTap: () => ref.read(navigationServiceProvider).go(RouteNames.questions),
                ),
                ProfileMenuItem(
                  iconWidget: const DiamondIcon.purple(size: 24),
                  title: context.tr('diamonds'),
                  onTap: () => ref.read(navigationServiceProvider).go(RouteNames.diamonds),
                ),
                ProfileMenuItem(
                  iconPath: QIcons.icCrown,
                  title: context.tr('sub_my_subscription'),
                  subtitle: (() {
                    final sub = ref.watch(subscriptionProvider).valueOrNull;
                    if (sub == null || sub.isFree) return context.tr('sub_free_upgrade');
                    final planLabel = sub.isPremium ? 'Premium' : 'Plus';
                    if (sub.expiresAt != null) {
                      final date = DateTime.tryParse(sub.expiresAt!);
                      if (date != null) {
                        final formatted = '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
                        return '$planLabel • $formatted';
                      }
                    }
                    return planLabel;
                  })(),
                  onTap: () => ref.read(navigationServiceProvider).go(RouteNames.subscription),
                ),
                ProfileMenuItem(
                  iconPath: QIcons.icPlane,
                  title: context.tr('passport'),
                  onTap: () => ref.read(navigationServiceProvider).go(RouteNames.passport),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
