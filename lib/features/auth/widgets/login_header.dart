import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qulo_v2/core/constants/app_assets.dart';
import 'package:qulo_v2/core/constants/app_sizes.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';

/// Login ekrani ust blogu: logo + uygulama adi + karsilama metni
class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        SvgPicture.asset(
          AppAssets.logoSvg,
          width: AppSizes.logoMd,
          height: AppSizes.logoMd,
          colorFilter:
              ColorFilter.mode(context.appColors.primary, BlendMode.srcIn),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          context.tr('app_name'),
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall?.copyWith(
            color: context.appColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.tr('welcome_back'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
