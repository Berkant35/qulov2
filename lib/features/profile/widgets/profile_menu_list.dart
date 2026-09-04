import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/providers/subscription_provider.dart';
import 'package:qulo_v2/features/profile/widgets/profile_menu_item.dart';

class ProfileMenuList extends ConsumerWidget {
  const ProfileMenuList({
    super.key,
    required this.questionCount,
    required this.onEditProfile,
    required this.onQuestions,
    required this.onDiamonds,
    required this.onSubscription,
    required this.onPerformance,
    required this.onPassport,
    required this.onTerms,
    required this.onPrivacy,
  });

  final int questionCount;
  final VoidCallback onEditProfile;
  final VoidCallback onQuestions;
  final VoidCallback onPerformance;
  final VoidCallback onDiamonds;
  final VoidCallback onSubscription;
  final VoidCallback onPassport;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        ProfileMenuItem(
          iconPath: QIcons.icPencil,
          title: context.tr('edit_profile'),
          onTap: onEditProfile,
        ),
        ProfileMenuItem(
          iconPath: QIcons.helpCircle,
          title: context.tr('my_questions'),
          subtitle: questionCount < AppConstants.minQuestions
              ? context.tr('question_nudge_menu_required')
              : null,
          showBadge: questionCount < AppConstants.minQuestions,
          onTap: onQuestions,
        ),
        ProfileMenuItem(
          iconPath: QIcons.icChart,
          title: context.tr('performance_analysis'),
          onTap: onPerformance,
        ),
        ProfileMenuItem(
          iconWidget: const DiamondIcon.purple(size: 24),
          title: context.tr('diamonds'),
          onTap: onDiamonds,
        ),
        ProfileMenuItem(
          iconPath: QIcons.crown,
          title: context.tr('sub_my_subscription'),
          subtitle: _subscriptionSubtitle(context, ref),
          onTap: onSubscription,
        ),
        ProfileMenuItem(
          iconPath: QIcons.icPlane,
          title: context.tr('passport'),
          onTap: onPassport,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
          child: Text(
            context.tr('legal'),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ProfileMenuItem(
          iconWidget: Icon(Icons.description_outlined,
              color: context.appColors.primary, size: 24),
          title: context.tr('terms_of_service'),
          onTap: onTerms,
        ),
        ProfileMenuItem(
          iconWidget: Icon(Icons.privacy_tip_outlined,
              color: context.appColors.primary, size: 24),
          title: context.tr('privacy_policy'),
          onTap: onPrivacy,
        ),
      ],
    );
  }

  String _subscriptionSubtitle(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(subscriptionProvider).valueOrNull;
    if (sub == null || sub.isFree) return context.tr('sub_free_upgrade');
    final planLabel = sub.isPremium ? 'Premium' : 'Plus';
    if (sub.expiresAt != null) {
      final date = DateTime.tryParse(sub.expiresAt!)?.toLocal();
      if (date != null) {
        final formatted = context.fmt.date(date);
        return '$planLabel • $formatted';
      }
    }
    return planLabel;
  }
}
