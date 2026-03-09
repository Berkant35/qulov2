# Auth Improvements Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Auth ekranlarına inline hata mesajları, 5 adımlı register wizard, date picker, privacy policy ve ortak UI komponentleri eklemek.

**Architecture:** Backend error code'ları DioException'dan parse edilip ApiException'a dönüştürülür. i18n ile kullanıcıya gösterilir. Register tek sayfadan 5 adımlı PageView wizard'a çevrilir. Tüm UI bileşenleri theme'den beslenen ortak komponentler olarak yazılır.

**Tech Stack:** Flutter, Riverpod, Dio, GoRouter, url_launcher

---

### Task 1: ApiException + Error Parsing

**Files:**
- Create: `lib/core/error/api_exception.dart`
- Modify: `lib/core/network/token_interceptor.dart`
- Modify: `lib/data/models/api_error_model.dart`

**Step 1: Create ApiException class**

```dart
// lib/core/error/api_exception.dart
import '../network/api_error_model.dart';

class ApiException implements Exception {
  final String code;
  final dynamic params;
  final int? statusCode;

  const ApiException({
    required this.code,
    this.params,
    this.statusCode,
  });

  factory ApiException.fromResponse(Map<String, dynamic> data, int? statusCode) {
    final error = data['error'] as Map<String, dynamic>?;
    if (error != null) {
      return ApiException(
        code: error['code'] as String? ?? 'SERVER_ERROR',
        params: error['params'],
        statusCode: statusCode,
      );
    }
    return ApiException(code: 'SERVER_ERROR', statusCode: statusCode);
  }

  @override
  String toString() => 'ApiException($code)';
}
```

**Step 2: Update token_interceptor.dart to parse errors**

In `token_interceptor.dart`, update `onError` method. After the existing error logging and before the 401 refresh logic, add error parsing for non-401 errors. For all DioExceptions with a response body, parse the error and reject with ApiException instead of raw DioException:

```dart
// In onError method, BEFORE the 401 check, add:
if (err.response?.data is Map<String, dynamic>) {
  final apiException = ApiException.fromResponse(
    err.response!.data as Map<String, dynamic>,
    err.response?.statusCode,
  );
  return handler.reject(
    DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: apiException,
    ),
  );
}
```

**Step 3: Commit**

```bash
git add lib/core/error/api_exception.dart lib/core/network/token_interceptor.dart
git commit -m "feat: add ApiException and error parsing in interceptor"
```

---

### Task 2: i18n Error Code Translations

**Files:**
- Modify: `lib/core/l10n/app_localizations.dart`

**Step 1: Add error code keys and register wizard keys**

Add these keys to both `_en` and `_tr` maps in `app_localizations.dart`:

English keys to add:
```dart
// Error codes
'error_invalid_credentials': 'Email or password is incorrect',
'error_email_already_exists': 'This email is already registered',
'error_email_not_verified': 'Please verify your email first',
'error_validation_error': 'Please check your input',
'error_rate_limited': 'Too many attempts, please try again later',
'error_server_error': 'Something went wrong, please try again',
'error_unknown': 'An unexpected error occurred',

// Register wizard
'step_name': 'What\'s your name?',
'step_birthday': 'When\'s your birthday?',
'step_gender': 'How do you identify?',
'step_email': 'Create your account',
'step_terms': 'Almost there!',
'birthday': 'Date of birth',
'select_date': 'Select date',
'must_be_18': 'You must be at least 18 years old',
'man': 'Man',
'woman': 'Woman',
'other': 'Other',
'continue_btn': 'Continue',
'accept_terms': 'I accept the',
'terms_of_service': 'Terms of Service',
'privacy_policy': 'Privacy Policy',
'and_word': 'and',
'must_accept_terms': 'You must accept the terms to continue',
```

