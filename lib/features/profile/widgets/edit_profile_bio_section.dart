import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/profile_field_limits.dart';
import 'package:qulo_v2/core/widgets/app_text_field.dart';
import 'package:qulo_v2/core/widgets/profile_section_card.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';

class EditProfileBioSection extends StatelessWidget {
  final TextEditingController bioController;

  const EditProfileBioSection({
    super.key,
    required this.bioController,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileSectionCard(
      icon: Icons.edit_note,
      title: context.tr('about'),
      subtitle: context.tr('profile_bio_subtitle'),
      completionText: bioController.text.trim().isEmpty ? '0/1' : '1/1',
      isComplete: bioController.text.trim().isNotEmpty,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AppTextField(
            controller: bioController,
            label: context.tr('bio'),
            hint: context.tr('bio_hint'),
            maxLines: 4,
            maxLength: ProfileFieldLimits.bio,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }
}
