import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/navigation/navigation.dart';
import 'package:qulo_v2/data/models/quiz_model.dart' show QuizQuestionModel;
import 'package:qulo_v2/features/profile_detail/widgets/report_category_sheet.dart';
import 'package:qulo_v2/providers/api_provider.dart';

/// Quiz başlığındaki şikâyet girişi (2.0.19): kategori sayfası → sebep penceresi → şikâyet
/// çözülen sorunun `question_id`'siyle gider (sunucu soru ↔ kişi eşleşmesini doğrular).
/// Sorunun sesi/görseli varsa "Uygunsuz medya" kategorisi de sunulur.
mixin QuizReportMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  static const _otherCategory = 'OTHER';
  static const _reasonMaxLength = 500;
  static const _reasonMaxLines = 3;

  /// Şikâyet edilen kişi (soru sahibi).
  String get reportedUserId;

  /// Şu an ekrandaki soru (yoksa şikâyet yalnız kişiye gider).
  QuizQuestionModel? get reportedQuestion;

  bool get includeMediaReportCategory => reportedQuestion?.hasMedia ?? false;

  void onReportQuestion() {
    // Kategori sayfası açıkken soru ilerleyebilir: şikâyet BASILAN sorunun kimliğini taşır.
    final questionId = reportedQuestion?.questionId;
    ref.read(navigationServiceProvider).showAppBottomSheet<void>(
          CustomBottomSheet(
            name: 'quiz_report_category',
            builder: (_) => ReportCategorySheet(
              includeMediaCategory: includeMediaReportCategory,
              onSelected: (category) => _showReasonDialog(category, questionId),
            ),
          ),
        );
  }

  /// Şikâyeti yollar; başarılıysa true. Hata sessiz yutulmaz (moderasyon yolu).
  Future<bool> sendQuestionReport({
    required String category,
    String? reason,
    String? questionId,
  }) async {
    final result = await ref.read(reportRepositoryProvider).createReport(
          reportedId: reportedUserId,
          category: category,
          reason: reason != null && reason.isNotEmpty ? reason : null,
          questionId: questionId,
        );
    return result.isSuccess;
  }

  void _showReasonDialog(String category, String? questionId) {
    final nav = ref.read(navigationServiceProvider);
    final controller = TextEditingController();
    final isOther = category == _otherCategory;

    nav.showAppDialog(
      CustomDialog(
        name: 'quiz_report_reason',
        builder: (ctx) => AlertDialog(
          title: Text(ctx.tr('report')),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: ctx.tr('report_reason_hint')),
            maxLines: _reasonMaxLines,
            maxLength: _reasonMaxLength,
          ),
          actions: [
            TextButton(
              onPressed: nav.closeOverlay,
              child: Text(ctx.tr('cancel')),
            ),
            FilledButton(
              onPressed: () async {
                final reason = controller.text.trim();
                if (isOther && reason.isEmpty) return;
                nav.closeOverlay();
                // Metinler await ÖNCESİ alınır: dialog context'i async gap sonrası kullanılmaz.
                final sentText = ctx.tr('report_sent');
                final failedText = ctx.tr('report_failed');
                final sent = await sendQuestionReport(
                  category: category,
                  reason: reason,
                  questionId: questionId,
                );
                controller.dispose();
                if (!mounted) return;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(sent ? sentText : failedText)));
              },
              child: Text(ctx.tr('report')),
            ),
          ],
        ),
      ),
    );
  }
}
