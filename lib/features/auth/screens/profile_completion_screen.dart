import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_progress_bar.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/features/auth/mixins/profile_completion_mixin.dart';
import 'package:qulo_v2/features/auth/widgets/register_step_birthday.dart';
import 'package:qulo_v2/features/auth/widgets/register_step_gender.dart';
import 'package:qulo_v2/features/auth/widgets/register_step_location.dart';

class ProfileCompletionScreen extends ConsumerStatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  ConsumerState<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends ConsumerState<ProfileCompletionScreen>
    with ProfileCompletionMixin {
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          await handleBack();
        }
      },
      child: AppScaffold(
        isLoading: isSubmitting,
        padding: EdgeInsets.zero,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => handleBack(),
        ),
        title: '',
        body: Column(
          children: [
            AppProgressBar(
              currentStep: currentStep + 1,
              totalSteps: ProfileCompletionMixin.totalSteps,
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: PageView(
                controller: pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => currentStep = index);
                },
                children: [
                  RegisterStepBirthday(
                    selectedDate: birthday,
                    onDateSelected: (date) {
                      setState(() {
                        birthday = date;
                        birthdayError = null;
                      });
                    },
                    errorText: birthdayError,
                    onContinue: nextStep,
                  ),
                  RegisterStepGender(
                    selectedGender: gender,
                    onGenderSelected: (g) {
                      setState(() {
                        gender = g;
                        genderError = null;
                      });
                    },
                    errorText: genderError,
                    onContinue: nextStep,
                  ),
                  RegisterStepLocation(
                    locationGranted: locationGranted,
                    isRequesting: isRequestingLocation,
                    errorText: locationError,
                    onRequestLocation: requestLocation,
                    onContinue: completeProfile,
                    onSkip: completeProfile,
                    onOpenSettings: () =>
                        ref.read(locationManagerProvider).openAppSettings(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
