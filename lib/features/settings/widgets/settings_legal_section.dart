import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/features/settings/widgets/settings_action_tile.dart';

class SettingsLegalSection extends StatelessWidget {
  final Future<void> Function() onTerms;
  final Future<void> Function() onPrivacy;

  const SettingsLegalSection({
    super.key,
    required this.onTerms,
    required this.onPrivacy,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsActionTile(
          icon: Icons.description_outlined,
          title: context.tr('terms_of_service'),
          onTap: onTerms,
        ),
        SettingsActionTile(
          icon: Icons.privacy_tip_outlined,
          title: context.tr('privacy_policy'),
          onTap: onPrivacy,
        ),
      ],
    );
  }
}
