import 'dart:async';

import 'package:flutter/widgets.dart';

/// Uygulamanın aktif (ön planda) olmasını bekleyen tek kullanımlık kapı.
///
/// iOS'ta bazı sistem diyalogları (ATT gibi) uygulama `UIApplicationStateActive`
/// değilken sessizce başarısız olur; `runApp`'ten önce çağrılan kod bu kapıyla
/// ilk `resumed`'a ertelenir. Zaten aktifse hemen döner.
abstract final class AppLifecycleGate {
  static Future<void> whenResumed() {
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      return Future<void>.value();
    }
    final completer = Completer<void>();
    late final AppLifecycleListener listener;
    listener = AppLifecycleListener(
      onResume: () {
        listener.dispose();
        if (!completer.isCompleted) completer.complete();
      },
    );
    return completer.future;
  }
}
