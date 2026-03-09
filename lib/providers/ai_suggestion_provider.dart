import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/data/models/ai_suggestion_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';

class AiSuggestionNotifier extends AsyncNotifier<List<AiSuggestionModel>> {
  @override
  Future<List<AiSuggestionModel>> build() async => [];

  Future<void> fetchSuggestions({
    String? category,
    bool profileBased = false,
    String locale = 'tr',
  }) async {
    state = const AsyncLoading();
    final result = await ref.read(questionRepositoryProvider).getAiSuggestions({
      if (category != null) 'category': category,
      'profile_based': profileBased,
      'locale': locale,
      'count': 5,
    });
    state = result.when(
      success: (data) {
        final list = (data['suggestions'] as List?)
                ?.map((e) => AiSuggestionModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        return AsyncData(list);
      },
      failure: (f) => AsyncError(f, StackTrace.current),
    );
  }

  void clear() {
    state = const AsyncData([]);
  }
}

final aiSuggestionProvider =
    AsyncNotifierProvider<AiSuggestionNotifier, List<AiSuggestionModel>>(
  AiSuggestionNotifier.new,
);
