import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/features/settings/widgets/settings_action_tile.dart';

class SettingsLegalSection extends StatelessWidget {
  final Future<void> Function(String url) onOpenUrl;

  const SettingsLegalSection({super.key, required this.onOpenUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsActionTile(
          icon: Icons.description_outlined,
          title: context.tr('terms_of_service'),
          onTap: () => onOpenUrl('https://qulo.app/terms'),
        ),
        SettingsActionTile(
          icon: Icons.privacy_tip_outlined,
          title: context.tr('privacy_policy'),
          onTap: () => onOpenUrl('https://qulo.app/privacy'),
        ),
      ],
    );
  }
}
