import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/providers/user_provider.dart';

/// Rainbow görünürlüğü tek kaynaktan (sunucu `rainbow_enabled`) — istemci kendi karar vermez.
extension RainbowFlagRef on WidgetRef {
  bool watchRainbowEnabled() => watch(userProvider.select((u) => u.valueOrNull?.rainbowEnabled ?? false));

  /// "Hediye kartlarım": Rainbow kapalı olsa da talebi olan (evine dönen turist) görür.
  bool watchGiftCardsVisible() => watch(userProvider.select((u) {
        final user = u.valueOrNull;
        return user != null && (user.rainbowEnabled || user.hasRewardRedemptions);
      }));
}
