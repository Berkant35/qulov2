import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/profile_section_card.dart';
import 'package:qulo_v2/data/models/identity_model.dart';
import 'package:qulo_v2/features/identity/mixins/edit_profile_identity_section_mixin.dart';
import 'package:qulo_v2/features/identity/widgets/edit_profile_gender_row.dart';
import 'package:qulo_v2/features/identity/widgets/identity_chips.dart';
import 'package:qulo_v2/providers/identity_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

/// Profil düzenleme: kilitli cinsiyet satırı + kimlik/yönelim etiketleri (ekle/düzenle/sil,
/// grup başına görünürlük). Etiketler yalnız profil bilgisidir; eşleşmeye etkisi yoktur.
class EditProfileIdentitySection extends ConsumerStatefulWidget {
  const EditProfileIdentitySection({super.key});

  @override
  ConsumerState<EditProfileIdentitySection> createState() => _EditProfileIdentitySectionState();
}

class _EditProfileIdentitySectionState extends ConsumerState<EditProfileIdentitySection>
    with EditProfileIdentitySectionMixin {
  @override
  Widget build(BuildContext context) {
    final gender = ref.watch(userProvider.select((u) => u.valueOrNull?.gender));
    final identityAsync = ref.watch(identityProvider);
    final identity = identityAsync.valueOrNull;

    return ProfileSectionCard(
      icon: Icons.badge_outlined,
      title: context.tr('identity_section_title'),
      subtitle: context.tr('identity_section_subtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (genderLabelKey(gender) case final genderKey?) ...[
            EditProfileGenderRow(genderLabelKey: genderKey, onRequestChange: requestGenderChange),
            const SizedBox(height: AppSpacing.md),
          ],
          if (identity != null)
            _IdentityLabelsBody(
              identity: identity,
              isBusy: isBusy,
              onEdit: edit,
              onToggleGender: (value) => toggleShow(gender: value),
              onToggleOrientation: (value) => toggleShow(orientation: value),
              onClear: clearLabels,
            )
          else if (identityAsync.hasError && !identityAsync.isLoading)
            Row(
              children: [
                Expanded(child: Text(context.tr('error'))),
                TextButton(onPressed: retryLoad, child: Text(context.tr('retry'))),
              ],
            )
          else
            const Center(child: AppLoadingWidget.small()),
        ],
      ),
    );
  }
}

class _IdentityLabelsBody extends StatelessWidget {
  final IdentityModel identity;
  final bool isBusy;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggleGender;
  final ValueChanged<bool> onToggleOrientation;
  final VoidCallback onClear;

  const _IdentityLabelsBody({
    required this.identity,
    required this.isBusy,
    required this.onEdit,
    required this.onToggleGender,
    required this.onToggleOrientation,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (identity.isEmpty) {
      return Row(
        children: [
          Expanded(
            child: Text(
              context.tr('identity_none'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: isBusy ? null : onEdit,
            child: Text(context.tr('identity_banner_add')),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IdentityChips(
          identity: VisibleIdentityModel(
            genderLabels: identity.genderLabels,
            orientationLabels: identity.orientationLabels,
          ),
        ),
        TextButton(onPressed: isBusy ? null : onEdit, child: Text(context.tr('identity_edit'))),
        if (identity.orientationLabels.isNotEmpty)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.tr('identity_show_orientation')),
            value: identity.showOrientationLabels,
            onChanged: isBusy ? null : onToggleOrientation,
          ),
        if (identity.genderLabels.isNotEmpty)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.tr('identity_show_gender')),
            value: identity.showGenderLabels,
            onChanged: isBusy ? null : onToggleGender,
          ),
        TextButton(
          onPressed: isBusy ? null : onClear,
          style: TextButton.styleFrom(foregroundColor: context.appColors.error),
          child: Text(context.tr('identity_clear')),
        ),
      ],
    );
  }
}
