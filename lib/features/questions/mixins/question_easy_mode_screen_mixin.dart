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
    final appLocale = Localizations.localeOf(context).languageCode;
    selectedLocale =
        AppConstants.supportedQuestionLocales.contains(appLocale)
            ? appLocale
            : 'tr';
  }

  void disposeMixin() {
    // Clean up if needed
  }

  void fetchByCategory(String category) {
    setState(() => selectedCategory = category);
    ref.read(aiSuggestionProvider.notifier).fetchSuggestions(
          category: category,
          locale: selectedLocale,
        );
  }

  void fetchByProfile() {
    setState(() => selectedCategory = null);
    ref.read(aiSuggestionProvider.notifier).fetchSuggestions(
          profileBased: true,
          locale: selectedLocale,
        );
  }

  void selectSuggestion(AiSuggestionModel suggestion) {
    ref.read(navigationServiceProvider).push(
      RouteNames.questionCreate,
      extra: suggestion.withLocale(selectedLocale),
    );
  }

  Future<void> onLanguageChipPressed() async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      builder: (_) => LanguagePickerSheet(
        selectedLanguages: [selectedLocale],
        multiSelect: false,
      ),
    );
    if (mounted && result != null && result.isNotEmpty) {
      setState(() => selectedLocale = result.first);
    }
  }
}
