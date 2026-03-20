import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qulo_v2/data/models/economy_config_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';

final economyConfigProvider =
    NotifierProvider<EconomyConfigNotifier, EconomyConfig>(
  EconomyConfigNotifier.new,
);

class EconomyConfigNotifier extends Notifier<EconomyConfig> {
  static const _cacheKey = 'economy_config_cache';

  @override
  EconomyConfig build() => EconomyConfig.fallback;

  Future<void> fetch() async {
    final repo = ref.read(appConfigRepositoryProvider);
    final result = await repo.getEconomyConfig();

    await result.when(
      success: (response) async {
        state = response.config;
        await _saveToCache(response.config);
      },
      failure: (_) async {
        final cached = await _loadFromCache();
        if (cached != null) {
          state = cached;
        }
        _retryInBackground();
      },
    );
  }

  Future<void> _saveToCache(EconomyConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(config.toJson()));
  }

  Future<EconomyConfig?> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached == null) return null;
    try {
      return EconomyConfig.fromJson(
        jsonDecode(cached) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _retryInBackground() async {
    try {
      await Future.delayed(const Duration(seconds: 30));
      final repo = ref.read(appConfigRepositoryProvider);
      final result = await repo.getEconomyConfig();
      result.when(
        success: (response) async {
          state = response.config;
          await _saveToCache(response.config);
        },
        failure: (_) {},
      );
    } catch (_) {
      // Silently ignore retry failures
    }
  }
}
