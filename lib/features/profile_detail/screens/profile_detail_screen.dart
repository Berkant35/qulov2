import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';
import 'package:qulo_v2/core/widgets/error_retry_widget.dart';
import 'package:qulo_v2/data/models/public_profile_model.dart';
import 'package:qulo_v2/features/profile_detail/models/profile_detail_args.dart';
import 'package:qulo_v2/features/profile_detail/mixins/profile_detail_screen_mixin.dart';
import 'package:qulo_v2/features/profile_detail/providers/profile_detail_provider.dart';
import 'package:qulo_v2/features/profile_detail/widgets/profile_action_bar.dart';
import 'package:qulo_v2/features/profile_detail/widgets/profile_basic_info.dart';
import 'package:qulo_v2/features/profile_detail/widgets/profile_bio_section.dart';
import 'package:qulo_v2/features/profile_detail/widgets/profile_details_grid.dart';
import 'package:qulo_v2/features/profile_detail/widgets/profile_photo_gallery.dart';
import 'package:qulo_v2/features/profile_detail/widgets/profile_question_info.dart';
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
    final detailContext = widget.args?.context ?? ProfileDetailContext.discover;
    final isMatchContext =
        detailContext == ProfileDetailContext.match || detailContext == ProfileDetailContext.chat;

    return Scaffold(
      backgroundColor: context.appColors.scaffold,
      body: asyncProfile.when(
        loading: () => _ProfileDetailWithPreloaded(
          args: widget.args,
          detailContext: detailContext,
          isMatch: isMatchContext,
          userId: widget.userId,
          onClose: onClose,
          onPhotoChanged: onPhotoChanged,
          onReport: onReport,
          onBlock: onBlock,
        ),
        error: (err, _) => ErrorRetryWidget(
          onRetry: () => ref.read(profileDetailProvider(widget.userId).notifier).refresh(),
        ),
        data: (profile) => _ProfileDetailBody(
          profile: profile,
          detailContext: detailContext,
          isMatch: isMatchContext,
          userId: widget.userId,
          onClose: onClose,
          onPhotoChanged: onPhotoChanged,
          onReport: onReport,
          onBlock: onBlock,
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

class _ProfileDetailBody extends StatelessWidget {
  final PublicProfileModel profile;
  final ProfileDetailContext detailContext;
  final bool isMatch;
  final String userId;
  final VoidCallback onClose;
  final void Function(int index, int total) onPhotoChanged;
  final VoidCallback onReport;
  final VoidCallback onBlock;

  const _ProfileDetailBody({
    required this.profile,
    required this.detailContext,
    required this.isMatch,
    required this.userId,
    required this.onClose,
    required this.onPhotoChanged,
    required this.onReport,
    required this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    final showQuestions =
        detailContext == ProfileDetailContext.discover ||
        detailContext == ProfileDetailContext.quizResult;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfilePhotoGallery(
            photos: profile.photos,
            onClose: onClose,
            onPhotoChanged: onPhotoChanged,
          ),
          const SizedBox(height: AppSpacing.lg),
          ProfileBasicInfo(profile: profile, showOnlineStatus: isMatch),
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sectionGap),
            ProfileBioSection(bio: profile.bio!),
          ],
          if (profile.details != null) ...[
            const SizedBox(height: AppSpacing.sectionGap),
            ProfileDetailsGrid(details: profile.details!),
          ],
          if (showQuestions && profile.questionInfo != null) ...[
            const SizedBox(height: AppSpacing.sectionGap),
            ProfileQuestionInfo(questionInfo: profile.questionInfo!),
          ],
          const SizedBox(height: AppSpacing.sectionGap),
          ProfileReportButton(
            userId: userId,
            onReport: onReport,
            onBlock: onBlock,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _ProfileDetailWithPreloaded extends StatelessWidget {
  final ProfileDetailArgs? args;
  final ProfileDetailContext detailContext;
  final bool isMatch;
  final String userId;
  final VoidCallback onClose;
  final void Function(int index, int total) onPhotoChanged;
  final VoidCallback onReport;
  final VoidCallback onBlock;

  const _ProfileDetailWithPreloaded({
    required this.args,
    required this.detailContext,
    required this.isMatch,
    required this.userId,
    required this.onClose,
    required this.onPhotoChanged,
    required this.onReport,
    required this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    final card = args?.preloadedCard;
    if (card == null) {
      return const Center(child: AppLoadingWidget.large());
    }

    final tempProfile = PublicProfileModel(
      userId: card.userId,
      name: card.name,
      age: card.age,
      bio: card.bio,
      city: card.city,
      photos: card.photos ?? [],
      distanceKm: card.distanceKm,
      relationshipGoal: card.relationshipGoal,
      profileCompletion: card.profileCompletion,
      isBoosted: card.isBoosted,
      questionInfo: card.questionInfo,
    );

    return _ProfileDetailBody(
      profile: tempProfile,
      detailContext: detailContext,
      isMatch: isMatch,
      userId: userId,
      onClose: onClose,
      onPhotoChanged: onPhotoChanged,
      onReport: onReport,
      onBlock: onBlock,
    );
  }
}
