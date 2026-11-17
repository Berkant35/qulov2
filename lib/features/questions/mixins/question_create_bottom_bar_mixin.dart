import 'package:flutter/widgets.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';

/// [QuestionCreateBottomBar] birincil buton eşlemesi (stateless widget → plain mixin).
mixin QuestionCreateBottomBarMixin {
  static const int _lastStep = 2;

  bool _isLastStep(int step) => step == _lastStep;

  /// Kayıt sürerken ya da adım geçersizken buton kapalı.
  VoidCallback? primaryAction({
    required int currentStep,
    required bool isSaving,
    required bool canGoNext,
    required VoidCallback onNext,
    required VoidCallback onSave,
  }) {
    if (isSaving || !canGoNext) return null;
    return _isLastStep(currentStep) ? onSave : onNext;
  }

  String primaryLabel(
    BuildContext context, {
    required int currentStep,
    required bool isEditMode,
  }) {
    if (!_isLastStep(currentStep)) return context.tr('next');
    return context.tr(
      isEditMode ? 'question_create_update' : 'question_create_save',
    );
  }
}
