import 'package:flutter/material.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

/// Sonuç ekranının elmas hareketi kartı (yeşil/Rainbow kazanç, mor harcama): başlık + alt metin; birden
/// çok satır varsa başlığa dokununca satır satır döküm açılır.
///
/// Renk/ikon/metinler ve satırlar çağırandan gelir ([ChatQuestionRewardCards]); kart yalnız çizer.
class PowerLedgerCard extends StatefulWidget {
  const PowerLedgerCard({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.rows,
    required this.amountPrefix,
  });

  final Color color;
  final Widget icon;
  final String title;
  final String subtitle;

  /// Çevrilmiş satır etiketi → miktar (ekleme sırası korunur).
  final Map<String, int> rows;

  /// Miktarın önüne yazılan işaret: kazançta `+`, harcamada `-`.
  final String amountPrefix;

  @override
  State<PowerLedgerCard> createState() => _PowerLedgerCardState();
}

class _PowerLedgerCardState extends State<PowerLedgerCard> {
  bool _expanded = false;

  bool get _expandable => widget.rows.length > 1;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = widget.color;
    final secondary = context.appColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _expandable ? () => setState(() => _expanded = !_expanded) : null,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                widget.icon,
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.bold),
                      ),
                      Text(widget.subtitle, style: textTheme.bodySmall?.copyWith(color: secondary)),
                    ],
                  ),
                ),
                if (_expandable)
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: secondary,
                    size: 20,
                  ),
              ],
            ),
          ),
          if (_expanded && _expandable) ...[
            const SizedBox(height: AppSpacing.sm),
            Divider(color: color.withValues(alpha: 0.2), height: 1),
            const SizedBox(height: AppSpacing.sm),
            for (final row in widget.rows.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(row.key, style: textTheme.bodySmall?.copyWith(color: secondary)),
                    Text(
                      '${widget.amountPrefix}${row.value}',
                      style: textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
