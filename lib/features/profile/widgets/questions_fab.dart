import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/widgets/app_icon.dart';
import 'package:qulo_v2/data/models/question_model.dart';
import 'package:qulo_v2/providers/daily_stats_provider.dart';
import 'package:qulo_v2/providers/question_provider.dart';

class QuestionsFab extends ConsumerWidget {
  final VoidCallback onPressed;

  const QuestionsFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questions = ref.watch(questionProvider).valueOrNull ?? <QuestionModel>[];
    final dailyStats = ref.watch(dailyStatsProvider).valueOrNull;
    final questionsLimit = dailyStats?.questionsLimit ?? 4;
    final isAtLimit = questions.length >= questionsLimit;

    return FloatingActionButton(
      backgroundColor: isAtLimit
          ? context.appColors.textHint
          : context.appColors.primaryDark,
      onPressed: onPressed,
      child: isAtLimit
          ? AppIcon(QIcons.lock, size: 22, color: Colors.white)
          : const Icon(Icons.add),
    );
  }
}
