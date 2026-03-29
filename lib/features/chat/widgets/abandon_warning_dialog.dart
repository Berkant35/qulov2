import 'package:flutter/material.dart';
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
      features.add(const _FeatureItem(
        icon: Icons.lock_outline,
        label: 'Soru Kilidi',
      ));
    }
    if (question.hasPowerBlock) {
      features.add(const _FeatureItem(
        icon: Icons.flash_on,
        label: 'Güç Engeli',
      ));
    }
    if (question.hasUnmatchRisk) {
      features.add(const _FeatureItem(
        icon: Icons.heart_broken,
        label: 'Unmatch Riski',
        isDestructive: true,
      ));
    }

    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Sorudan Kaçıyorsun!',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (features.isNotEmpty) ...[
            const Text('Karşı taraf bu soruya şu özellikleri eklemiş:'),
            const SizedBox(height: 12),
            ...features,
            const SizedBox(height: 16),
          ],
          const Text('Cevap vermeden çıkarsan sorudan kaçmış sayılırsın.'),
          if (question.hasUnmatchRisk) ...[
            const SizedBox(height: 8),
            Text(
              'Eşleşmen sona erecek!',
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
            'Vazgeç ve Çık',
            style: TextStyle(color: Colors.red.shade400),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Geri Dön'),
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
