import 'package:flutter/widgets.dart';

/// Şikâyet kategorisi satırı: sunucu değeri (`reports.category`), çeviri anahtarı, ikon.
class ReportCategoryOption {
  final String value;
  final String l10nKey;
  final IconData icon;

  const ReportCategoryOption({
    required this.value,
    required this.l10nKey,
    required this.icon,
  });
}
