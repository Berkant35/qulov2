import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/widgets/profile_section_card.dart';
import 'package:qulo_v2/providers/edit_profile_provider.dart';

class EditProfileRelationshipGoalSection extends ConsumerWidget {
  const EditProfileRelationshipGoalSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final epState = ref.watch(editProfileProvider);

    final isComplete = epState.selectedRelationshipGoal != null &&
        epState.selectedRelationshipGoal != 'NOT_SURE';

    return ProfileSectionCard(
      icon: Icons.favorite,
      title: context.tr('profile_relationship_title'),
      subtitle: context.tr('profile_relationship_subtitle'),
      completionText: isComplete ? '1/1' : '0/1',
      isComplete: isComplete,
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'SERIOUS', label: Text(context.tr('profile_relationship_serious'))),
            ButtonSegment(value: 'FRIENDSHIP', label: Text(context.tr('profile_relationship_friendship'))),
            ButtonSegment(value: 'NOT_SURE', label: Text(context.tr('profile_relationship_not_sure'))),
          ],
          selected: {epState.selectedRelationshipGoal ?? 'NOT_SURE'},
          onSelectionChanged: (v) =>
              ref.read(editProfileProvider.notifier).setRelationshipGoal(v.first),
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: context.appColors.primarySurface,
            selectedForegroundColor: context.appColors.primary,
          ),
        ),
      ),
    );
  }
}
