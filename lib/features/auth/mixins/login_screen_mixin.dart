import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/mixins/form_mixin.dart';
import 'package:qulo_v2/core/mixins/loading_mixin.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/widgets/language_picker_sheet.dart';
import 'package:qulo_v2/features/auth/mixins/social_auth_mixin.dart';
import 'package:qulo_v2/features/auth/screens/login_screen.dart';
import 'package:qulo_v2/features/auth/widgets/staggered_column.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/providers/locale_provider.dart';

mixin LoginScreenMixin
    on
        ConsumerState<LoginScreen>,
        FormMixin<LoginScreen>,
        LoadingMixin<LoginScreen>,
        SocialAuthMixin<LoginScreen> {
  final emailCtrl = TextEditingController(
    text: kDebugMode
        ? const String.fromEnvironment('DEBUG_EMAIL', defaultValue: '')
        : null,
  );
  final passwordCtrl = TextEditingController(
    text: kDebugMode
        ? const String.fromEnvironment('DEBUG_PASSWORD', defaultValue: '')
        : null,
  );
  bool obscure = true;
  String? loginError;
  String appVersion = '';

  final staggeredKey = GlobalKey<StaggeredColumnState>();

  void initMixin() {
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => appVersion = info.version);
    });
  }

  void disposeMixin() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
  }

  void toggleObscure() => setState(() => obscure = !obscure);

  void onVideoInitialized() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      staggeredKey.currentState?.forward();
    });
  }

  Future<void> showLanguagePicker() async {
    final currentLocale = ref.read(localeProvider).languageCode;
    final result = await ref
        .read(navigationServiceProvider)
        .showAppBottomSheet<List<String>>(
          CustomBottomSheet(
            name: 'language_picker',
            builder: (_) => LanguagePickerSheet(
              selectedLanguages: [currentLocale],
              multiSelect: false,
            ),
          ),
        );
    if (result != null && result.isNotEmpty) {
      ref.read(localeProvider.notifier).setLocale(Locale(result.first));
    }
  }

  Future<void> login() => withLoading(() async {
        setState(() => loginError = null);
        if (!validateForm()) return;
        final result = await ref
            .read(authProvider.notifier)
            .login(email: emailCtrl.text.trim(), password: passwordCtrl.text);
        if (!mounted) return;
        result.when(
          success: (_) {},
          failure: (f) {
            final errorCode = errorCodeOf(f) ?? 'UNKNOWN';
            setState(() => loginError = context.l10n.errorMessage(errorCode));
          },
        );
      });

  @override
  void onSocialAuthError(String errorCode) {
    setState(() => loginError = context.l10n.errorMessage(errorCode));
  }
}
