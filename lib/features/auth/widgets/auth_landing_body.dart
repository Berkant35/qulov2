import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qulo_v2/core/constants/app_assets.dart';
import 'package:qulo_v2/core/constants/app_sizes.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';

/// [AuthLandingScreen] icin marka basligi + sosyal butonlar + e-posta CTA'sini
/// bir arada sunan salt-UI govde. Logic icermez — tum callback'ler disaridan gelir.
class AuthLandingBody extends StatelessWidget {
  final String title;
  final String subtitle;
  final String continueEmailLabel;
  final String? error;
  final Widget socialButtons;
  final VoidCallback onEmail;

  const AuthLandingBody({
    super.key,
    required this.title,
    required this.subtitle,
    required this.continueEmailLabel,
    required this.error,
    required this.socialButtons,
    required this.onEmail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xxxl),
          SvgPicture.asset(
            AppAssets.logoSvg,
            width: AppSizes.logoMd,
            height: AppSizes.logoMd,
            colorFilter:
                ColorFilter.mode(context.appColors.primary, BlendMode.srcIn),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: context.appColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          socialButtons,
          if (error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.appColors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: continueEmailLabel,
            variant: AppButtonVariant.text,
            onPressed: onEmail,
          ),
        ],
      ),
    );
  }
}
