import 'package:qulo_v2/data/models/daily_stats_model.dart';
import 'package:qulo_v2/features/discover/models/undo_allowance.dart';

/// `DiscoverActionButtons` logic'i (stateless widget → plain mixin).
mixin DiscoverActionButtonsMixin {
  /// Gunluk limitlerden geri alma hakki. Limitler henuz yuklenmediyse (null)
  /// hak yok sayilir — yukleme kisa surer; basarisiz istek artik aboneligin
  /// kendi limitlerine duser (`daily_stats_provider`).
  UndoAllowance undoAllowance(DailyStats? stats) {
    final used = stats?.dailyUndosUsed ?? 0;
    final limit = stats?.dailyUndosLimit ?? 0;
    final unlimited = stats?.isUndoUnlimited ?? false;
    return UndoAllowance(
      hasRight: unlimited || limit > 0,
      isUnlimited: unlimited,
      remaining: unlimited ? -1 : (limit - used).clamp(0, limit),
    );
  }

  /// Butonun altindaki etiket: hak varsa kalan sayi (sinirsizda ∞), yoksa
  /// [lockedLabel] ("Geri al").
  String undoLabel(UndoAllowance allowance, {required String lockedLabel}) {
    if (!allowance.hasRight) return lockedLabel;
    return allowance.isUnlimited ? '∞' : '${allowance.remaining}';
  }

  /// Etiket yalniz hak varken VE geri alinacak kart varken vurgulu.
  bool isUndoLabelHighlighted(UndoAllowance allowance, {required bool canUndo}) =>
      allowance.hasRight && canUndo;
}
