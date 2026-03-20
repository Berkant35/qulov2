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
        loading: () => _buildWithPreloaded(detailContext, isMatchContext),
        error: (err, _) => ErrorRetryWidget(
          onRetry: () => ref.read(profileDetailProvider(widget.userId).notifier).refresh(),
        ),
        data: (profile) => _buildBody(profile, detailContext, isMatchContext),
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

  Widget _buildBody(PublicProfileModel profile, ProfileDetailContext ctx, bool isMatch) {
    final showQuestions =
        ctx == ProfileDetailContext.discover || ctx == ProfileDetailContext.quizResult;

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
            userId: widget.userId,
            onReport: onReport,
            onBlock: onBlock,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildWithPreloaded(ProfileDetailContext ctx, bool isMatch) {
    final card = widget.args?.preloadedCard;
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
    return _buildBody(tempProfile, ctx, isMatch);
  }
}
