import 'package:flutter/widgets.dart';
import 'package:qulo_v2/core/services/admob_manager.dart';
import 'package:qulo_v2/core/services/att_manager.dart';
import 'package:qulo_v2/core/services/native_ad_handle.dart';

class FakeAdHandle implements NativeAdHandle {
  int disposeCount = 0;
  bool get disposed => disposeCount > 0;

  @override
  Widget build() => const SizedBox.shrink();

  @override
  void dispose() => disposeCount++;
}

/// AdMob SDK'sı yerine: çağrıları sayar, hata/onay senaryosu verir.
class FakeAdMob implements AdMobManager {
  bool consentGranted = true;
  Object? loadError;
  int readyCalls = 0;
  int loadCalls = 0;
  final handles = <FakeAdHandle>[];
  final nonPersonalizedRequests = <bool>[];

  @override
  Future<bool> ensureReady() async {
    readyCalls++;
    return consentGranted;
  }

  @override
  Future<NativeAdHandle> loadNativeAd({
    required bool nonPersonalized,
    required NativeAdStyle style,
    VoidCallback? onImpression,
    VoidCallback? onClicked,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    loadCalls++;
    nonPersonalizedRequests.add(nonPersonalized);
    if (loadError != null) throw loadError!;
    final h = FakeAdHandle();
    handles.add(h);
    return h;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeAdMob.${invocation.memberName}');
}

class FakeAtt implements AttManager {
  FakeAtt({this.authorized = true});
  final bool authorized;

  @override
  Future<bool> isAuthorized() async => authorized;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeAtt.${invocation.memberName}');
}
