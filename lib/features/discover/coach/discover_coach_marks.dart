import 'package:qulo_v2/core/coach_mark/coach_mark_step.dart';

/// 3-step discover onboarding tour. Step 1 is a centered intro (no anchor);
/// steps 2–3 highlight the solve button and the action row.
List<CoachMarkStep> buildDiscoverCoachSteps() => const [
      CoachMarkStep(
        titleKey: 'coach_discover_intro_title',
        bodyKey: 'coach_discover_intro_body',
        ctaKey: 'coach_cta_next',
      ),
      CoachMarkStep(
        anchorId: 'discover_solve',
        titleKey: 'coach_discover_solve_title',
        bodyKey: 'coach_discover_solve_body',
        ctaKey: 'coach_cta_next',
      ),
      CoachMarkStep(
        anchorId: 'discover_actions',
        titleKey: 'coach_discover_match_title',
        bodyKey: 'coach_discover_match_body',
        ctaKey: 'coach_cta_start',
      ),
    ];
