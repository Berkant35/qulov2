import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      title: 'Iliski Amaci',
      subtitle: 'Ne aradigini karsi taraf gorsun',
      completionText: isComplete ? '1/1' : '0/1',
      isComplete: isComplete,
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'SERIOUS', label: Text('Ciddi Iliski')),
            ButtonSegment(value: 'FRIENDSHIP', label: Text('Arkadaslik')),
            ButtonSegment(value: 'NOT_SURE', label: Text('Emin Degilim')),
          ],
          selected: {epState.selectedRelationshipGoal ?? 'NOT_SURE'},
          onSelectionChanged: (v) =>
              ref.read(editProfileProvider.notifier).setRelationshipGoal(v.first),
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: context.appColors.primarySurface,
            selectedForegroundColor: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
