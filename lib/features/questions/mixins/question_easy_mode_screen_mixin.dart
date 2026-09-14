import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/widgets/language_picker_sheet.dart';
import 'package:qulo_v2/data/models/ai_suggestion_model.dart';
import 'package:qulo_v2/features/questions/screens/question_easy_mode_screen.dart';
import 'package:qulo_v2/providers/ai_suggestion_provider.dart';
import 'package:qulo_v2/routing/route_names.dart';

mixin QuestionEasyModeScreenMixin on ConsumerState<QuestionEasyModeScreen> {
  String? selectedCategory;
  late String selectedLocale;
  bool _localeInitialized = false;

  void initMixin() {
    if (_localeInitialized) return;
    _localeInitialized = true;
    selectedLocale = AppConstants.defaultQuestionLocale(
      Localizations.localeOf(context).languageCode,
    );
  }

  void disposeMixin() {
    // Clean up if needed
  }

  void fetchByCategory(String category) {
    setState(() => selectedCategory = category);
    ref
        .read(aiSuggestionProvider.notifier)
        .fetchSuggestions(category: category, locale: selectedLocale);
  }

  void fetchByProfile() {
    setState(() => selectedCategory = null);
    ref
        .read(aiSuggestionProvider.notifier)
        .fetchSuggestions(profileBased: true, locale: selectedLocale);
  }

  void selectSuggestion(AiSuggestionModel suggestion) {
    ref
        .read(navigationServiceProvider)
        .push(
          RouteNames.questionCreate,
          extra: suggestion.withLocale(selectedLocale),
        );
  }

  Future<void> onLanguageChipPressed() async {
    final picked = await LanguagePickerSheet.pickOne(
      ref.read(navigationServiceProvider),
      selectedLocale,
    );
    if (mounted && picked != null) setState(() => selectedLocale = picked);
  }
}
