import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/firebase_options.dart';
import 'package:qulo_v2/core/config/supabase_config.dart';
import 'package:qulo_v2/core/error/error_manager.dart';
import 'package:qulo_v2/core/network/network_manager.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/video_manager.dart';
import 'package:qulo_v2/core/services/att_manager.dart';
import 'package:qulo_v2/core/services/meta_events_manager.dart';
import 'package:qulo_v2/providers/onboarding_seen_provider.dart';
import 'package:qulo_v2/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await ErrorManager.init();
  await initSupabase();
  NetworkManager.instance.init();
  await AnalyticsManager.instance.init();
  await MetaEventsManager.instance.init();
  VideoManager.instance.init();

  // Onboarding carousel guard'i router'in ilk frame'de senkron okuyabilmesi
  // icin SharedPreferences'i runApp'ten once preload edip override ile inject et.
  final prefs = await SharedPreferences.getInstance();

  unawaited(_initTracking());

  runApp(
    ProviderScope(
      overrides: [
        onboardingSeenPrefsProvider.overrideWithValue(prefs),
      ],
      child: const QuloApp(),
    ),
  );
}

/// ATT izni — iOS diyaloğu yalnızca uygulama aktifken (ilk frame sonrası)
/// çıkar; `runApp`'ten önce await edilince hiç görünmüyordu. Karar alınınca
/// Meta SDK'ya iletilir (prompt'tan SONRA çağrılmalı). Açılışı bloklamaz;
/// her iki manager hatayı içeride non-fatal loglar, burası son emniyet.
Future<void> _initTracking() async {
  try {
    await AttManager.instance.requestWhenActive();
    await MetaEventsManager.instance.syncAdvertiserTracking();
  } catch (e, stack) {
    AnalyticsManager.instance.logNonFatalError(e, stack, context: 'att_init');
  }
}
