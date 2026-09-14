import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/public_profile_model.dart';
import 'package:qulo_v2/features/profile_detail/widgets/profile_basic_info.dart';
import 'package:qulo_v2/features/profile_detail/widgets/profile_bio_section.dart';
import 'package:qulo_v2/features/profile_detail/widgets/profile_details_grid.dart';
import 'package:qulo_v2/features/profile_detail/widgets/profile_photo_gallery.dart';
import 'package:qulo_v2/features/profile_detail/widgets/profile_question_info.dart';

/// Scrollable profile body shared by the profile detail screen (someone
/// else's profile) and the own-profile preview screen.
///
/// [footer] sits after the sections (e.g. the report/block button); without
/// it the body ends with extra space for the screen's bottom bar.
class ProfileDetailBody extends StatelessWidget {
  final PublicProfileModel profile;
  final VoidCallback onClose;
  final void Function(int index, int total) onPhotoChanged;
  final bool showOnlineStatus;
  final bool showDistance;
  final bool showQuestions;
  final Widget? footer;

  const ProfileDetailBody({
    super.key,
    required this.profile,
    required this.onClose,
    required this.onPhotoChanged,
    this.showOnlineStatus = false,
    this.showDistance = true,
    this.showQuestions = true,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final bio = profile.bio;
    final details = profile.details;
    final questionInfo = profile.questionInfo;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfilePhotoGallery(
            photos: profile.photos,
            onClose: onClose,
            onPhotoChanged: onPhotoChanged,
          ),
          const SizedBox(height: AppSpacing.lg),
          ProfileBasicInfo(
            profile: profile,
            showOnlineStatus: showOnlineStatus,
            showDistance: showDistance,
          ),
          if (bio != null && bio.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sectionGap),
            ProfileBioSection(bio: bio),
          ],
          if (details != null) ...[
            const SizedBox(height: AppSpacing.sectionGap),
            ProfileDetailsGrid(details: details),
          ],
          if (showQuestions && questionInfo != null) ...[
            const SizedBox(height: AppSpacing.sectionGap),
            ProfileQuestionInfo(questionInfo: questionInfo),
          ],
          if (footer case final footer?) ...[
            const SizedBox(height: AppSpacing.sectionGap),
            footer,
            const SizedBox(height: AppSpacing.lg),
          ] else
            const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}
