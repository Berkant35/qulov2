import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/overlay_queue_service.dart';
import 'package:qulo_v2/core/services/overlay_request.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/discover/screens/discover_screen.dart';
import 'package:qulo_v2/features/pref_consent/widgets/pref_consent_sheet.dart';
import 'package:qulo_v2/providers/user_provider.dart';

/// Rızasız alınmış eşleşme tercihi için bir kerelik açık rıza sayfası (KVKK m.6).
abstract final class PrefConsentPrompt {
  static const String overlayId = 'pref_consent';
  static const int priority = OverlayPriority.consent;

  /// 2.0.14 ve öncesinde seçilmiş ya da destekle değişmiş tercih; sunucu durumu tek kaynak.
  static bool shouldPrompt(UserModel? user) => user?.needsPrefConsent ?? false;

  static OverlayRequest request(Future<void> Function() show) =>
      OverlayRequest(id: overlayId, priority: priority, show: show);
}

/// Discover'a girişte rıza sayfasını overlay kuyruğuna sokar; ekran başına bir kez.
mixin PrefConsentPromptMixin on ConsumerState<DiscoverScreen> {
  bool _prefConsentTried = false;

  void initPrefConsentPrompt() {
    ref.listenManual<AsyncValue<UserModel?>>(userProvider, (_, next) {
      if (_prefConsentTried || !PrefConsentPrompt.shouldPrompt(next.valueOrNull)) return;
      _prefConsentTried = true;
      OverlayQueueService.instance.enqueue(PrefConsentPrompt.request(_showPrefConsentSheet));
    }, fireImmediately: true);
  }

  Future<void> _showPrefConsentSheet() async {
    // Kuyruk boşsa `show` initState içinde senkron çağrılır; sheet frame bitince açılır.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await ref.read(navigationServiceProvider).showAppBottomSheet<void>(
          CustomBottomSheet(
            name: 'pref_consent',
            isDismissible: false,
            enableDrag: false,
            maxHeightFactor: AppBottomSheet.tallHeightFactor,
            builder: (_) => const PrefConsentSheet(),
          ),
        );
  }

  void disposePrefConsentPrompt() => OverlayQueueService.instance.cancel(PrefConsentPrompt.overlayId);
}
