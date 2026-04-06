import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:qulo_v2/firebase_options.dart';
import 'package:qulo_v2/core/config/supabase_config.dart';
import 'package:qulo_v2/core/error/error_manager.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/video_manager.dart';
import 'package:qulo_v2/core/network/network_manager.dart';
import 'package:qulo_v2/providers/auth_provider.dart';
import 'package:qulo_v2/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  VideoManager.instance.init();
  await ErrorManager.init();
  await AnalyticsManager.instance.init();
  await initSupabase();

  final container = ProviderContainer();

  NetworkManager.instance.init(
    onForceLogout: () {
      container.read(authProvider.notifier).forceLogout();
    },
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const QuloApp(),
    ),
  );
}
