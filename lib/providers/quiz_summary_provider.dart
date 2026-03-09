import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/data/models/quiz_summary_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';

final quizSummaryProvider =
    FutureProvider.family<QuizSummaryModel?, String>((ref, matchId) async {
  final result = await ref.read(quizRepositoryProvider).getMatchQuizSummary(matchId);
  return result.when(
    success: (data) => data,
    failure: (_) => null,
  );
});
