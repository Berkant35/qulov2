import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

/// Teslim edilen kod (kopyala) ve/veya link (harici tarayıcı).
class RedemptionDeliveryBox extends StatelessWidget {
  const RedemptionDeliveryBox({super.key, this.code, this.url, required this.onCopy, required this.onOpen});

  final String? code;
  final String? url;
  final void Function(String code) onCopy;
  final void Function(String url) onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceInput,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (code != null)
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    code!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(onPressed: () => onCopy(code!), child: Text(context.tr('redemption_copy_code'))),
              ],
            ),
          if (url != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: () => onOpen(url!), child: Text(context.tr('redemption_open_link'))),
            ),
        ],
      ),
    );
  }
}
