import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';

class MapConfirmBottomPanel extends StatelessWidget {
  const MapConfirmBottomPanel({
    super.key,
    required this.cityName,
    required this.isLoadingCity,
    required this.isLoading,
    required this.onConfirm,
  });

  final String cityName;
  final bool isLoadingCity;
  final bool isLoading;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.lg, AppSpacing.xl,
          MediaQuery.of(context).padding.bottom + AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -2)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: context.appColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AnimatedOpacity(
                    opacity: isLoadingCity ? 0.4 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      cityName,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (isLoadingCity)
                  const Padding(
                    padding: EdgeInsets.only(left: AppSpacing.sm),
                    child: SizedBox(width: 16, height: 16, child: AppLoadingWidget.small()),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: isLoading ? null : onConfirm,
                style: FilledButton.styleFrom(backgroundColor: context.appColors.primaryDark),
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: AppLoadingWidget.small())
                    : Text(context.tr('passport_start_exploring')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
