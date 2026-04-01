import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/app_localizations.dart';
import 'package:qulo_v2/core/services/location_manager.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/features/auth/screens/profile_completion_screen.dart';

mixin ProfileCompletionMixin on ConsumerState<ProfileCompletionScreen> {
  static const totalSteps = 3;

  final pageController = PageController();
  int currentStep = 0;
  DateTime? birthday;
  String? gender;
  double? lat;
  double? lng;
  bool locationGranted = false;
  bool isRequestingLocation = false;
  bool isSubmitting = false;

  // Error state
  String? birthdayError;
  String? genderError;
  String? locationError;
  String? submitError;

  void initMixin() {}

  void disposeMixin() {
    pageController.dispose();
  }

  void goToStep(int step) {
    pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => currentStep = step);
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

  bool validateBirthday() {
    final l10n = AppLocalizations.of(context);
    String? err;
    if (birthday == null) {
      err = l10n.get('field_required');
    } else if (calculateAge() < 18) {
      err = l10n.get('must_be_18');
    }
    setState(() => birthdayError = err);
    return err == null;
  }

  bool validateGender() {
    final l10n = AppLocalizations.of(context);
    final err = gender == null ? l10n.get('field_required') : null;
    setState(() => genderError = err);
    return err == null;
  }

  void nextStep() {
    bool valid;
    switch (currentStep) {
      case 0:
        valid = validateBirthday();
      case 1:
        valid = validateGender();
      default:
        valid = true;
    }
    if (valid) goToStep(currentStep + 1);
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

  Future<void> completeProfile() async {
    setState(() {
      isSubmitting = true;
      submitError = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.completeProfile({
        'age': calculateAge(),
        'gender': gender!,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      });

      if (!mounted) return;
      await ref.read(authProvider.notifier).onProfileCompleted();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isSubmitting = false;
        submitError = e.toString();
      });
    }
  }

  /// Returns true if screen should allow pop (i.e. at step 0 → logout)
  Future<bool> handleBack() async {
    if (currentStep > 0) {
      goToStep(currentStep - 1);
      return false;
    }
    // At step 0 → logout the user
    await ref.read(authProvider.notifier).logout();
    return true;
  }
}
