import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/diamond_icon.dart';

// ─── Cell type enum ──────────────────────────────────────────────────────────

enum _CellType { text, infinity, tick, dash }

// ─── Row config ──────────────────────────────────────────────────────────────

class _RowConfig {
  final String labelKey;
  final bool hasDiamondIcon;

  // free / plus / premium cell types
  final _CellType freeType;
  final _CellType plusType;
  final _CellType premiumType;

  // optional text values (only used when type == text)
  final String? freeText;
  final String? plusText;
  final String? premiumText;

  const _RowConfig({
    required this.labelKey,
    required this.freeType,
    required this.plusType,
    required this.premiumType,
    this.freeText,
    this.plusText,
    this.premiumText,
    this.hasDiamondIcon = false,
  });
}

// ─── Static table data ───────────────────────────────────────────────────────

const List<_RowConfig> _kRows = [
  _RowConfig(
    labelKey: 'feature_daily_discovers',
    freeType: _CellType.text,
    freeText: '50',
    plusType: _CellType.infinity,
    premiumType: _CellType.infinity,
  ),
  _RowConfig(
    labelKey: 'feature_question_slots',
    freeType: _CellType.text,
    freeText: '4',
    plusType: _CellType.text,
    plusText: '6',
    premiumType: _CellType.text,
    premiumText: '10',
  ),
  _RowConfig(
    labelKey: 'feature_undo',
    freeType: _CellType.dash,
    plusType: _CellType.text,
    plusText: '3',
    premiumType: _CellType.infinity,
  ),
  _RowConfig(
    labelKey: 'feature_monthly_diamonds',
    freeType: _CellType.dash,
    plusType: _CellType.text,
    plusText: '500',
    premiumType: _CellType.text,
    premiumText: '1500',
    hasDiamondIcon: true,
  ),
  _RowConfig(
    labelKey: 'feature_passport',
    freeType: _CellType.dash,
    plusType: _CellType.dash,
    premiumType: _CellType.tick,
  ),
  _RowConfig(
    labelKey: 'feature_no_ads',
    freeType: _CellType.dash,
    plusType: _CellType.tick,
    premiumType: _CellType.tick,
  ),
];

// ─── Plan colors ─────────────────────────────────────────────────────────────

const Color _kFreeColor = Color(0xFF666666);
const Color _kPlusColor = AppColors.secondary;
const Color _kPremiumColor = AppColors.primary;
const Color _kDashColor = Color(0xFF444444);

// ─── Public widget ───────────────────────────────────────────────────────────

class PaywallComparisonTable extends StatelessWidget {
  const PaywallComparisonTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TableHeader(),
        ..._kRows.asMap().entries.map((entry) {
          final isEven = entry.key % 2 == 0;
          return _TableRow(config: entry.value, isEven: isEven);
        }),
      ],
    );
  }
}

// ─── Header row ──────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          const Spacer(flex: 14),
          _HeaderCell(label: 'FREE', color: _kFreeColor),
          _HeaderCell(label: 'PLUS', color: _kPlusColor),
          _HeaderCell(label: 'PREMIUM', color: _kPremiumColor),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final Color color;

  const _HeaderCell({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 7,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Data row ────────────────────────────────────────────────────────────────

class _TableRow extends StatelessWidget {
  final _RowConfig config;
  final bool isEven;

  const _TableRow({required this.config, required this.isEven});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isEven
            ? Colors.white.withAlpha(5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 14,
            child: _FeatureLabel(config: config),
          ),
          _DataCell(type: config.freeType, planColor: _kFreeColor, text: config.freeText),
          _DataCell(type: config.plusType, planColor: _kPlusColor, text: config.plusText),
          _DataCell(type: config.premiumType, planColor: _kPremiumColor, text: config.premiumText),
        ],
      ),
    );
  }
}

// ─── Feature label ───────────────────────────────────────────────────────────

class _FeatureLabel extends StatelessWidget {
  final _RowConfig config;

  const _FeatureLabel({required this.config});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (config.hasDiamondIcon) ...[
          const DiamondIcon.purple(size: 12, showGlow: false),
          const SizedBox(width: AppSpacing.xs),
        ],
        Flexible(
          child: Text(
            context.tr(config.labelKey),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Data cell ───────────────────────────────────────────────────────────────

class _DataCell extends StatelessWidget {
  final _CellType type;
  final Color planColor;
  final String? text;

  const _DataCell({
    required this.type,
    required this.planColor,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 7,
      child: Center(child: _buildContent()),
    );
  }

  Widget _buildContent() {
    switch (type) {
      case _CellType.text:
        return Text(
          text ?? '',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: planColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        );
      case _CellType.infinity:
        return Text(
          '∞',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: planColor,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        );
      case _CellType.tick:
        return Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: planColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            color: Colors.white,
            size: 13,
          ),
        );
      case _CellType.dash:
        return Text(
          '—',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _kDashColor,
            fontSize: 13,
          ),
        );
    }
  }
}
