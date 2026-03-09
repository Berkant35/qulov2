import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/network/network_manager.dart';
import 'package:qulo_v2/core/services/image_picker_manager.dart';
import 'package:qulo_v2/core/services/location_manager.dart';
import 'package:qulo_v2/core/services/notification_manager.dart';
import 'package:qulo_v2/core/services/url_launcher_manager.dart';
import 'package:qulo_v2/core/services/version_manager.dart';
import 'package:qulo_v2/core/network/services/auth_service.dart';
import 'package:qulo_v2/core/network/services/user_service.dart';
import 'package:qulo_v2/core/network/services/question_service.dart';
import 'package:qulo_v2/core/network/services/match_service.dart';
import 'package:qulo_v2/core/network/services/quiz_service.dart';
import 'package:qulo_v2/core/network/services/chat_service.dart';
import 'package:qulo_v2/core/network/services/diamond_service.dart';
import 'package:qulo_v2/core/network/services/power_service.dart';
import 'package:qulo_v2/core/network/services/passport_service.dart';
import 'package:qulo_v2/core/network/services/report_service.dart';
import 'package:qulo_v2/core/network/services/subscription_service.dart';
import 'package:qulo_v2/core/network/services/notification_service.dart';
import 'package:qulo_v2/core/network/services/app_config_service.dart';
import 'package:qulo_v2/data/repositories/repositories.dart';

// ─── Core Services ───
final imagePickerManagerProvider = Provider<ImagePickerManager>(
  (_) => ImagePickerManager.instance,
);
final locationManagerProvider = Provider<LocationManager>(
  (_) => LocationManager.instance,
);
final urlLauncherManagerProvider = Provider<UrlLauncherManager>(
  (_) => UrlLauncherManager.instance,
);
final notificationManagerProvider = Provider<NotificationManager>(
  (_) => NotificationManager.instance,
);
final versionManagerProvider = Provider<VersionManager>(
  (_) => VersionManager.instance,
);

// ─── NetworkManager ───
final networkManagerProvider = Provider<NetworkManager>(
  (_) => NetworkManager.instance,
);

// ─── Retrofit Services ───
final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.read(networkManagerProvider).dio),
);
final userServiceProvider = Provider<UserService>(
  (ref) => UserService(ref.read(networkManagerProvider).dio),
);
final questionServiceProvider = Provider<QuestionService>(
  (ref) => QuestionService(ref.read(networkManagerProvider).dio),
);
final matchServiceProvider = Provider<MatchService>(
  (ref) => MatchService(ref.read(networkManagerProvider).dio),
);
final quizServiceProvider = Provider<QuizService>(
  (ref) => QuizService(ref.read(networkManagerProvider).dio),
);
final chatServiceProvider = Provider<ChatService>(
  (ref) => ChatService(ref.read(networkManagerProvider).dio),
);
final diamondServiceProvider = Provider<DiamondService>(
  (ref) => DiamondService(ref.read(networkManagerProvider).dio),
);
final powerServiceProvider = Provider<PowerService>(
  (ref) => PowerService(ref.read(networkManagerProvider).dio),
);
final passportServiceProvider = Provider<PassportService>(
  (ref) => PassportService(ref.read(networkManagerProvider).dio),
);
final reportServiceProvider = Provider<ReportService>(
  (ref) => ReportService(ref.read(networkManagerProvider).dio),
);
final subscriptionServiceProvider = Provider<SubscriptionService>(
  (ref) => SubscriptionService(ref.read(networkManagerProvider).dio),
);
final notificationRetrofitServiceProvider =
    Provider<NotificationRetrofitService>(
  (ref) => NotificationRetrofitService(ref.read(networkManagerProvider).dio),
);
final appConfigRetrofitServiceProvider = Provider<AppConfigRetrofitService>(
  (ref) => AppConfigRetrofitService(ref.read(networkManagerProvider).dio),
);

// ─── Repositories ───
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.read(authServiceProvider)),
);
final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(
    ref.read(userServiceProvider),
    ref.read(networkManagerProvider),
  ),
);
final questionRepositoryProvider = Provider<QuestionRepository>(
  (ref) => QuestionRepository(
    ref.read(questionServiceProvider),
    ref.read(networkManagerProvider),
  ),
);
final matchRepositoryProvider = Provider<MatchRepository>(
  (ref) => MatchRepository(ref.read(matchServiceProvider)),
);
final quizRepositoryProvider = Provider<QuizRepository>(
  (ref) => QuizRepository(ref.read(quizServiceProvider)),
);
final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.read(chatServiceProvider)),
);
final diamondRepositoryProvider = Provider<DiamondRepository>(
  (ref) => DiamondRepository(ref.read(diamondServiceProvider)),
);
final powerRepositoryProvider = Provider<PowerRepository>(
  (ref) => PowerRepository(ref.read(powerServiceProvider)),
);
final passportRepositoryProvider = Provider<PassportRepository>(
  (ref) => PassportRepository(
    ref.read(passportServiceProvider),
    ref.read(networkManagerProvider),
  ),
);
final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(ref.read(reportServiceProvider)),
);
final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => SubscriptionRepository(ref.read(subscriptionServiceProvider)),
);
final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) =>
      NotificationRepository(ref.read(notificationRetrofitServiceProvider)),
);
final appConfigRepositoryProvider = Provider<AppConfigRepository>(
  (ref) => AppConfigRepository(ref.read(appConfigRetrofitServiceProvider)),
);
