import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/profile_section_card.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/providers/edit_profile_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';
import 'package:qulo_v2/features/profile/mixins/edit_profile_screen_mixin.dart';
import 'package:qulo_v2/features/profile/mixins/edit_profile_photos_mixin.dart';
import 'package:qulo_v2/features/profile/mixins/edit_profile_labels_mixin.dart';
import 'package:qulo_v2/features/profile/widgets/edit_profile_progress_bar.dart';
import 'package:qulo_v2/features/profile/widgets/edit_profile_question_nudge.dart';
import 'package:qulo_v2/features/profile/widgets/edit_profile_bio_section.dart';
import 'package:qulo_v2/features/profile/widgets/edit_profile_basic_info_section.dart';
import 'package:qulo_v2/features/profile/widgets/edit_profile_details_section.dart';
import 'package:qulo_v2/features/profile/widgets/edit_profile_preferences_section.dart';
import 'package:qulo_v2/features/profile/widgets/edit_profile_relationship_goal_section.dart';
import 'package:qulo_v2/features/profile/widgets/edit_profile_save_button.dart';
import 'package:qulo_v2/features/profile/widgets/photo_grid.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/routing/route_names.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
    with EditProfileScreenMixin, EditProfilePhotosMixin, EditProfileLabelsMixin {
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
    final epState = ref.watch(editProfileProvider);
    final user = ref.watch(userProvider).valueOrNull;
    final completion = user?.profileCompletion ?? 0;

    return AppScaffold(
      title: context.tr('edit_profile'),
      showBackButton: true,
      padding: EdgeInsets.zero,
      actions: [
        IconButton(
          icon: const Icon(Icons.visibility),
          tooltip: context.tr('profile_preview_tooltip'),
          onPressed: () {
            ref.read(navigationServiceProvider).push(
              RouteNames.profilePreview,
              extra: 'edit_screen',
            );
          },
        ),
      ],
      bottomNavigationBar: EditProfileSaveButton(
        isSaving: epState.isSaving,
        onSave: save,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EditProfileQuestionNudge(),
            EditProfileProgressBar(
              completion: completion,
              milestoneMessage: milestoneMessage(completion),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            ProfileSectionCard(
              icon: Icons.photo_library,
              title: context.tr('photos'),
              subtitle: context.tr('profile_photo_hint'),
              completionText: photoCompletionText(epState.photos),
              isComplete: epState.photos.where((p) => p != null).length >= 2,
              child: PhotoGridFull(
                photos: epState.photos,
                editMode: true,
                onSlotTap: onPhotoSlotTap,
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            EditProfileBioSection(bioController: bioController),
            const SizedBox(height: AppSpacing.sectionGap),
            EditProfileBasicInfoSection(
              nameController: nameController,
              cityController: cityController,
              units: units,
              completionText: basicInfoCompletionText(),
              onUpdateLocation: updateLocation,
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            EditProfileDetailsSection(
              jobController: jobController,
              schoolController: schoolController,
              petsController: petsController,
              musicController: musicController,
              personalityController: personalityController,
              completionText: detailsCompletionText(epState),
              zodiacItems: zodiacItems(),
              frequencyItems: frequencyItems(),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            EditProfilePreferencesSection(
              completionText: preferencesCompletionText(epState),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            const EditProfileRelationshipGoalSection(),
            const SizedBox(height: AppSpacing.sectionGap),
          ],
        ),
      ),
    );
  }
}
