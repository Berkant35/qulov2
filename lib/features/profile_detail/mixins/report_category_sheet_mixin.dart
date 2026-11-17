import 'package:flutter/material.dart';
import 'package:qulo_v2/features/profile_detail/models/report_category_option.dart';

/// [ReportCategorySheet] listesini kurar. Sunucu değerleri `report.validator.ts`
/// ve prod `report_category` enum'u ile aynı olmalı.
mixin ReportCategorySheetMixin {
  static const List<ReportCategoryOption> _categories = [
    ReportCategoryOption(value: 'INAPPROPRIATE_CONTENT', l10nKey: 'report_cat_inappropriate', icon: Icons.warning_amber_outlined),
    ReportCategoryOption(value: 'FAKE_PROFILE', l10nKey: 'report_cat_fake', icon: Icons.person_off_outlined),
    ReportCategoryOption(value: 'SPAM', l10nKey: 'report_cat_spam', icon: Icons.mark_email_unread_outlined),
    ReportCategoryOption(value: 'HARASSMENT', l10nKey: 'report_cat_harassment', icon: Icons.sentiment_very_dissatisfied_outlined),
    ReportCategoryOption(value: 'UNDERAGE', l10nKey: 'report_cat_underage', icon: Icons.child_care_outlined),
    ReportCategoryOption(value: 'SCAM', l10nKey: 'report_cat_scam', icon: Icons.money_off_outlined),
    ReportCategoryOption(value: 'OFFENSIVE_PHOTOS', l10nKey: 'report_cat_offensive_photos', icon: Icons.hide_image_outlined),
    ReportCategoryOption(value: 'THREATENING', l10nKey: 'report_cat_threatening', icon: Icons.gavel_outlined),
    ReportCategoryOption(value: 'IMPERSONATION', l10nKey: 'report_cat_impersonation', icon: Icons.masks_outlined),
    ReportCategoryOption(value: 'OTHER', l10nKey: 'report_cat_other', icon: Icons.more_horiz),
  ];

  static const _mediaCategory = ReportCategoryOption(
    value: 'INAPPROPRIATE_MEDIA',
    l10nKey: 'report_cat_inappropriate_media',
    icon: Icons.perm_media_outlined,
  );

  /// Medyalı soruda "Uygunsuz medya" ilk sıradakinin hemen ardından gelir.
  List<ReportCategoryOption> categoriesFor({required bool includeMedia}) =>
      includeMedia
          ? [_categories.first, _mediaCategory, ..._categories.skip(1)]
          : _categories;
}
