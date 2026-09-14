import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_button.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/data/models/user_model.dart';
import 'package:qulo_v2/features/profile/mixins/profile_preview_screen_mixin.dart';
import 'package:qulo_v2/features/profile_detail/widgets/profile_detail_body.dart';
import 'package:qulo_v2/providers/user_provider.dart';

class ProfilePreviewScreen extends ConsumerStatefulWidget {
  final String source;

  const ProfilePreviewScreen({
    super.key,
    this.source = 'profile_screen',
  });

  @override
  ConsumerState<ProfilePreviewScreen> createState() =>
      _ProfilePreviewScreenState();
}

class _ProfilePreviewScreenState extends ConsumerState<ProfilePreviewScreen>
    with ProfilePreviewScreenMixin {
  @override
  void initState() {
    super.initState();
    initMixin();
  }

  @override
  void dispose() {
    disposeMixin();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);

    // Raw Scaffold: full-bleed photo gallery with its own close button —
    // AppScaffold's page padding / AppBar would break the layout.
    return Scaffold(
      backgroundColor: context.appColors.scaffold,
      body: userAsync.when(
        loading: () => const Center(child: AppLoadingWidget.large()),
        error: (_, __) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) onClose();
          });
          return const SizedBox.shrink();
        },
        data: (user) {
          if (user == null) return const SizedBox.shrink();
          return ProfileDetailBody(
            profile: user.toPublicProfile(),
            onClose: onClose,
            onPhotoChanged: onPhotoChanged,
            showDistance: false,
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: AppButton(
            label: context.tr('edit_profile'),
            onPressed: onEditProfile,
          ),
        ),
      ),
    );
  }
}
