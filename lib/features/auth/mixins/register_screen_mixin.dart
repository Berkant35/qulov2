import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/services/location_manager.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/features/auth/screens/register_screen.dart';

mixin RegisterScreenMixin on ConsumerState<RegisterScreen> {
  static const totalSteps = 6;

  final pageController = PageController();
  final nameCtrl = TextEditingController();
  final surnameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final referralCodeCtrl = TextEditingController();

  int currentStep = 0;
  DateTime? birthday;
  String? gender;
  double? lat;
  double? lng;
  bool locationGranted = false;
  bool isRequestingLocation = false;
  bool termsAccepted = false;
  bool obscurePassword = true;
  bool isLoading = false;
  bool referralExpanded = false;
  bool validatingReferral = false;
  String? referralValidName;

  // Error state
  String? nameError;
  String? surnameError;
  String? emailError;
  String? passwordError;
  String? birthdayError;
  String? genderError;
  String? locationError;
  String? termsError;
  String? referralError;

  void initMixin() {
    if (widget.referralCode != null && widget.referralCode!.isNotEmpty) {
      referralCodeCtrl.text = widget.referralCode!;
      referralExpanded = true;
    }
  }

  void disposeMixin() {
    pageController.dispose();
    nameCtrl.dispose();
    surnameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    referralCodeCtrl.dispose();
  }

  void goToStep(int step) {
    pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => currentStep = step);
  }

  void nextStep() {
    if (validateCurrentStep()) {
      goToStep(currentStep + 1);
    }
  }

  bool validateCurrentStep() {
    final l10n = AppLocalizations.of(context);

    switch (currentStep) {
      case 0:
        final nameErr =
            nameCtrl.text.trim().isEmpty ? l10n.get('field_required') : null;
        final surnameErr =
            surnameCtrl.text.trim().isEmpty ? l10n.get('field_required') : null;
        setState(() {
          nameError = nameErr;
          surnameError = surnameErr;
        });
        return nameErr == null && surnameErr == null;

      case 1:
        String? err;
        if (birthday == null) {
          err = l10n.get('field_required');
        } else if (calculateAge() < 18) {
          err = l10n.get('must_be_18');
        }
        setState(() => birthdayError = err);
        return err == null;

      case 2:
        final err = gender == null ? l10n.get('field_required') : null;
        setState(() => genderError = err);
        return err == null;

      case 3:
        return true;

      case 4:
        final emailErr = _emailValidator(emailCtrl.text.trim());
        final passErr = _passwordValidator(passwordCtrl.text);
        setState(() {
          emailError = emailErr;
          passwordError = passErr;
        });
        return emailErr == null && passErr == null;

      case 5:
        final err = !termsAccepted ? l10n.get('must_accept_terms') : null;
        setState(() => termsError = err);
        return err == null;

      default:
        return false;
    }
  }

  String? _emailValidator(String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.trim().isEmpty) return l10n.get('email_required');
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return l10n.get('email_invalid');
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) return l10n.get('password_required');
    if (value.length < 8) return l10n.get('password_min');
    return null;
  }

  int calculateAge() {
    if (birthday == null) return 0;
    final now = DateTime.now();
    int age = now.year - birthday!.year;
    if (now.month < birthday!.month ||
        (now.month == birthday!.month && now.day < birthday!.day)) {
      age--;
    }
    return age;
  }

  Future<void> requestLocation() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      isRequestingLocation = true;
      locationError = null;
    });

    try {
      final manager = ref.read(locationManagerProvider);

      final serviceEnabled = await manager.isServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          isRequestingLocation = false;
          locationError = l10n.get('location_service_disabled');
        });
        return;
      }

      var permission = await manager.checkPermission();
      if (permission == LocationPermissionStatus.denied) {
        permission = await manager.requestPermission();
        if (permission == LocationPermissionStatus.denied) {
          setState(() {
            isRequestingLocation = false;
            locationError = l10n.get('location_permission_denied');
          });
          return;
        }
      }

      if (permission == LocationPermissionStatus.deniedForever) {
        setState(() {
          isRequestingLocation = false;
          locationError = l10n.get('location_permission_denied_forever');
        });
        return;
      }

      final result = await manager.getCurrentPosition();

      setState(() {
        lat = result.lat;
        lng = result.lng;
        locationGranted = true;
        isRequestingLocation = false;
      });
    } catch (e) {
      setState(() {
        isRequestingLocation = false;
        locationError = e.toString();
      });
    }
  }

  Future<void> validateReferralCode() async {
    final code = referralCodeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() {
        referralError = null;
        referralValidName = null;
      });
      return;
    }

    setState(() {
      validatingReferral = true;
      referralError = null;
      referralValidName = null;
    });

    try {
      final repo = ref.read(referralRepositoryProvider);
      final result = await repo.validateCode(code);
      if (!mounted) return;
      result.when(
        success: (response) {
          setState(() {
            validatingReferral = false;
            if (response.valid) {
              referralValidName = response.referrerName;
              referralError = null;
            } else {
              referralError = context.tr('referral_code_invalid');
              referralValidName = null;
            }
          });
        },
        failure: (_) {
          setState(() {
            validatingReferral = false;
            referralError = context.tr('referral_code_invalid');
          });
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          validatingReferral = false;
          referralError = context.tr('referral_code_invalid');
        });
      }
    }
  }

  Future<void> register() async {
    if (!validateCurrentStep()) return;

    setState(() => isLoading = true);

    final referralCode = referralCodeCtrl.text.trim();
    final result = await ref.read(authProvider.notifier).register(
          email: emailCtrl.text.trim(),
          password: passwordCtrl.text,
          name: nameCtrl.text.trim(),
          surname: surnameCtrl.text.trim(),
          age: calculateAge(),
          gender: gender!,
          lat: lat,
          lng: lng,
          referralCode: referralCode.isNotEmpty ? referralCode : null,
        );

    if (!mounted) return;
    setState(() => isLoading = false);

    final l10n = AppLocalizations.of(context);
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.get('check_email'))),
        );
        ref.read(navigationServiceProvider).go(RouteNames.login);
      },
      failure: (f) {
        final errorCode = switch (f) {
          ServerFailure(:final code) => code,
          _ => 'UNKNOWN',
        };
        if (errorCode == 'EMAIL_ALREADY_EXISTS') {
          setState(() => emailError = l10n.errorMessage(errorCode));
          goToStep(4);
        } else {
          setState(() => termsError = l10n.errorMessage(errorCode));
        }
      },
    );
  }

  void handleBack() {
    if (currentStep > 0) {
      goToStep(currentStep - 1);
    } else {
      ref.read(navigationServiceProvider).pop();
    }
  }
}
