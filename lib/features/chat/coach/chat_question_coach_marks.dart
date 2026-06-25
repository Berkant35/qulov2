import 'package:qulo_v2/core/coach_mark/coach_mark_step.dart';

/// Single-step tour highlighting the "send a question" button in the chat
/// input bar. Shown once on the user's first visit to any match chat.
List<CoachMarkStep> buildChatQuestionCoachSteps() => const [
      CoachMarkStep(
        anchorId: 'chat_question_btn',
        shape: CoachMarkShape.circle,
        titleKey: 'coach_chat_question_title',
        bodyKey: 'coach_chat_question_body',
        ctaKey: 'coach_cta_got_it',
      ),
    ];
