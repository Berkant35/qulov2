import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/mixins/form_mixin.dart';
import 'package:qulo_v2/core/services/location_manager.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_progress_bar.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';
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
    with FormMixin {
  static const _totalSteps = 6;

  final _pageController = PageController();
  final _nameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _referralCodeCtrl = TextEditingController();

  int _currentStep = 0;
  DateTime? _birthday;
  String? _gender;
  double? _lat;
  double? _lng;
  bool _locationGranted = false;
  bool _isRequestingLocation = false;
  bool _termsAccepted = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _referralExpanded = false;
  bool _validatingReferral = false;
  String? _referralValidName;

  // Error state
  String? _nameError;
  String? _surnameError;
  String? _emailError;
  String? _passwordError;
  String? _birthdayError;
  String? _genderError;
  String? _locationError;
  String? _termsError;
  String? _referralError;

  @override
  void initState() {
    super.initState();
    if (widget.referralCode != null && widget.referralCode!.isNotEmpty) {
      _referralCodeCtrl.text = widget.referralCode!;
      _referralExpanded = true;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtrl.dispose();
    _surnameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _referralCodeCtrl.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep = step);
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      _goToStep(_currentStep + 1);
    }
  }

  bool _validateCurrentStep() {
    final l10n = AppLocalizations.of(context);

    switch (_currentStep) {
      case 0:
        final nameErr = _nameCtrl.text.trim().isEmpty
            ? l10n.get('field_required')
            : null;
        final surnameErr = _surnameCtrl.text.trim().isEmpty
            ? l10n.get('field_required')
            : null;
        setState(() {
          _nameError = nameErr;
          _surnameError = surnameErr;
        });
        return nameErr == null && surnameErr == null;

      case 1:
        String? err;
        if (_birthday == null) {
          err = l10n.get('field_required');
        } else if (_calculateAge() < 18) {
          err = l10n.get('must_be_18');
        }
        setState(() => _birthdayError = err);
        return err == null;

      case 2:
        final err =
            _gender == null ? l10n.get('field_required') : null;
        setState(() => _genderError = err);
        return err == null;

      case 3:
        return true;

      case 4:
        final emailErr = emailValidator(_emailCtrl.text.trim());
        final passErr = passwordValidator(_passwordCtrl.text);
        setState(() {
          _emailError = emailErr;
          _passwordError = passErr;
        });
        return emailErr == null && passErr == null;

      case 5:
        final err = !_termsAccepted
            ? l10n.get('must_accept_terms')
            : null;
        setState(() => _termsError = err);
        return err == null;

      default:
        return false;
    }
  }

  int _calculateAge() {
    if (_birthday == null) return 0;
    final now = DateTime.now();
    int age = now.year - _birthday!.year;
    if (now.month < _birthday!.month ||
        (now.month == _birthday!.month && now.day < _birthday!.day)) {
      age--;
    }
    return age;
  }

  Future<void> _requestLocation() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isRequestingLocation = true;
      _locationError = null;
    });

    try {
      final manager = ref.read(locationManagerProvider);

      final serviceEnabled = await manager.isServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isRequestingLocation = false;
          _locationError = l10n.get('location_service_disabled');
        });
        return;
      }

      var permission = await manager.checkPermission();
      if (permission == LocationPermissionStatus.denied) {
        permission = await manager.requestPermission();
        if (permission == LocationPermissionStatus.denied) {
          setState(() {
            _isRequestingLocation = false;
            _locationError = l10n.get('location_permission_denied');
          });
          return;
        }
      }

      if (permission == LocationPermissionStatus.deniedForever) {
        setState(() {
          _isRequestingLocation = false;
          _locationError = l10n.get('location_permission_denied_forever');
        });
        return;
      }

      final result = await manager.getCurrentPosition();

      setState(() {
        _lat = result.lat;
        _lng = result.lng;
        _locationGranted = true;
        _isRequestingLocation = false;
      });
    } catch (e) {
      setState(() {
        _isRequestingLocation = false;
        _locationError = e.toString();
      });
    }
  }

  Future<void> _validateReferralCode() async {
    final code = _referralCodeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() {
        _referralError = null;
        _referralValidName = null;
      });
      return;
    }

    setState(() {
      _validatingReferral = true;
      _referralError = null;
      _referralValidName = null;
    });

    try {
      final repo = ref.read(referralRepositoryProvider);
      final result = await repo.validateCode(code);
      if (!mounted) return;
      result.when(
        success: (response) {
          setState(() {
            _validatingReferral = false;
            if (response.valid) {
              _referralValidName = response.referrerName;
              _referralError = null;
            } else {
              _referralError = context.tr('referral_code_invalid');
              _referralValidName = null;
            }
          });
        },
        failure: (_) {
          setState(() {
            _validatingReferral = false;
            _referralError = context.tr('referral_code_invalid');
          });
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _validatingReferral = false;
          _referralError = context.tr('referral_code_invalid');
        });
      }
    }
  }

  Future<void> _register() async {
    if (!_validateCurrentStep()) return;

    setState(() => _isLoading = true);

    final referralCode = _referralCodeCtrl.text.trim();
    final result = await ref.read(authProvider.notifier).register(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          name: _nameCtrl.text.trim(),
          surname: _surnameCtrl.text.trim(),
          age: _calculateAge(),
          gender: _gender!,
          lat: _lat,
          lng: _lng,
          referralCode: referralCode.isNotEmpty ? referralCode : null,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

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
          setState(() => _emailError = l10n.errorMessage(errorCode));
          _goToStep(4);
        } else {
          setState(() => _termsError = l10n.errorMessage(errorCode));
        }
      },
    );
  }

  void _handleBack() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    } else {
      ref.read(navigationServiceProvider).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: AppScaffold(
      padding: EdgeInsets.zero,
      leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _handleBack,
            ),
      title: '',
      body: Column(
          children: [
            AppProgressBar(
              currentStep: _currentStep + 1,
              totalSteps: _totalSteps,
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentStep = index);
                },
                children: [
                  RegisterStepName(
                    nameCtrl: _nameCtrl,
                    surnameCtrl: _surnameCtrl,
                    nameError: _nameError,
                    surnameError: _surnameError,
                    onContinue: _nextStep,
                  ),
                  RegisterStepBirthday(
                    selectedDate: _birthday,
                    onDateSelected: (date) {
                      setState(() {
                        _birthday = date;
                        _birthdayError = null;
                      });
                    },
                    errorText: _birthdayError,
                    onContinue: _nextStep,
                  ),
                  RegisterStepGender(
                    selectedGender: _gender,
                    onGenderSelected: (gender) {
                      setState(() {
                        _gender = gender;
                        _genderError = null;
                      });
                    },
                    errorText: _genderError,
                    onContinue: _nextStep,
                  ),
                  RegisterStepLocation(
                    locationGranted: _locationGranted,
                    isRequesting: _isRequestingLocation,
                    errorText: _locationError,
                    onRequestLocation: _requestLocation,
                    onContinue: _nextStep,
                    onSkip: () => _goToStep(_currentStep + 1),
                    onOpenSettings: () => ref.read(locationManagerProvider).openAppSettings(),
                  ),
                  RegisterStepEmail(
                    emailCtrl: _emailCtrl,
                    passwordCtrl: _passwordCtrl,
                    emailError: _emailError,
                    passwordError: _passwordError,
                    obscurePassword: _obscurePassword,
                    onToggleObscure: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    onContinue: _nextStep,
                  ),
                  RegisterStepTerms(
                    termsAccepted: _termsAccepted,
                    onTermsChanged: (value) {
                      setState(() {
                        _termsAccepted = value ?? false;
                        _termsError = null;
                      });
                    },
                    errorText: _termsError,
                    isLoading: _isLoading,
                    onRegister: _register,
                    onOpenUrl: (url) => ref.read(urlLauncherManagerProvider).launch(url),
                    referralCodeCtrl: _referralCodeCtrl,
                    referralExpanded: _referralExpanded,
                    onToggleReferral: () => setState(() => _referralExpanded = !_referralExpanded),
                    onValidateReferral: _validateReferralCode,
                    validatingReferral: _validatingReferral,
                    referralValidName: _referralValidName,
                    referralError: _referralError,
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
