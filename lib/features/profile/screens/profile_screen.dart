import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/error_retry_widget.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/core/widgets/question_gate_banner.dart';
import 'package:qulo_v2/core/widgets/referral_invite_card.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/providers/notification_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/features/profile/mixins/profile_screen_mixin.dart';
import 'package:qulo_v2/features/profile/widgets/detail_chips.dart';
import 'package:qulo_v2/features/profile/widgets/notification_bell_button.dart';
import 'package:qulo_v2/features/profile/widgets/photo_grid.dart';
import 'package:qulo_v2/features/profile/widgets/power_inventory_grid.dart';
import 'package:qulo_v2/features/profile/widgets/profile_identity_card.dart';
import 'package:qulo_v2/features/profile/widgets/profile_menu_list.dart';
import 'package:qulo_v2/features/profile/widgets/profile_preferences_section.dart';
import 'package:qulo_v2/features/profile/widgets/profile_progress_card.dart';
import 'package:qulo_v2/features/profile/widgets/question_vitrin_card.dart';
import 'package:qulo_v2/features/profile/widgets/section_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with ProfileScreenMixin {
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
    final userAsync = ref.watch(userProvider);
    final unreadCount =
        ref.watch(notificationProvider.select((s) => s.unreadCount));
    final theme = Theme.of(context);

    return AppScaffold(
      title: context.tr('profile'),
      isLoading: userAsync is AsyncLoading,
      actions: [
        NotificationBellButton(
          unreadCount: unreadCount,
          onTap: () => navigateTo(RouteNames.notifications),
        ),
        IconButton(
          icon: QIcon(QIcons.icSettings,
              color: theme.colorScheme.onSurfaceVariant, size: 24),
          onPressed: openSettings,
        ),
      ],
      padding: EdgeInsets.zero,
      body: userAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (e, _) =>
            ErrorRetryWidget(onRetry: () => ref.invalidate(userProvider)),
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
                  onSlotTap: (_) => navigateTo(RouteNames.editProfile),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ─── Question Gate / Vitrin ───
                if (user.questionCount < AppConstants.minQuestions) ...[
                  QuestionGateBanner(
                    questionCount: user.questionCount,
                    profileCompletion: user.profileCompletion,
                    onAddQuestions: () => navigateTo(RouteNames.questions),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ] else ...[
                  const QuestionVitrinCard(),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // ─── Identity ───
                ProfileIdentityCard(user: user),
                const SizedBox(height: AppSpacing.lg),

                // ─── Referral ───
                ReferralInviteCard(
                  compact: true,
                  onTap: () => navigateTo(RouteNames.diamonds),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ─── Progress ───
                ProfileProgressCard(
                  user: user,
                  onEditProfile: () => navigateTo(RouteNames.editProfile),
                  onNavigate: (route) {
                    switch (route) {
                      case 'editProfile':
                        navigateTo(RouteNames.editProfile);
                      case 'questions':
                        pushTo(RouteNames.questions);
                    }
                  },
                  onClaimReward: handleClaimReward,
                ),
                const SizedBox(height: AppSpacing.lg),

                // ─── Power Inventory ───
                const PowerInventoryGrid(),
                const SizedBox(height: AppSpacing.xl),

                // ─── About Me ───
                SectionCard(
                  title: context.tr('about_me'),
                  onTap: () => navigateTo(RouteNames.editProfile),
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

                // ─── Details ───
                SectionCard(
                  title: context.tr('details'),
                  onTap: () => navigateTo(RouteNames.editProfile),
                  child: DetailChips(
                    user: user,
                    isOwnProfile: true,
                    onTap: () => navigateTo(RouteNames.editProfile),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // ─── Preferences ───
                SectionCard(
                  title: context.tr('preferences'),
                  onTap: () => navigateTo(RouteNames.editProfile),
                  child: ProfilePreferencesSection(
                    user: user,
                    genderPrefLabel:
                        genderPrefLabel(context, user.genderPref),
                    relationshipGoalLabel:
                        relationshipGoalLabel(context, user.relationshipGoal),
                    languageFlag: languageFlag,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ─── Menu Items ───
                ProfileMenuList(
                  questionCount: user.questionCount,
                  onEditProfile: () => navigateTo(RouteNames.editProfile),
                  onQuestions: () => navigateTo(RouteNames.questions),
                  onDiamonds: () => navigateTo(RouteNames.diamonds),
                  onSubscription: () => navigateTo(RouteNames.subscription),
                  onPassport: () => navigateTo(RouteNames.passport),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
