import 'package:flutter/material.dart';
import 'package:qulo_v2/core/constants/q_icons.dart';
import 'package:qulo_v2/core/widgets/app_icon.dart';

/// Fotograf yokken / yuklenirken / hata aninda kartin dolgusu.
///
/// Ayri widget class'i: proje kurali `Widget _buildX()` desenini yasakliyor.
class ProfilePhotoPlaceholder extends StatelessWidget {
  const ProfilePhotoPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      child: Center(
        child: AppIcon(QIcons.userRounded, color: theme.hintColor, size: 80),
      ),
    );
  }
}
