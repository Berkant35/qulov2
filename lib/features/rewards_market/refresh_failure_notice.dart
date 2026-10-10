import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/l10n/l10n.dart';
import 'package:qulo_v2/core/network/failure_message.dart';
import 'package:qulo_v2/core/network/result.dart';

/// Pull-to-refresh başarısız ama önceki veri ekranda kaldıysa kısa bildirim — kullanıcı bayat listeyi
/// taze sanmasın. Önceki veri yoksa ekranın kendi hata görünümü zaten gösterildiği için bir şey yapmaz.
void showRefreshFailure(BuildContext context, AsyncValue<Object?> state, String fallbackKey) {
  if (!state.hasError || state.valueOrNull == null) return;
  final error = state.error;
  final key = error is AppFailure ? error.userMessageKey(fallbackKey) : fallbackKey;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr(key))));
}
