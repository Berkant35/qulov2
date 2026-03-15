import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/services/analytics_manager.dart';
import 'package:qulo_v2/core/services/analytics_events.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/widgets/app_scaffold.dart';
import 'package:qulo_v2/routing/route_names.dart';
import 'package:qulo_v2/features/onboarding/widgets/onboarding_page.dart';
import 'package:qulo_v2/features/onboarding/widgets/onboarding_indicators.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _analytics = AnalyticsManager.instance;
  final _controller = PageController();
  int _page = 0;

  static const List<String> _stepNames = ['welcome', 'quiz', 'profile'];

  @override
  void initState() {
    super.initState();
    _analytics.logEvent(AnalyticsEvents.onboardingStart);
    _analytics.logEvent(AnalyticsEvents.onboardingStepView, params: {
      AnalyticsEvents.paramStepName: _stepNames[0],
      AnalyticsEvents.paramStepIndex: 0,
    });
  }

  List<OnboardingPageData> _getPages(BuildContext context) => [
        OnboardingPageData(
          icon: Icons.favorite,
          title: context.tr('onboarding_title_1'),
          subtitle: context.tr('onboarding_sub_1'),
        ),
        OnboardingPageData(
          icon: Icons.quiz,
          title: context.tr('onboarding_title_2'),
          subtitle: context.tr('onboarding_sub_2'),
        ),
        OnboardingPageData(
          icon: Icons.person,
          title: context.tr('onboarding_title_3'),
          subtitle: context.tr('onboarding_sub_3'),
        ),
      ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = _getPages(context);
    final isLast = _page == pages.length - 1;

    return AppScaffold(
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (i) {
                setState(() => _page = i);
                _analytics.logEvent(AnalyticsEvents.onboardingStepView,
                    params: {
                      AnalyticsEvents.paramStepName: _stepNames[i],
                      AnalyticsEvents.paramStepIndex: i,
                    });
              },
              itemCount: pages.length,
              itemBuilder: (_, i) => OnboardingPage(data: pages[i]),
            ),
          ),
          OnboardingIndicators(count: pages.length, currentPage: _page),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  _analytics.logEvent(
                      AnalyticsEvents.onboardingStepComplete,
                      params: {
                        AnalyticsEvents.paramStepName: _stepNames[_page],
                        AnalyticsEvents.paramStepIndex: _page,
                      });
                  if (isLast) {
                    _analytics
                        .logEvent(AnalyticsEvents.onboardingComplete);
                    ref
                        .read(navigationServiceProvider)
                        .go(RouteNames.discover);
                  } else {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: Text(isLast
                    ? context.tr('get_started')
                    : context.tr('next')),
              ),
            ),
          ),
          if (!isLast)
            TextButton(
              onPressed: () => ref
                  .read(navigationServiceProvider)
                  .go(RouteNames.discover),
              child: Text(context.tr('skip')),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
