import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qulo_v2/core/constants/app_assets.dart';
import 'package:qulo_v2/core/constants/app_sizes.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/app_config_provider.dart';

class ForceUpdateScreen extends ConsumerWidget {
  const ForceUpdateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider).config;

    return PopScope(
      canPop: false,
      child: AppScaffold(
        padding: const EdgeInsets.all(AppSpacing.xl),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                AppAssets.logoSvg,
                width: AppSizes.logoMd,
                height: AppSizes.logoMd,
                colorFilter: ColorFilter.mode(
                  context.appColors.primary,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                context.tr('update_required_title'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                context.tr('update_required_message'),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              if (config != null && config.storeUrl.isNotEmpty)
                AppButton(
                  label: context.tr('update_button'),
                  onPressed: () {
                    ref
                        .read(urlLauncherManagerProvider)
                        .launch(config.storeUrl);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
