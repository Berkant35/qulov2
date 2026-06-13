import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/profile/widgets/pref_chip.dart';

class ProfilePreferencesSection extends StatelessWidget {
  const ProfilePreferencesSection({
    super.key,
    required this.user,
    required this.genderPrefLabel,
    required this.relationshipGoalLabel,
    required this.languageFlag,
  });

  final UserModel user;
  final String genderPrefLabel;
  final String relationshipGoalLabel;
  final String Function(String code) languageFlag;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        if (user.genderPref != null)
          PrefChip(
            iconPath: QIcons.icGenderPref,
            label: genderPrefLabel,
          ),
        if (user.agePrefMin != null && user.agePrefMax != null)
          PrefChip(
            iconPath: QIcons.icAgeRange,
            label: '${user.agePrefMin} - ${user.agePrefMax}',
          ),
        PrefChip(
          iconPath: QIcons.mapPin,
          label: '${user.matchRadiusKm} km',
        ),
        if (user.relationshipGoal != null && user.relationshipGoal != 'NOT_SURE')
          PrefChip(
            iconPath: QIcons.heart,
            label: relationshipGoalLabel,
          ),
        if (user.preferredLanguages.isNotEmpty)
          PrefChip(
            iconPath: QIcons.globe,
            label: user.preferredLanguages.map(languageFlag).join(', '),
          ),
      ],
    );
  }
}
