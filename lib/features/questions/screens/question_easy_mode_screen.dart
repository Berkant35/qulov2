import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/features/questions/mixins/question_easy_mode_screen_mixin.dart';
import 'package:qulo_v2/features/questions/widgets/easy_mode_category_section.dart';
import 'package:qulo_v2/features/questions/widgets/easy_mode_suggestions_content.dart';
import 'package:qulo_v2/providers/ai_suggestion_provider.dart';

class QuestionEasyModeScreen extends ConsumerStatefulWidget {
  const QuestionEasyModeScreen({super.key});

  @override
  ConsumerState<QuestionEasyModeScreen> createState() =>
      _QuestionEasyModeScreenState();
}

class _QuestionEasyModeScreenState
    extends ConsumerState<QuestionEasyModeScreen>
    with QuestionEasyModeScreenMixin {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    initMixin();
  }

  @override
  void dispose() {
    disposeMixin();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suggestionsAsync = ref.watch(aiSuggestionProvider);

    return AppScaffold(
      title: context.tr('ai_suggest_title'),
      padding: EdgeInsets.zero,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: EasyModeCategorySection(
              selectedLocale: selectedLocale,
              selectedCategory: selectedCategory,
              onLanguageChipPressed: onLanguageChipPressed,
              onCategorySelected: fetchByCategory,
              onProfileBased: fetchByProfile,
            ),
          ),
          SliverToBoxAdapter(
            child: Divider(height: 1, color: context.appColors.border),
          ),
          EasyModeSuggestionsContent(
            suggestionsAsync: suggestionsAsync,
            onSelect: selectSuggestion,
          ),
        ],
      ),
    );
  }
}
