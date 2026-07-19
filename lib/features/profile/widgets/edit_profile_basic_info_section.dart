import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/profile_field_limits.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_icon.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/app_text_field.dart';
import 'package:qulo_v2/core/widgets/profile_section_card.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/providers/location_provider.dart';

class EditProfileBasicInfoSection extends ConsumerWidget {
  final TextEditingController nameController;
  final TextEditingController cityController;
  final TextEditingController heightController;
  final TextEditingController weightController;
  final String completionText;
  final VoidCallback onUpdateLocation;

  const EditProfileBasicInfoSection({
    super.key,
    required this.nameController,
    required this.cityController,
    required this.heightController,
    required this.weightController,
    required this.completionText,
    required this.onUpdateLocation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locState = ref.watch(locationProvider);

    return ProfileSectionCard(
      icon: Icons.person,
      title: context.tr('edit_basic_info'),
      subtitle: context.tr('profile_basic_info_subtitle'),
      completionText: completionText,
      isComplete: completionText == '4/4',
      child: Column(
        children: [
          AppTextField(
            controller: nameController,
            label: context.tr('name'),
            enabled: false,
          ),
          const SizedBox(height: AppSpacing.itemGap),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: cityController,
                  label: context.tr('city'),
                  hint: context.tr('city_hint'),
                  maxLength: ProfileFieldLimits.city,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _LocationButton(
                isLoading: locState.isLoading,
                onPressed: onUpdateLocation,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.itemGap),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: heightController,
                  label: context.tr('height'),
                  hint: 'cm',
                  maxLength: ProfileFieldLimits.height,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: AppSpacing.itemGap),
              Expanded(
                child: AppTextField(
                  controller: weightController,
                  label: context.tr('weight'),
                  hint: 'kg',
                  maxLength: ProfileFieldLimits.weight,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _LocationButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        onPressed: isLoading ? null : onPressed,
        style: IconButton.styleFrom(
          backgroundColor: context.appColors.primarySurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: AppLoadingWidget.small(),
              )
            : AppIcon(QIcons.mapPin, color: context.appColors.primary, size: 20),
      ),
    );
  }
}
