import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/core/widgets/q_icon.dart';

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
              failure is ServerFailure && (failure as ServerFailure).code == 'NO_QUESTIONS'
                  ? context.tr('quiz_no_questions')
                  : context.tr('quiz_start_error'),
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
