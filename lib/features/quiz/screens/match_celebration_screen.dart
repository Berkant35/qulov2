import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_loading_widget.dart';

class MatchCelebrationScreen extends StatefulWidget {
  final bool matched;
  final int totalCorrect;
  final int totalQuestions;
  final int totalTimeSpent;
  final int powersUsed;
  final String performanceBadge;
  final String? targetPhotoUrl;
  final String? myPhotoUrl;
  final VoidCallback? onStartChat;
  final VoidCallback onGoBack;

  const MatchCelebrationScreen({
    super.key,
    required this.matched,
    required this.totalCorrect,
    required this.totalQuestions,
    required this.totalTimeSpent,
    required this.powersUsed,
    required this.performanceBadge,
    this.targetPhotoUrl,
    this.myPhotoUrl,
    this.onStartChat,
    required this.onGoBack,
  });

  @override
  State<MatchCelebrationScreen> createState() =>
      _MatchCelebrationScreenState();
}

class _MatchCelebrationScreenState extends State<MatchCelebrationScreen>
    with TickerProviderStateMixin {
  late final AnimationController _badgeController;
  late final AnimationController _photoController;
  late final AnimationController _statsController;

  late final Animation<double> _badgeScale;
  late final Animation<double> _badgeOpacity;
  late final Animation<double> _photoSlide;
  late final Animation<double> _statsOpacity;

  @override
  void initState() {
    super.initState();

    // Badge animation: scale 3→1 with elasticOut, 1000ms
    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _badgeScale = Tween<double>(begin: 3.0, end: 1.0).animate(
      CurvedAnimation(parent: _badgeController, curve: Curves.elasticOut),
    );
    _badgeOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _badgeController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // Photo animation: slide from sides, 800ms
    _photoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _photoSlide = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _photoController, curve: Curves.easeOutBack),
    );

    // Stats fade in with photos
    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _statsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _statsController, curve: Curves.easeIn),
    );

    _startAnimations();

    AnalyticsManager.instance.logEvent(
      AnalyticsEvents.matchCelebrationShown,
      params: {
        AnalyticsEvents.paramMatched: widget.matched.toString(),
        AnalyticsEvents.paramBadge: widget.performanceBadge,
      },
    );
  }

  Future<void> _startAnimations() async {
    // Badge starts after 200ms delay
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _badgeController.forward();

    // Photos start after 800ms delay from beginning
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _photoController.forward();
    _statsController.forward();
  }

  @override
  void dispose() {
    _badgeController.dispose();
    _photoController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.95),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
              vertical: AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ─── Badge animation ───
                _buildBadgeSection(theme),
                const SizedBox(height: AppSpacing.xxl),

                // ─── Photo animation ───
                _buildPhotoSection(),
                const SizedBox(height: AppSpacing.xxl),

                // ─── Stats + buttons ───
                FadeTransition(
                  opacity: _statsOpacity,
                  child: Column(
                    children: [
                      _buildStats(theme),
                      const SizedBox(height: AppSpacing.xl),
                      _buildButtons(theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeSection(ThemeData theme) {
    final config = _getBadgeConfig();

    return AnimatedBuilder(
      animation: _badgeController,
      builder: (context, child) {
        return Opacity(
          opacity: _badgeOpacity.value,
          child: Transform.scale(
            scale: _badgeScale.value,
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge chip
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: config.gradientColors),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              boxShadow: [
                BoxShadow(
                  color: config.gradientColors.first.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(config.icon, size: 24, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  context.tr(config.labelKey),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Title text
          Text(
            widget.matched ? context.tr('quiz_match_title') : context.tr('quiz_failed_title'),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: widget.matched ? AppColors.primary : AppColors.error,
              fontWeight: FontWeight.bold,
              fontSize: widget.matched ? 32 : 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return AnimatedBuilder(
      animation: _photoController,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // My photo — slides from left
            Transform.translate(
              offset: Offset(-_photoSlide.value, 0),
              child: _buildPhotoCircle(widget.myPhotoUrl),
            ),
            const SizedBox(width: AppSpacing.md),
            // Heart icon between photos
            Opacity(
              opacity: 1.0 - (_photoSlide.value / 50.0).clamp(0.0, 1.0),
              child: Icon(
                Icons.favorite,
                color: widget.matched ? AppColors.primary : AppColors.error,
                size: 32,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Target photo — slides from right
            Transform.translate(
              offset: Offset(_photoSlide.value, 0),
              child: _buildPhotoCircle(widget.targetPhotoUrl),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPhotoCircle(String? photoUrl) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: ClipOval(
        child: photoUrl != null && photoUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppColors.surfaceElevated,
                  child: AppLoadingWidget.small(),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.surfaceElevated,
                  child: const Icon(
                    Icons.person,
                    color: AppColors.textSecondary,
                    size: 40,
                  ),
                ),
              )
            : Container(
                color: AppColors.surfaceElevated,
                child: const Icon(
                  Icons.person,
                  color: AppColors.textSecondary,
                  size: 40,
                ),
              ),
      ),
    );
  }

  Widget _buildStats(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          _StatRow(
            icon: Icons.check_circle_outline,
            iconColor: AppColors.secondary,
            label:
                context.tr('quiz_stat_correct').replaceAll('{correct}', '${widget.totalCorrect}').replaceAll('{total}', '${widget.totalQuestions}'),
            theme: theme,
          ),
          const SizedBox(height: AppSpacing.md),
          _StatRow(
            icon: Icons.timer_outlined,
            iconColor: AppColors.info,
            label: context.tr('quiz_stat_time').replaceAll('{time}', '${widget.totalTimeSpent}'),
            theme: theme,
          ),
          if (widget.powersUsed > 0) ...[
            const SizedBox(height: AppSpacing.md),
            _StatRow(
              icon: Icons.bolt,
              iconColor: AppColors.primary,
              label: context.tr('quiz_stat_powers').replaceAll('{count}', '${widget.powersUsed}'),
              theme: theme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildButtons(ThemeData theme) {
    return Column(
      children: [
        if (widget.matched && widget.onStartChat != null) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                AnalyticsManager.instance.logEvent(
                  AnalyticsEvents.matchCelebrationStartChat,
                );
                widget.onStartChat?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: Text(
                context.tr('quiz_send_message'),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              AnalyticsManager.instance.logEvent(
                AnalyticsEvents.matchCelebrationGoBack,
              );
              widget.onGoBack();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              padding:
                  const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            child: Text(
              context.tr('quiz_go_back'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  _BadgeConfig _getBadgeConfig() {
    if (widget.matched) {
      return switch (widget.performanceBadge) {
        'flawless' => _BadgeConfig(
            labelKey: 'quiz_badge_flawless',
            icon: Icons.stars,
            gradientColors: [Colors.amber, Colors.orange],
          ),
        'speed_solver' => _BadgeConfig(
            labelKey: 'quiz_badge_speed_solver',
            icon: Icons.bolt,
            gradientColors: [Colors.blue, Colors.cyan],
          ),
        'power_master' => _BadgeConfig(
            labelKey: 'quiz_badge_power_master',
            icon: Icons.auto_awesome,
            gradientColors: [AppColors.primary, Colors.deepPurple],
          ),
        'determined' => _BadgeConfig(
            labelKey: 'quiz_badge_determined',
            icon: Icons.psychology,
            gradientColors: [Colors.green, Colors.teal],
          ),
        _ => _BadgeConfig(
            labelKey: 'quiz_badge_matched',
            icon: Icons.favorite,
            gradientColors: [AppColors.primary, Colors.pink],
          ),
      };
    }
    return _BadgeConfig(
      labelKey: 'quiz_badge_failed',
      icon: Icons.close,
      gradientColors: [AppColors.error, Colors.red],
    );
  }
}

class _BadgeConfig {
  final String labelKey;
  final IconData icon;
  final List<Color> gradientColors;

  const _BadgeConfig({
    required this.labelKey,
    required this.icon,
    required this.gradientColors,
  });
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final ThemeData theme;

  const _StatRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
