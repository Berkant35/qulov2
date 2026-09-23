import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/services/overlay_queue_service.dart';
import 'package:qulo_v2/core/services/overlay_request.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/discover/screens/discover_screen.dart';
import 'package:qulo_v2/features/discover/widgets/acquisition_sheet.dart';
import 'package:qulo_v2/providers/user_provider.dart';

/// "Bizi nereden duydun?" anketinin ne zaman ve hangi sırayla sorulacağı.
abstract final class AcquisitionPrompt {
  static const String overlayId = 'acquisition';

  /// Coach-mark turundan (onboarding) ÖNCE: tek dokunuşluk soru, sonra tur.
  static const int priority = OverlayPriority.survey;

  /// Kullanıcı yüklendi ve henüz cevaplamadıysa sorulur; sunucu bayrağı tek
  /// kaynak (atlayan da cevaplamış sayılır, tekrar sorulmaz).
  static bool shouldPrompt(UserModel? user) =>
      user != null && !user.acquisitionAnswered;

  static OverlayRequest request(Future<void> Function() show) =>
      OverlayRequest(id: overlayId, priority: priority, show: show);
}

/// Discover'a girişte anketi overlay kuyruğuna sokar.
///
/// Anket vaktiyle profil ekranındaydı (coach-mark çakışması yüzünden
/// Discover'dan kaçırılmıştı); profile hiç girmeyen kullanıcı hiç görmüyordu:
/// 20–23 Eyl'de 7 kayıttan 7'si boştu. Kuyruk çakışmayı sıralayarak çözer;
/// id idempotent, ekran başına bir kez denenir.
mixin AcquisitionPromptMixin on ConsumerState<DiscoverScreen> {
  bool _acquisitionTried = false;

  void initAcquisitionPrompt() {
    ref.listenManual<AsyncValue<UserModel?>>(userProvider, (_, next) {
      if (_acquisitionTried || !AcquisitionPrompt.shouldPrompt(next.valueOrNull)) {
        return;
      }
      _acquisitionTried = true;
      OverlayQueueService.instance
          .enqueue(AcquisitionPrompt.request(_showAcquisitionSheet));
    }, fireImmediately: true);
  }

  Future<void> _showAcquisitionSheet() async {
    // Kuyruk boşsa `show` initState içinde senkron çağrılır; sheet frame bitince açılır.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await ref.read(navigationServiceProvider).showAppBottomSheet<void>(
          CustomBottomSheet(
            name: 'acquisition',
            isDismissible: false,
            enableDrag: false,
            maxHeightFactor: AppBottomSheet.tallHeightFactor,
            builder: (_) => const AcquisitionSheet(),
          ),
        );
  }

  void disposeAcquisitionPrompt() =>
      OverlayQueueService.instance.cancel(AcquisitionPrompt.overlayId);
}
