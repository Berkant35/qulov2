import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Auth olmayan kullanici icin deferred deep link saklama.
/// Deep link handler set eder, GoRouter redirect consume eder.
final pendingDeepLinkProvider = StateProvider<String?>((ref) => null);
