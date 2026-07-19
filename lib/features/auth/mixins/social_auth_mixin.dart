import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/mixins/loading_mixin.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/providers/auth_provider.dart';

/// Social login (Google/Apple) davranisini login VE landing ekranlarinda
/// paylasir. Ekrana ozgu hata gosterimi [onSocialAuthError] ile delege edilir.
mixin SocialAuthMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T>, LoadingMixin<T> {
  void onSocialAuthError(String errorCode);

  String? errorCodeOf(AppFailure failure) => switch (failure) {
        ServerFailure(:final code) => code,
        NetworkFailure() => 'NETWORK_ERROR',
        TimeoutFailure() => 'TIMEOUT',
        _ => null,
      };

  Future<void> socialLogin(String provider) => withLoading(() async {
        final result =
            await ref.read(authProvider.notifier).socialLogin(provider);
        if (!mounted) return;
        result.when(
          success: (_) {},
          failure: (f) {
            if (f.message?.contains('cancelled') == true) return;
            final code = errorCodeOf(f);
            if (code != null) onSocialAuthError(code);
          },
        );
      });
}
