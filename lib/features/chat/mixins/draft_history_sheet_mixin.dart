import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/chat_question_draft_model.dart';
import 'package:qulo_v2/data/models/chat_question_model.dart';
import 'package:qulo_v2/features/chat/sheets/draft_history_sheet.dart';
import 'package:qulo_v2/providers/api_provider.dart';

/// Taslak gecmisi sheet'inin davranisi: taslak + gecmis yukleme, taslak silme
/// ve secme. Her await sonrasi `mounted` — sheet istek surerken kapanabilir.
mixin DraftHistorySheetMixin on ConsumerState<DraftHistorySheet> {
  List<ChatQuestionDraftModel>? drafts;
  List<ChatQuestionHistoryItem>? history;
  bool isDraftsLoading = true;
  bool isHistoryLoading = true;
  bool draftsFailed = false;
  bool historyFailed = false;

  void initMixin() {
    _loadDrafts();
    _loadHistory();
  }

  Future<void> _loadDrafts() async {
    final result = await ref.read(chatRepositoryProvider).getDrafts();
    if (!mounted) return;
    setState(() {
      isDraftsLoading = false;
      switch (result) {
        case Success(:final data):
          drafts = data;
        case Failure():
          draftsFailed = true;
      }
    });
  }

  Future<void> _loadHistory() async {
    final result = await ref.read(chatRepositoryProvider).getHistory();
    if (!mounted) return;
    setState(() {
      isHistoryLoading = false;
      switch (result) {
        case Success(:final data):
          history = data.items;
        case Failure():
          historyFailed = true;
      }
    });
  }

  /// Kaydirilan taslak AYNI karede listeden cikar (`Dismissible` sozlesmesi —
  /// eskiden sunucu cevabi beklenirken "dismissed Dismissible still part of the
  /// tree" riski vardi). Sunucu istegi sonra gider; sheet bu arada kapanirsa
  /// eskiden `setState` dispose edilmis State'e dusuyordu.
  Future<void> deleteDraft(String draftId) async {
    setState(() => drafts = drafts?.where((d) => d.id != draftId).toList());
    final result = await ref.read(chatRepositoryProvider).deleteDraft(draftId);
    if (!mounted || result.isSuccess) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('chat_draft_delete_failed'))),
    );
  }

  void selectDraft(ChatQuestionDraftModel draft) {
    // Sheet ici kapatma — sheet/dialog icinde Navigator.pop istisnasi.
    Navigator.pop(context);
    widget.onDraftSelected(draft);
  }
}
