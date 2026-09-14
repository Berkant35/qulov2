import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/features/profile/widgets/section_card.dart';

/// "About me" card on the own-profile screen; shows a hint when bio is empty.
class ProfileAboutCard extends StatelessWidget {
  final String? bio;
  final VoidCallback onTap;

  const ProfileAboutCard({super.key, required this.bio, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = bio;
    final hasBio = text != null && text.isNotEmpty;

    return SectionCard(
      title: context.tr('about_me'),
      onTap: onTap,
      child: Text(
        hasBio ? text : context.tr('hint_add_bio'),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: hasBio ? null : theme.hintColor,
        ),
      ),
    );
  }
}
