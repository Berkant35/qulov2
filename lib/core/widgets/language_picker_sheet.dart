import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/app_constants.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

/// Tek dil secimi (uygulama dili, soru dili). Coklu secim dali hicbir cagri
/// yerinde kullanilmiyordu; eslesme dilleri tek kaynak sunucudaki
/// `set_user_languages` RPC'sidir, bu sayfa ona dokunmaz.
class LanguagePickerSheet extends StatefulWidget {
  final String selected;

  const LanguagePickerSheet({super.key, required this.selected});

  /// Tek acilis yolu. Secim yapilmadan kapatilirsa null doner.
  /// 18 cip kucuk ekranda tavani astigi icin yukseklik faktoru burada sabitlenir;
  /// cagri yerleri (ayarlar, giris, soru olusturma, kolay mod) bunu bilmek zorunda kalmaz.
  static Future<String?> pickOne(NavigationService nav, String current) =>
      nav.showAppBottomSheet<String>(
        CustomBottomSheet(
          name: 'language_picker',
          maxHeightFactor: AppBottomSheet.tallHeightFactor,
          builder: (_) => LanguagePickerSheet(selected: current),
        ),
      );

  @override
  State<LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<LanguagePickerSheet> {
  late String _selected = widget.selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('language_picker_select_one'),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          // 18 çip küçük ekranda sayfa tavanını aşar: çipler kaydırılır, Kaydet sabit kalır.
          Flexible(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: AppConstants.supportedQuestionLocales.map((locale) {
                  final isSelected = _selected == locale;
                  final flag = AppConstants.localeFlagEmojis[locale] ?? '';
                  return FilterChip(
                    label: Text('$flag ${context.tr('locale_$locale')}'),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selected = locale),
                    selectedColor: context.appColors.primarySurface,
                    checkmarkColor: context.appColors.primary,
                    side: BorderSide(
                      color: isSelected
                          ? context.appColors.primary
                          : context.appColors.border,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_selected),
            style: FilledButton.styleFrom(
              backgroundColor: context.appColors.primary,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
            child: Text(context.tr('save')),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
