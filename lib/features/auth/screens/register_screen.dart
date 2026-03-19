import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_progress_bar.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/features/auth/mixins/register_screen_mixin.dart';
import 'package:qulo_v2/features/auth/widgets/register_step_birthday.dart';
import 'package:qulo_v2/features/auth/widgets/register_step_email.dart';
import 'package:qulo_v2/features/auth/widgets/register_step_gender.dart';
import 'package:qulo_v2/features/auth/widgets/register_step_location.dart';
import 'package:qulo_v2/features/auth/widgets/register_step_name.dart';
import 'package:qulo_v2/features/auth/widgets/register_step_terms.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String? referralCode;

  const RegisterScreen({super.key, this.referralCode});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with RegisterScreenMixin {
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
      canPop: currentStep == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          handleBack();
        }
      },
      child: AppScaffold(
        padding: EdgeInsets.zero,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: handleBack,
        ),
        title: '',
        body: Column(
          children: [
            AppProgressBar(
              currentStep: currentStep + 1,
              totalSteps: RegisterScreenMixin.totalSteps,
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
                  RegisterStepName(
                    nameCtrl: nameCtrl,
                    surnameCtrl: surnameCtrl,
                    nameError: nameError,
                    surnameError: surnameError,
                    onContinue: nextStep,
                  ),
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
                    onContinue: nextStep,
                    onSkip: () => goToStep(currentStep + 1),
                    onOpenSettings: () =>
                        ref.read(locationManagerProvider).openAppSettings(),
                  ),
                  RegisterStepEmail(
                    emailCtrl: emailCtrl,
                    passwordCtrl: passwordCtrl,
                    emailError: emailError,
                    passwordError: passwordError,
                    obscurePassword: obscurePassword,
                    onToggleObscure: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                    onContinue: nextStep,
                  ),
                  RegisterStepTerms(
                    termsAccepted: termsAccepted,
                    onTermsChanged: (value) {
                      setState(() {
                        termsAccepted = value ?? false;
                        termsError = null;
                      });
                    },
                    errorText: termsError,
                    isLoading: isLoading,
                    onRegister: register,
                    onOpenUrl: (url) =>
                        ref.read(urlLauncherManagerProvider).launch(url),
                    referralCodeCtrl: referralCodeCtrl,
                    referralExpanded: referralExpanded,
                    onToggleReferral: () =>
                        setState(() => referralExpanded = !referralExpanded),
                    onValidateReferral: validateReferralCode,
                    validatingReferral: validatingReferral,
                    referralValidName: referralValidName,
                    referralError: referralError,
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
