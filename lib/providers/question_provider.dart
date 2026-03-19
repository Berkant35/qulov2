import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/question_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

class QuestionNotifier extends AsyncNotifier<List<QuestionModel>> {
  @override
  Future<List<QuestionModel>> build() async => [];

  Future<void> fetchQuestions() async {
    state = const AsyncLoading();
    final result = await ref.read(questionRepositoryProvider).getMyQuestions();
    state = result.when(
      success: (data) => AsyncData(data),
      failure: (f) => AsyncError(f, StackTrace.current),
    );
  }

  Future<Result<QuestionModel>> createQuestion(Map<String, dynamic> data) async {
    final result = await ref.read(questionRepositoryProvider).createQuestion(data);
    result.when(
      success: (_) {
        fetchQuestions();
        ref.read(userProvider.notifier).fetchMe();
      },
      failure: (f) => dev.log('createQuestion failed: $f', name: 'QuestionNotifier'),
    );
    return result;
  }

  Future<Result<QuestionModel>> updateQuestion(int orderNum, Map<String, dynamic> data) async {
    final result = await ref.read(questionRepositoryProvider).updateQuestion(orderNum, data);
    result.when(
      success: (_) => fetchQuestions(),
      failure: (f) => dev.log('updateQuestion failed: $f', name: 'QuestionNotifier'),
    );
    return result;
  }

  Future<Result<void>> deleteQuestion(int orderNum) async {
    final result = await ref.read(questionRepositoryProvider).deleteQuestion(orderNum);
    result.when(
      success: (_) {
        fetchQuestions();
        ref.read(userProvider.notifier).fetchMe();
      },
      failure: (f) => dev.log('deleteQuestion failed: $f', name: 'QuestionNotifier'),
    );
    return result;
  }
}

final questionProvider = AsyncNotifierProvider<QuestionNotifier, List<QuestionModel>>(QuestionNotifier.new);
