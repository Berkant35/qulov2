import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';
import 'package:qulo_v2/features/quiz/quiz_retry_lock.dart';
import 'package:qulo_v2/providers/match_provider.dart';

class QuizErrorView extends StatelessWidget {
  final AppFailure failure;
  final VoidCallback onGoBack;

  const QuizErrorView({
    super.key,
    required this.failure,
    required this.onGoBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: '',
      leading: IconButton(
        icon: QIcon(QIcons.icX, size: 24),
        onPressed: onGoBack,
      ),
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.appColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              quizStartErrorMessage(failure, context.l10n),
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: onGoBack,
              child: Text(context.tr('quiz_go_back')),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quiz başlatılamadı: erişilemeyen profil / soru yok / kilitli hedef (409 QUIZ_RETRY_LOCKED) / genel.
String quizStartErrorMessage(AppFailure failure, AppLocalizations l10n) {
  if (isNotCompatibleFailure(failure)) return l10n.get('error_not_compatible');
  if (failure is ServerFailure && failure.code == 'NO_QUESTIONS') return l10n.get('quiz_no_questions');
  return quizRetryLockMessage(failure, l10n) ?? l10n.get('quiz_start_error');
}
