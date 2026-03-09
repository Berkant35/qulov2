import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/providers/quiz_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/features/quiz/widgets/answer_button.dart';
import 'package:qulo_v2/features/quiz/widgets/power_bar.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_timer.dart';
import 'package:qulo_v2/features/quiz/widgets/quiz_result_dialog.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String targetId;
  const QuizScreen({super.key, required this.targetId});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  final _stopwatch = Stopwatch();
  int _totalTimeSpent = 0;
  int _totalCorrect = 0;
  int _powersUsed = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(quizProvider.notifier).startSession(widget.targetId);
      _startQuestionTimer();
    });
  }

  void _startQuestionTimer() {
    _stopwatch.reset();
    _stopwatch.start();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    ref.read(quizProvider.notifier).reset();
    super.dispose();
  }

  Future<void> _answer(int index, {String? powerUsed}) async {
    _stopwatch.stop();
    final timeSpent = _stopwatch.elapsedMilliseconds ~/ 1000;
    _totalTimeSpent += timeSpent;

    if (powerUsed != null) _powersUsed++;

    final result = await ref.read(quizProvider.notifier).answer(
          index,
          powerUsed: powerUsed,
          timeSpent: timeSpent,
        );
    if (!mounted) return;
    result.when(
      success: (data) {
        if (data.isCorrect == true) _totalCorrect++;

        if (data.sessionStatus == 'COMPLETED') {
          _showGamifiedResult(matched: true);
        } else if (data.sessionStatus == 'FAILED') {
          _showGamifiedResult(matched: false);
        } else if (data.awaitingAnswer != true) {
          ref.read(quizProvider.notifier).fetchCurrentQuestion();
          _startQuestionTimer();
        }
      },
      failure: (_) {},
    );
  }

  String _determineBadge() {
    final quiz = ref.read(quizProvider);
    final total = quiz.totalQuestions;

    // Flawless: all correct, no powers
    if (_totalCorrect == total && _powersUsed == 0) return 'flawless';
    // Speed solver: average < 10s per question
    if (total > 0 && (_totalTimeSpent / total) < 10) return 'speed_solver';
    // Power master: used 2+ powers
    if (_powersUsed >= 2) return 'power_master';
    // Determined: completed but not perfect
    if (_totalCorrect > 0) return 'determined';
    return 'none';
  }

  Future<void> _showGamifiedResult({required bool matched}) async {
    final nav = ref.read(navigationServiceProvider);
    final quiz = ref.read(quizProvider);
    final badge = _determineBadge();

    await nav.showAppDialog(
      CustomDialog(
        name: 'quiz_result',
        barrierDismissible: false,
        builder: (_) => QuizResultContent(
          matched: matched,
          totalCorrect: _totalCorrect,
          totalQuestions: quiz.totalQuestions,
          totalTimeSpent: _totalTimeSpent,
          powersUsed: _powersUsed,
          performanceBadge: badge,
          onStartChat: matched
              ? () {
                  nav.closeOverlay();
                  nav.pop();
                  nav.go(RouteNames.matches);
                }
              : null,
          onGoBack: () {
            nav.closeOverlay();
            if (mounted) nav.pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quiz = ref.watch(quizProvider);
    final theme = Theme.of(context);
    final question = quiz.currentQuestion;

    return AppScaffold(
      title: question != null
          ? '${question.questionNumber}/${question.totalQuestions}'
          : '',
      leading: IconButton(
        icon: QIcon(QIcons.icX, size: 24),
        onPressed: () => ref.read(navigationServiceProvider).pop(),
      ),
      padding: EdgeInsets.zero,
      isLoading: quiz.isLoading || question == null,
      body: quiz.isLoading || question == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  QuizTimer(
                    seconds: question.timeLimitSeconds,
                    onTimeout: () => _answer(0),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    question.questionText,
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  ...question.answers.map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: AnswerButton(
                          text: a.text,
                          onTap: () => _answer(a.index),
                        ),
                      )),
                  const Spacer(),
                  PowerBar(
                    sessionId: quiz.sessionId!,
                    hasHint: question.hasHint,
                    onPowerUsed: (power) => _answer(0, powerUsed: power),
                  ),
                ],
              ),
            ),
    );
  }
}
