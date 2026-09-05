import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/core/utils/version_utils.dart';
import 'package:qulo_v2/data/models/app_config_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';

enum UpdateStatus {
  none,
  optionalUpdate,
  forceUpdate,
  maintenance,
}

class AppConfigState {
  final AppConfigModel? config;
  final UpdateStatus status;
  final bool isLoading;
  final String currentVersion;

  const AppConfigState({
    this.config,
    this.status = UpdateStatus.none,
    this.isLoading = false,
    this.currentVersion = '0.0.0',
  });

  AppConfigState copyWith({
    AppConfigModel? config,
    UpdateStatus? status,
    bool? isLoading,
    String? currentVersion,
  }) {
    return AppConfigState(
      config: config ?? this.config,
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      currentVersion: currentVersion ?? this.currentVersion,
    );
  }
}

class AppConfigNotifier extends Notifier<AppConfigState> {
  static const _dismissedKey = 'optional_update_dismissed_at';

  @override
  AppConfigState build() => const AppConfigState();

  Future<UpdateStatus> checkVersion() async {
    state = state.copyWith(isLoading: true);

    try {
      final currentVersion = await ref.read(appInfoManagerProvider).version;

      final result = await ref.read(appConfigRepositoryProvider).getConfig();

      return result.when(
        success: (config) {
          UpdateStatus status;

          if (config.isMaintenance) {
            status = UpdateStatus.maintenance;
          } else if (config.isForceUpdateEnabled &&
              isVersionLessThan(currentVersion, config.minVersion)) {
            status = UpdateStatus.forceUpdate;
          } else if (isVersionLessThan(currentVersion, config.latestVersion)) {
            status = UpdateStatus.optionalUpdate;
          } else {
            status = UpdateStatus.none;
          }

          state = state.copyWith(
            config: config,
            status: status,
            isLoading: false,
            currentVersion: currentVersion,
          );

          return status;
        },
        failure: (_) {
          state = state.copyWith(isLoading: false, status: UpdateStatus.none);
          return UpdateStatus.none;
        },
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, status: UpdateStatus.none);
      return UpdateStatus.none;
    }
  }

  Future<bool> isOptionalUpdateDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedAt = prefs.getInt(_dismissedKey);
    if (dismissedAt == null) return false;

    final dismissedTime = DateTime.fromMillisecondsSinceEpoch(dismissedAt);
    final hoursSince = DateTime.now().difference(dismissedTime).inHours;
    return hoursSince < 24;
  }

  Future<void> dismissOptionalUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dismissedKey, DateTime.now().millisecondsSinceEpoch);
  }
}

final appConfigProvider = NotifierProvider<AppConfigNotifier, AppConfigState>(
  AppConfigNotifier.new,
);
