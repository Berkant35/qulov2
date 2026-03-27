import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/data/models/notification_preferences_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';

class NotificationPreferencesState {
  final NotificationPreferencesModel preferences;
  final bool isLoading;

  const NotificationPreferencesState({
    this.preferences = const NotificationPreferencesModel(),
    this.isLoading = false,
  });

  NotificationPreferencesState copyWith({
    NotificationPreferencesModel? preferences,
    bool? isLoading,
  }) {
    return NotificationPreferencesState(
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotificationPreferencesNotifier
    extends Notifier<NotificationPreferencesState> {
  @override
  NotificationPreferencesState build() {
    return const NotificationPreferencesState();
  }

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true);

    final result =
        await ref.read(userRepositoryProvider).getNotificationPreferences();

    result.when(
      success: (data) {
        state = state.copyWith(preferences: data, isLoading: false);
      },
      failure: (_) {
        state = state.copyWith(isLoading: false);
      },
    );
  }

  Future<bool> update(String category, bool value) async {
    final oldPrefs = state.preferences;

    // Optimistic update
    final newPrefs = NotificationPreferencesModel(
      messages: category == 'messages' ? value : oldPrefs.messages,
      matches: category == 'matches' ? value : oldPrefs.matches,
      campaigns: category == 'campaigns' ? value : oldPrefs.campaigns,
    );
    state = state.copyWith(preferences: newPrefs);

    final result = await ref
        .read(userRepositoryProvider)
        .updateNotificationPreferences({category: value});

    return result.when(
      success: (data) {
        state = state.copyWith(preferences: data);
        return true;
      },
      failure: (_) {
        // Rollback
        state = state.copyWith(preferences: oldPrefs);
        return false;
      },
    );
  }
}

final notificationPreferencesProvider = NotifierProvider<
    NotificationPreferencesNotifier, NotificationPreferencesState>(
  NotificationPreferencesNotifier.new,
);