Turkish keys to add:
```dart
// Error codes
'error_invalid_credentials': 'Email veya şifre hatalı',
'error_email_already_exists': 'Bu email zaten kayıtlı',
'error_email_not_verified': 'Lütfen önce emailinizi doğrulayın',
'error_validation_error': 'Lütfen girişlerinizi kontrol edin',
'error_rate_limited': 'Çok fazla deneme, lütfen daha sonra tekrar deneyin',
'error_server_error': 'Bir hata oluştu, lütfen tekrar deneyin',
'error_unknown': 'Beklenmeyen bir hata oluştu',

// Register wizard
'step_name': 'Adın ne?',
'step_birthday': 'Doğum günün ne zaman?',
'step_gender': 'Cinsiyetin ne?',
'step_email': 'Hesabını oluştur',
'step_terms': 'Neredeyse tamam!',
'birthday': 'Doğum tarihi',
'select_date': 'Tarih seçin',
'must_be_18': 'En az 18 yaşında olmalısınız',
'man': 'Erkek',
'woman': 'Kadın',
'other': 'Diğer',
'continue_btn': 'Devam',
'accept_terms': 'Kabul ediyorum:',
'terms_of_service': 'Kullanım Koşulları',
'privacy_policy': 'Gizlilik Politikası',
'and_word': 've',
'must_accept_terms': 'Devam etmek için koşulları kabul etmelisiniz',
```

**Step 2: Add error code → i18n key helper method**

Add this static method to `AppLocalizations`:

```dart
String errorMessage(String code) {
  final key = 'error_${code.toLowerCase()}';
  return _strings[key] ?? _strings['error_unknown']!;
}
```

**Step 3: Commit**

```bash
git add lib/core/l10n/app_localizations.dart
git commit -m "feat: add error code translations and register wizard i18n keys"
```

---

### Task 3: Theme Updates (Input, Button, Progress)

**Files:**
- Modify: `lib/core/theme/app_theme_components.dart`
- Modify: `lib/core/theme/app_colors.dart`

**Step 1: Add error-specific colors to app_colors.dart**

```dart
// Add to AppColors class:
static const errorLight = Color(0xFFFDE8E8);  // Light red bg for error fields
```

**Step 2: Update InputDecorationTheme in app_theme_components.dart**

Update existing `inputDecoration()` method to add better error styling:

```dart
// Add to the existing InputDecorationTheme:
errorMaxLines: 2,
errorStyle: TextStyle(
  color: AppColors.error,
  fontSize: 12,
  fontWeight: FontWeight.w400,
),
```

**Step 3: Add ProgressIndicatorThemeData to app_theme.dart**

```dart
// Add to the ThemeData in lightTheme:
progressIndicatorTheme: const ProgressIndicatorThemeData(
  color: AppColors.primary,
  linearTrackColor: AppColors.outlineVariant,
  linearMinHeight: 4,
),
```

**Step 4: Commit**

```bash
git add lib/core/theme/
git commit -m "feat: update theme with error styling and progress indicator"
```

---

### Task 4: Shared Components — AppTextField

**Files:**
- Create: `lib/core/widgets/app_text_field.dart`

**Step 1: Create AppTextField widget**

```dart
// lib/core/widgets/app_text_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final FocusNode? focusNode;
  final int maxLines;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onFieldSubmitted,
    this.inputFormatters,
    this.enabled = true,
    this.focusNode,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      inputFormatters: inputFormatters,
      enabled: enabled,
      maxLines: maxLines,
    );
  }
}
```

**Step 2: Commit**

```bash
git add lib/core/widgets/app_text_field.dart
git commit -m "feat: add AppTextField shared component"
```

---

### Task 5: Shared Components — AppButton, AppProgressBar, AppDatePicker

**Files:**
- Create: `lib/core/widgets/app_button.dart`
- Create: `lib/core/widgets/app_progress_bar.dart`
- Create: `lib/core/widgets/app_date_picker.dart`

**Step 1: Create AppButton**

```dart
// lib/core/widgets/app_button.dart
import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, text }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool fullWidth;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.fullWidth = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              )
            : Text(label);

    final button = switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
      AppButtonVariant.text => TextButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
    };

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
```

**Step 2: Create AppProgressBar**

```dart
// lib/core/widgets/app_progress_bar.dart
import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

class AppProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const AppProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: LinearProgressIndicator(
          value: currentStep / totalSteps,
          minHeight: 4,
        ),
      ),
    );
  }
}
```

**Step 3: Create AppDatePicker**

