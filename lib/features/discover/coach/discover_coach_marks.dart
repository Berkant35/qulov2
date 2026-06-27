import 'package:qulo_v2/core/coach_mark/coach_mark_step.dart';

/// Centered "how Qulo works" intro — shown on the first discover visit
/// regardless of whether cards are present or the user has questions yet.
/// This is the transparent app explanation a brand-new user needs.
List<CoachMarkStep> buildDiscoverIntroSteps() => const [
      CoachMarkStep(
        titleKey: 'coach_discover_intro_title',
        bodyKey: 'coach_discover_intro_body',
        ctaKey: 'coach_cta_start',
      ),
    ];

/// Anchored steps highlighting the solve button and the action row — shown
/// once cards are present (after the intro has already been seen).
List<CoachMarkStep> buildDiscoverActionSteps() => const [
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
