import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    required this.onPassport,
  });

  final int questionCount;
  final VoidCallback onEditProfile;
  final VoidCallback onQuestions;
  final VoidCallback onDiamonds;
  final VoidCallback onSubscription;
  final VoidCallback onPassport;

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
          iconPath: QIcons.icHelpCircle,
          title: context.tr('my_questions'),
          subtitle: questionCount < AppConstants.minQuestions
              ? context.tr('question_nudge_menu_required')
              : null,
          showBadge: questionCount < AppConstants.minQuestions,
          onTap: onQuestions,
        ),
        ProfileMenuItem(
          iconWidget: const DiamondIcon.purple(size: 24),
          title: context.tr('diamonds'),
          onTap: onDiamonds,
        ),
        ProfileMenuItem(
          iconPath: QIcons.icCrown,
          title: context.tr('sub_my_subscription'),
          subtitle: _subscriptionSubtitle(context, ref),
          onTap: onSubscription,
        ),
        ProfileMenuItem(
          iconPath: QIcons.icPlane,
          title: context.tr('passport'),
          onTap: onPassport,
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
        final formatted =
            '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
        return '$planLabel • $formatted';
      }
    }
    return planLabel;
  }
}