```dart
// lib/core/widgets/app_date_picker.dart
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

class AppDatePicker extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final String? errorText;

  const AppDatePicker({
    super.key,
    this.selectedDate,
    required this.onDateSelected,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _showPicker(context),
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: l10n['birthday'],
              errorText: errorText,
              prefixIcon: const Icon(Icons.cake_outlined),
              suffixIcon: const Icon(Icons.calendar_today_outlined),
            ),
            child: Text(
              selectedDate != null
                  ? '${selectedDate!.day.toString().padLeft(2, '0')}/'
                    '${selectedDate!.month.toString().padLeft(2, '0')}/'
                    '${selectedDate!.year}'
                  : l10n['select_date']!,
              style: selectedDate != null
                  ? theme.textTheme.bodyLarge
                  : theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showPicker(BuildContext context) async {
    final now = DateTime.now();
    final maxDate = DateTime(now.year - 18, now.month, now.day);
    final minDate = DateTime(now.year - 100);

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? maxDate,
      firstDate: minDate,
      lastDate: maxDate,
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      onDateSelected(picked);
    }
  }
}
```

**Step 4: Commit**

```bash
git add lib/core/widgets/
git commit -m "feat: add AppButton, AppProgressBar, AppDatePicker components"
```

---

### Task 6: Add url_launcher Dependency

**Files:**
- Modify: `pubspec.yaml`

**Step 1: Add url_launcher**

Add to dependencies in `pubspec.yaml` (after `flutter_native_splash`):

```yaml
  url_launcher: ^6.3.1
```

**Step 2: Run pub get**

```bash
flutter pub get
```

**Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "feat: add url_launcher dependency for privacy policy links"
```

---

### Task 7: Backend — Add "OTHER" Gender

**Files:**
- Modify: `server/src/validators/auth.validator.ts`

**Step 1: Update gender enum**

Change `z.enum(["MAN", "WOMAN"])` to `z.enum(["MAN", "WOMAN", "OTHER"])`.

**Step 2: Commit**

```bash
git add server/src/validators/auth.validator.ts
git commit -m "feat: add OTHER gender option to register validation"
```

---

### Task 8: Register Wizard — Step Widgets

**Files:**
- Create: `lib/features/auth/widgets/register_step_name.dart`
- Create: `lib/features/auth/widgets/register_step_birthday.dart`
- Create: `lib/features/auth/widgets/register_step_gender.dart`
- Create: `lib/features/auth/widgets/register_step_email.dart`
- Create: `lib/features/auth/widgets/register_step_terms.dart`

**Step 1: Create RegisterStepName**

```dart
// lib/features/auth/widgets/register_step_name.dart
import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class RegisterStepName extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController surnameCtrl;
  final String? nameError;
  final String? surnameError;
  final VoidCallback onContinue;

  const RegisterStepName({
    super.key,
    required this.nameCtrl,
    required this.surnameCtrl,
    this.nameError,
    this.surnameError,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          Text(l10n['step_name']!, style: AppTextStyles.headlineMedium),
          const SizedBox(height: AppSpacing.xxl),
          AppTextField(
            controller: nameCtrl,
            label: l10n['name'],
            errorText: nameError,
            prefixIcon: const Icon(Icons.person_outline),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: surnameCtrl,
            label: l10n['surname'],
            errorText: surnameError,
            prefixIcon: const Icon(Icons.person_outline),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onContinue(),
          ),
          const Spacer(),
          AppButton(
            label: l10n['continue_btn']!,
            onPressed: onContinue,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
```

**Step 2: Create RegisterStepBirthday**

```dart
// lib/features/auth/widgets/register_step_birthday.dart
import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/app_date_picker.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class RegisterStepBirthday extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final String? errorText;
  final VoidCallback onContinue;

  const RegisterStepBirthday({
    super.key,
    this.selectedDate,
    required this.onDateSelected,
    this.errorText,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          Text(l10n['step_birthday']!, style: AppTextStyles.headlineMedium),
          const SizedBox(height: AppSpacing.xxl),
          AppDatePicker(
            selectedDate: selectedDate,
            onDateSelected: onDateSelected,
            errorText: errorText,
          ),
          const Spacer(),
          AppButton(
            label: l10n['continue_btn']!,
            onPressed: onContinue,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
```

**Step 3: Create RegisterStepGender**

```dart
// lib/features/auth/widgets/register_step_gender.dart
import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';

class RegisterStepGender extends StatelessWidget {
  final String? selectedGender;
  final ValueChanged<String> onGenderSelected;
  final String? errorText;
  final VoidCallback onContinue;

  const RegisterStepGender({
    super.key,
    this.selectedGender,
    required this.onGenderSelected,
    this.errorText,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          Text(l10n['step_gender']!, style: AppTextStyles.headlineMedium),
          const SizedBox(height: AppSpacing.xxl),
          _GenderOption(
            label: l10n['man']!,
            icon: Icons.male,
            isSelected: selectedGender == 'MAN',
            onTap: () => onGenderSelected('MAN'),
          ),
          const SizedBox(height: AppSpacing.md),
          _GenderOption(
            label: l10n['woman']!,
            icon: Icons.female,
            isSelected: selectedGender == 'WOMAN',
            onTap: () => onGenderSelected('WOMAN'),
          ),
          const SizedBox(height: AppSpacing.md),
          _GenderOption(
            label: l10n['other']!,
            icon: Icons.transgender,
            isSelected: selectedGender == 'OTHER',
            onTap: () => onGenderSelected('OTHER'),
          ),
          if (errorText != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              errorText!,
              style: TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ],
          const Spacer(),
          AppButton(
            label: l10n['continue_btn']!,
            onPressed: onContinue,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _GenderOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: isSelected ? AppColors.primarySurface : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.md),
              Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.primary : null,
                ),
              ),
              const Spacer(),
              if (isSelected)
                const Icon(Icons.check_circle, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Step 4: Create RegisterStepEmail**

```dart
// lib/features/auth/widgets/register_step_email.dart
import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class RegisterStepEmail extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final String? emailError;
  final String? passwordError;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final VoidCallback onContinue;

  const RegisterStepEmail({
    super.key,
    required this.emailCtrl,
    required this.passwordCtrl,
    this.emailError,
    this.passwordError,
    this.obscurePassword = true,
    required this.onToggleObscure,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          Text(l10n['step_email']!, style: AppTextStyles.headlineMedium),
          const SizedBox(height: AppSpacing.xxl),
          AppTextField(
            controller: emailCtrl,
            label: l10n['email'],
            errorText: emailError,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: passwordCtrl,
            label: l10n['password'],
            errorText: passwordError,
            obscureText: obscurePassword,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: onToggleObscure,
            ),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onContinue(),
          ),
          const Spacer(),
          AppButton(
            label: l10n['continue_btn']!,
            onPressed: onContinue,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
```

**Step 5: Create RegisterStepTerms**

```dart
// lib/features/auth/widgets/register_step_terms.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';

class RegisterStepTerms extends StatelessWidget {
  final bool termsAccepted;
  final ValueChanged<bool?> onTermsChanged;
  final String? errorText;
  final bool isLoading;
  final VoidCallback onRegister;

  const RegisterStepTerms({
    super.key,
    required this.termsAccepted,
    required this.onTermsChanged,
    this.errorText,
    this.isLoading = false,
    required this.onRegister,
  });

  static const _termsUrl = 'https://qulo.app/terms';
  static const _privacyUrl = 'https://qulo.app/privacy';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          Text(l10n['step_terms']!, style: AppTextStyles.headlineMedium),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: termsAccepted,
                onChanged: onTermsChanged,
                activeColor: AppColors.primary,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium,
                      children: [
                        TextSpan(text: '${l10n['accept_terms']} '),
                        TextSpan(
                          text: l10n['terms_of_service'],
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _openUrl(_termsUrl),
                        ),
                        TextSpan(text: ' ${l10n['and_word']} '),
                        TextSpan(
                          text: l10n['privacy_policy'],
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _openUrl(_privacyUrl),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (errorText != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Text(
                errorText!,
                style: TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ),
          ],
          const Spacer(),
          AppButton(
            label: l10n['register']!,
            onPressed: isLoading ? null : onRegister,
            isLoading: isLoading,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
```

**Step 6: Commit**

```bash
git add lib/features/auth/widgets/
git commit -m "feat: add register wizard step widgets"
```

---

### Task 9: Rewrite Register Screen as Wizard

**Files:**
- Rewrite: `lib/features/auth/screens/register_screen.dart`

**Step 1: Rewrite register_screen.dart**

```dart
// lib/features/auth/screens/register_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/api_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/mixins/form_mixin.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/register_step_name.dart';
import '../widgets/register_step_birthday.dart';
import '../widgets/register_step_gender.dart';
import '../widgets/register_step_email.dart';
import '../widgets/register_step_terms.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> with FormMixin {
  final _pageController = PageController();
  int _currentStep = 0;
  static const _totalSteps = 5;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  // State
  DateTime? _birthday;
  String? _gender;
  bool _termsAccepted = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Errors
  String? _nameError;
  String? _surnameError;
  String? _emailError;
  String? _passwordError;
  String? _birthdayError;
  String? _genderError;
  String? _termsError;

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtrl.dispose();
    _surnameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      _goToStep(_currentStep + 1);
    }
  }

  bool _validateCurrentStep() {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _nameError = null;
      _surnameError = null;
      _emailError = null;
      _passwordError = null;
      _birthdayError = null;
      _genderError = null;
      _termsError = null;
    });

    switch (_currentStep) {
      case 0: // Name
        bool valid = true;
        if (_nameCtrl.text.trim().isEmpty) {
          setState(() => _nameError = l10n['field_required']);
          valid = false;
        }
        if (_surnameCtrl.text.trim().isEmpty) {
          setState(() => _surnameError = l10n['field_required']);
          valid = false;
        }
        return valid;
      case 1: // Birthday
        if (_birthday == null) {
          setState(() => _birthdayError = l10n['field_required']);
          return false;
        }
        final age = DateTime.now().difference(_birthday!).inDays ~/ 365;
        if (age < 18) {
          setState(() => _birthdayError = l10n['must_be_18']);
          return false;
        }
        return true;
      case 2: // Gender
        if (_gender == null) {
          setState(() => _genderError = l10n['field_required']);
          return false;
        }
        return true;
      case 3: // Email + Password
        bool valid = true;
        final emailErr = emailValidator(_emailCtrl.text);
        if (emailErr != null) {
          setState(() => _emailError = emailErr);
          valid = false;
        }
        final passErr = passwordValidator(_passwordCtrl.text);
        if (passErr != null) {
          setState(() => _passwordError = passErr);
          valid = false;
        }
        return valid;
      case 4: // Terms
        if (!_termsAccepted) {
          setState(() => _termsError = l10n['must_accept_terms']);
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  int _calculateAge() {
    final now = DateTime.now();
    int age = now.year - _birthday!.year;
    if (now.month < _birthday!.month ||
        (now.month == _birthday!.month && now.day < _birthday!.day)) {
      age--;
    }
    return age;
  }

  Future<void> _register() async {
    if (!_validateCurrentStep()) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).register(
            name: _nameCtrl.text.trim(),
            surname: _surnameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            age: _calculateAge(),
            gender: _gender!,
          );
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n['check_email']!)),
        );
        Navigator.of(context).pop();
      }
    } on DioException catch (e) {
      final l10n = AppLocalizations.of(context);
      final apiError = e.error;
      if (apiError is ApiException) {
        final msg = l10n.errorMessage(apiError.code);
        if (apiError.code == 'EMAIL_ALREADY_EXISTS') {
          setState(() => _emailError = msg);
          _goToStep(3); // Go back to email step
        } else {
          setState(() => _termsError = msg);
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _goToStep(_currentStep - 1),
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
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
                    onDateSelected: (d) => setState(() {
                      _birthday = d;
                      _birthdayError = null;
                    }),
                    errorText: _birthdayError,
                    onContinue: _nextStep,
                  ),
                  RegisterStepGender(
                    selectedGender: _gender,
                    onGenderSelected: (g) => setState(() {
                      _gender = g;
                      _genderError = null;
                    }),
                    errorText: _genderError,
                    onContinue: _nextStep,
                  ),
                  RegisterStepEmail(
                    emailCtrl: _emailCtrl,
                    passwordCtrl: _passwordCtrl,
                    emailError: _emailError,
                    passwordError: _passwordError,
                    obscurePassword: _obscurePassword,
                    onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                    onContinue: _nextStep,
                  ),
                  RegisterStepTerms(
                    termsAccepted: _termsAccepted,
                    onTermsChanged: (v) => setState(() {
                      _termsAccepted = v ?? false;
                      _termsError = null;
                    }),
                    errorText: _termsError,
                    isLoading: _isLoading,
                    onRegister: _register,
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
```

**Step 2: Commit**

```bash
git add lib/features/auth/screens/register_screen.dart
git commit -m "feat: rewrite register screen as 5-step wizard"
```

---

### Task 10: Update Login Screen with Inline Errors

**Files:**
- Modify: `lib/features/auth/screens/login_screen.dart`

**Step 1: Update login_screen.dart**

Replace the entire login screen with inline error support. Key changes:
- Add `_loginError` state for general API errors
- Catch `DioException`, extract `ApiException`, show inline error under password field
- Use `AppTextField` and `AppButton` components
- For `INVALID_CREDENTIALS`, show error under password field
- For other errors, show under password field as general error

```dart
// lib/features/auth/screens/login_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/error/api_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/mixins/form_mixin.dart';
import '../../../core/mixins/loading_mixin.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_button.dart';
import '../../../providers/auth_provider.dart';
import '../../../routing/route_names.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with FormMixin, LoadingMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  String? _loginError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _loginError = null);
    if (!validateForm()) return;

    await withLoading(() async {
      try {
        await ref.read(authProvider.notifier).login(
              email: _emailCtrl.text.trim(),
              password: _passwordCtrl.text,
            );
      } on DioException catch (e) {
        final apiError = e.error;
        if (apiError is ApiException && mounted) {
          final l10n = AppLocalizations.of(context);
          setState(() => _loginError = l10n.errorMessage(apiError.code));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n['app_name']!,
                    style: AppTextStyles.displayLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: AppTextStyles.black,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(l10n['welcome_back']!, style: AppTextStyles.bodyLarge),
                  const SizedBox(height: AppSpacing.xxxl),
                  AppTextField(
                    controller: _emailCtrl,
                    label: l10n['email'],
                    validator: emailValidator,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    controller: _passwordCtrl,
                    label: l10n['password'],
                    validator: passwordValidator,
                    obscureText: _obscure,
                    errorText: _loginError,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _login(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.pushNamed(RouteNames.forgotPassword),
                      child: Text(l10n['forgot_password']!),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: l10n['login']!,
                    isLoading: isLoading,
                    onPressed: _login,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n['no_account']!),
                      TextButton(
                        onPressed: () => context.pushNamed(RouteNames.register),
                        child: Text(l10n['register']!),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

**Step 2: Commit**

```bash
git add lib/features/auth/screens/login_screen.dart
git commit -m "feat: update login screen with inline error messages"
```

---

### Task 11: Fix Gender Enum Mismatch + Update FormMixin i18n

**Files:**
- Modify: `lib/core/mixins/form_mixin.dart`

**Step 1: Update form_mixin validators to use i18n**

```dart
// lib/core/mixins/form_mixin.dart
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

mixin FormMixin<T extends StatefulWidget> on State<T> {
  final formKey = GlobalKey<FormState>();

  bool validateForm() => formKey.currentState?.validate() ?? false;

  String? requiredValidator(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context)['field_required'];
    }
    return null;
  }

  String? emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context)['email_required'];
    }
    final regex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!regex.hasMatch(value.trim())) {
      return AppLocalizations.of(context)['email_invalid'];
    }
    return null;
  }

  String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)['password_required'];
    }
    if (value.length < 8) {
      return AppLocalizations.of(context)['password_min'];
    }
    return null;
  }
}
```

**Step 2: Commit**

```bash
git add lib/core/mixins/form_mixin.dart
git commit -m "feat: update form validators to use i18n"
```

---

### Task 12: Clean Up Debug Logs

**Files:**
- Modify: `lib/providers/auth_provider.dart`

**Step 1: Remove debug prints from _checkAuth**

Remove the `debugPrint('[AuthNotifier]...')` lines added during debugging, keep the try-catch for safety.

**Step 2: Commit**

```bash
git add lib/providers/auth_provider.dart
git commit -m "chore: remove auth debug logs"
```
