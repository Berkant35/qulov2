import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/error_retry_widget.dart';
import 'package:qulo_v2/features/profile_detail/models/profile_detail_args.dart';
import 'package:qulo_v2/features/profile_detail/mixins/profile_detail_screen_mixin.dart';
import 'package:qulo_v2/features/profile_detail/providers/profile_detail_provider.dart';
import 'package:qulo_v2/features/profile_detail/widgets/profile_action_bar.dart';
import 'package:qulo_v2/features/profile_detail/widgets/profile_detail_body.dart';
import 'package:qulo_v2/features/profile_detail/widgets/profile_report_button.dart';

class ProfileDetailScreen extends ConsumerStatefulWidget {
  final String userId;
  final ProfileDetailArgs? args;

  const ProfileDetailScreen({
    super.key,
    required this.userId,
    this.args,
  });

  @override
  ConsumerState<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends ConsumerState<ProfileDetailScreen>
    with ProfileDetailScreenMixin {
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
    final asyncProfile = ref.watch(profileDetailProvider(widget.userId));
    final preloaded = preloadedProfile;
    final reportButton = ProfileReportButton(
      userId: widget.userId,
      onReport: onReport,
      onBlock: onBlock,
    );

    // Raw Scaffold: full-bleed photo gallery with its own close button —
    // AppScaffold's page padding / AppBar would break the layout.
    return Scaffold(
      backgroundColor: context.appColors.scaffold,
      body: asyncProfile.when(
        // Discover'dan gelen kart varsa detay yuklenirken hemen onu goster.
        loading: () => preloaded == null
            ? const Center(child: AppLoadingWidget.large())
            : ProfileDetailBody(
                profile: preloaded,
                onClose: onClose,
                onPhotoChanged: onPhotoChanged,
                showOnlineStatus: isMatchContext,
                showQuestions: showQuestionInfo,
                footer: reportButton,
              ),
        error: (_, __) => ErrorRetryWidget(onRetry: retryLoad),
        data: (profile) => ProfileDetailBody(
          profile: profile,
          onClose: onClose,
          onPhotoChanged: onPhotoChanged,
          showOnlineStatus: isMatchContext,
          showQuestions: showQuestionInfo,
          footer: reportButton,
        ),
      ),
      bottomNavigationBar: ProfileActionBar(
        detailContext: detailContext,
        onSolveQuestions: onSolveQuestions,
        onReject: onReject,
        onSendMessage: onSendMessage,
        isMatched: isMatchContext,
      ),
    );
  }
}
