import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';

/// Shows a warning dialog when the user tries to leave the solve screen
/// without answering. Lists question features and unmatch risk.
/// Returns true if user confirms abandon, false if they want to stay.
Future<bool> showAbandonWarningDialog(
  BuildContext context,
  ChatQuestionModel question,
) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _AbandonWarningDialog(question: question),
  );
  return result ?? false;
}

class _AbandonWarningDialog extends StatelessWidget {
  final ChatQuestionModel question;

  const _AbandonWarningDialog({required this.question});

  @override
  Widget build(BuildContext context) {
    final features = <_FeatureItem>[];

    if (question.hasChatLock) {
      features.add(_FeatureItem(
        icon: Icons.lock_outline,
        label: context.tr('abandon_question_lock'),
      ));
    }
    if (question.hasPowerBlock) {
      features.add(_FeatureItem(
        icon: Icons.flash_on,
        label: context.tr('abandon_power_block'),
      ));
    }
    if (question.hasUnmatchRisk) {
      features.add(_FeatureItem(
        icon: Icons.heart_broken,
        label: context.tr('abandon_unmatch_risk'),
        isDestructive: true,
      ));
    }

    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        context.tr('abandon_title'),
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (features.isNotEmpty) ...[
            Text(context.tr('abandon_features_added')),
            const SizedBox(height: 12),
            ...features,
            const SizedBox(height: 16),
          ],
          Text(context.tr('abandon_flee_warning')),
          if (question.hasUnmatchRisk) ...[
            const SizedBox(height: 8),
            Text(
              context.tr('abandon_unmatch_warning'),
              style: TextStyle(
                color: Colors.red.shade400,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            context.tr('abandon_leave'),
            style: TextStyle(color: Colors.red.shade400),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.tr('abandon_stay')),
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;

  const _FeatureItem({
    required this.icon,
    required this.label,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red.shade400 : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: isDestructive ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }
}
