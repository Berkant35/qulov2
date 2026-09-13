import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulo_v2/core/network/result.dart';
import 'package:qulo_v2/data/models/question_model.dart';
import 'package:qulo_v2/providers/api_provider.dart';
import 'package:qulo_v2/providers/user_provider.dart';

class QuestionNotifier extends AsyncNotifier<List<QuestionModel>> {
  @override
  Future<List<QuestionModel>> build() async => [];

  Future<void> fetchQuestions() async {
    state = const AsyncLoading();
    final result = await ref.read(questionRepositoryProvider).getMyQuestions();
    state = result.when(
      success: (data) => AsyncData(data),
      failure: (f) => AsyncError(f, StackTrace.current),
    );
  }

  /// Yeni sorunun sira numarasi (`order_num`).
  ///
  /// `build()` bos liste dondurdugu icin state "hic cekilmedi" ile "hic soru
  /// yok"u ayirt edemez. Liste yalnizca profildeki sorular ekraninda cekiliyor;
  /// kurulum kapisindan dogrudan olusturmaya gelen ve zaten sorusu olan
  /// kullanici icin eski hesap (liste uzunlugu + 1) 1 uretiyor, sunucudaki
  /// `(user_id, order_num)` tekilliginden `DUPLICATE_ORDER_NUM` aliyordu.
  /// Sunucu silmede sirayi sikistirir (1..n), yani taze liste uzunlugu + 1
  /// dogru; liste alinamazsa profildeki soru sayisina duser.
  Future<int> nextOrderNum() async {
    await fetchQuestions();
    // Hata durumunda Riverpod ONCEKI veriyi korur (build'in bos listesi
    // dahil) — `valueOrNull` bos liste doner, 1 uretirdi. Hata varsa listeye
    // guvenme.
    final fresh = state.hasError ? null : state.valueOrNull;
    if (fresh != null) return fresh.length + 1;
    return (ref.read(userProvider).valueOrNull?.questionCount ?? 0) + 1;
  }

  Future<Result<QuestionModel>> createQuestion(Map<String, dynamic> data) async {
    final result = await ref.read(questionRepositoryProvider).createQuestion(data);
    result.when(
      success: (_) {
        fetchQuestions();
        ref.read(userProvider.notifier).fetchMe();
      },
      failure: (f) => dev.log('createQuestion failed: $f', name: 'QuestionNotifier'),
    );
    return result;
  }

  Future<Result<QuestionModel>> updateQuestion(int orderNum, Map<String, dynamic> data) async {
    final result = await ref.read(questionRepositoryProvider).updateQuestion(orderNum, data);
    result.when(
      success: (_) => fetchQuestions(),
      failure: (f) => dev.log('updateQuestion failed: $f', name: 'QuestionNotifier'),
    );
    return result;
  }

  Future<Result<void>> deleteQuestion(int orderNum) async {
    final result = await ref.read(questionRepositoryProvider).deleteQuestion(orderNum);
    result.when(
      success: (_) {
        fetchQuestions();
        ref.read(userProvider.notifier).fetchMe();
      },
      failure: (f) => dev.log('deleteQuestion failed: $f', name: 'QuestionNotifier'),
    );
    return result;
  }

  /// Sirayi iyimser olarak gunceller ve sunucuya gonderir.
  ///
  /// Doner: `false` YALNIZCA sunucu reddettiginde ve sira geri alindiginda —
  /// ekran mixin'i bunu kullaniciya gostermek icin kullaniyor. Eskiden `void`
  /// donuyordu ve hata yalnizca `dev.log`'a gidiyordu: liste sessizce geri
  /// zipliyor, kullanici nedenini bilmiyordu (sikayet akisindaki desenin aynisi).
  /// Siralanacak veri yoksa (yukleniyor/hata) `true` — gosterilecek bir
  /// basarisizlik yok.
  Future<bool> reorderQuestions(int oldIndex, int newIndex) async {
    final current = state.valueOrNull;
    if (current == null) return true;

    // Adjust index for ReorderableListView behavior
    if (newIndex > oldIndex) newIndex--;

    // Sinir kontrolu. Riverpod yukleme/hata durumlarinda ONCEKI veriyi korur
    // (build'in bos listesi dahil), yani `current` null degil BOS olabilir.
    // Ayrica indeksler kullanicinin surukledigi ANDAKI listeye gore gelir;
    // surukleme sirasinda liste degistiyse (silme, yenileme) bayat kalirlar.
    // Eskiden bu durumda `removeAt` RangeError atiyordu — `onReorder`'in async
    // callback'inde yakalanmayan hata. Gecerli bir tasima yoksa no-op: sunucuya
    // gitme, basarisizlik bildirme.
    if (oldIndex < 0 ||
        oldIndex >= current.length ||
        newIndex < 0 ||
        newIndex >= current.length) {
      return true;
    }

    // Ayni yere birakmak: sira degismiyor, sunucuya gitmeye gerek yok.
    if (newIndex == oldIndex) return true;

    final reordered = List<QuestionModel>.from(current);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);

    // Optimistic update
    state = AsyncData(reordered);

    final orderedIds = reordered.map((q) => q.id).toList();
    final result = await ref.read(questionRepositoryProvider).reorderQuestions(orderedIds);
    return result.when(
      success: (data) {
        state = AsyncData(data);
        return true;
      },
      failure: (f) {
        // Rollback
        state = AsyncData(current);
        dev.log('reorderQuestions failed: $f', name: 'QuestionNotifier');
        return false;
      },
    );
  }
}

final questionProvider = AsyncNotifierProvider<QuestionNotifier, List<QuestionModel>>(QuestionNotifier.new);
