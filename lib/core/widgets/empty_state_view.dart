import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

/// Bos/hata durumlarinin ortak iskeleti: ikon → baslik → aciklama → eylem.
///
/// Neden var: ayni `Center > Padding(pagePadding) > Column(min)` yapisi dort
/// ayri dosyada kopyalanmisti ve aralari acilmaya baslamisti (buton yuksekligi
/// bir yerde 48, digerinde 52). Iskeleti tek yerde tutuyoruz; eylem alanini
/// cagiran doldurur, cunku her ekranin eylemi farkli (buton, slider karti,
/// ipucu bagi).
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.children = const [],
  });

  /// Ust ikon — cagiran `QIcon` ya da `Icon` gecebilir (renk/tip ekrana ozel).
  final Widget icon;
  final String title;

  /// Basligin altindaki aciklama satiri; yoksa bosluk da eklenmez.
  final String? message;

  /// Aciklamadan sonra gelen icerik: buton, kart, ipucu baglari.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: context.appColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (children.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              ...children,
            ],
          ],
        ),
      ),
    );
  }
}
