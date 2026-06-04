import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_icon.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/data/models/ai_suggestion_model.dart';
import 'package:qulo_v2/features/questions/widgets/ai_suggestion_card.dart';

class EasyModeSuggestionsContent extends StatelessWidget {
  const EasyModeSuggestionsContent({
    required this.suggestionsAsync,
    required this.onSelect,
    super.key,
  });

  final AsyncValue<List<AiSuggestionModel>> suggestionsAsync;
  final ValueChanged<AiSuggestionModel> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return suggestionsAsync.when(
      loading: () => const SliverFillRemaining(
        child: Center(child: AppLoadingWidget.large()),
      ),
      error: (e, _) => SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr('error'),
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                e.toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
      data: (suggestions) {
        if (suggestions.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(
                    QIcons.wand,
                    size: 48,
                    color: context.appColors.textHint,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    context.tr('ai_suggest_empty'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          sliver: SliverList.builder(
            itemCount: suggestions.length,
            itemBuilder: (_, i) => AiSuggestionCard(
              suggestion: suggestions[i],
              onSelect: () => onSelect(suggestions[i]),
            ),
          ),
        );
      },
    );
  }
}
